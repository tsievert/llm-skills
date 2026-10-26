#!/usr/bin/env python3
"""Headless keypoint-MoSeq fit for HPC / batch use (no widgets, no notebook).

Pipeline: load DLC keypoints -> outlier removal -> PCA -> AR-HMM -> full model
-> reindex syllables -> extract results (+ CSV). Resumable: rerun the same
command after a time-limit kill and it continues from the last checkpoint.

Written against keypoint-moseq 0.6.x-0.8.x docs (modeling tutorial; run on 0.6.6 and 0.8.0). Verify
signatures against the installed version if anything fails:
    python -c "import keypoint_moseq as k; help(k.fit_model)"

Example:
    python kpms_headless_fit.py --project-dir proj --keypoints-dir dlc/videos \
        --use-bodyparts nose head spine1 spine2 spine3 \
        --anterior nose --posterior spine3 --fps 30 --model-name run1
"""
import argparse
import json
import os
import sys
import time
from pathlib import Path

# No display on compute nodes; must be set before matplotlib is imported.
os.environ.setdefault("MPLBACKEND", "Agg")

import keypoint_moseq as kpms  # noqa: E402


def parse_args():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--project-dir", required=True)
    p.add_argument("--keypoints-dir", required=True, help="Folder with DLC .csv/.h5 files (searched recursively)")
    p.add_argument("--dlc-config", help="DLC config.yaml; initialises bodyparts/skeleton/video_dir")
    p.add_argument("--video-dir", help="Videos (only needed for grid movies/overlays, not for fitting)")
    p.add_argument("--use-bodyparts", nargs="+", help="Subset of bodyparts for the model (5-10 recommended)")
    p.add_argument("--anterior", nargs="+", required=True, help="Bodypart(s) defining the front of the animal")
    p.add_argument("--posterior", nargs="+", required=True, help="Bodypart(s) defining the back of the animal")
    p.add_argument("--fps", type=float, required=True)
    p.add_argument("--latent-dim", type=int, help="Default: dims explaining 90%% of PCA variance, capped at 10")
    p.add_argument("--outlier-scale-factor", type=float, default=6.0)
    p.add_argument("--kappa-ar", type=float, default=1e6, help="Kappa for the AR-HMM stage")
    p.add_argument("--kappa-full", type=float, default=1e4, help="Kappa for the full model (usually lower)")
    p.add_argument("--ar-iters", type=int, default=50)
    p.add_argument("--full-iters", type=int, default=500, help="Additional iterations after the AR stage")
    p.add_argument("--save-every", type=int, default=25, help="Checkpoint interval; bounds the work lost on a kill")
    p.add_argument("--seed", type=int, default=0, help="Use different seeds for restarts / model selection")
    p.add_argument("--model-name", required=True, help="Checkpoint folder name inside the project (also the resume key)")
    p.add_argument("--no-csv", action="store_true", help="Skip per-recording CSV export")
    p.add_argument("--prepare-only", action="store_true",
                   help="Create config, outlier-filter and PCA, then exit. Run once before submitting an array "
                        "so tasks do not race on the shared project files")
    return p.parse_args()


def log(msg):
    print(msg, flush=True)


def log_phase_timing(phase, n_iters, seconds):
    if n_iters <= 0 or seconds is None:
        log(f"{phase} phase: 0 iterations")
        return
    log(f"{phase} phase: {n_iters} iterations in {seconds:.1f} s ({n_iters / seconds:.3f} iter/s)")


def main():
    a = parse_args()
    import jax

    # Do not create project_dir here: setup_project refuses to use an existing folder
    # unless it is called with overwrite=True.
    project_dir = a.project_dir
    log(f"keypoint_moseq {getattr(kpms, '__version__', '?')}, jax backend: {jax.default_backend()}")

    # --- project and config -------------------------------------------------
    coordinates, confidences, bodyparts = kpms.load_keypoints(a.keypoints_dir, "deeplabcut")
    log(f"loaded {len(coordinates)} recordings, bodyparts: {bodyparts}")

    if not (Path(project_dir) / "config.yml").exists():
        if a.dlc_config:
            kpms.setup_project(project_dir, deeplabcut_config=a.dlc_config)
        else:
            # skeleton is for visualisation only; a simple chain avoids placeholder names
            chain = a.use_bodyparts or bodyparts
            skeleton = [[chain[i], chain[i + 1]] for i in range(len(chain) - 1)]
            kpms.setup_project(project_dir, bodyparts=bodyparts, skeleton=skeleton, video_dir=a.video_dir or "")
    config = lambda: kpms.load_config(project_dir)  # noqa: E731

    updates = dict(
        anterior_bodyparts=a.anterior,
        posterior_bodyparts=a.posterior,
        use_bodyparts=a.use_bodyparts or bodyparts,
        fps=a.fps,
        outlier_scale_factor=a.outlier_scale_factor,
    )
    if a.video_dir:
        updates["video_dir"] = a.video_dir
    kpms.update_config(project_dir, **updates)

    # Report NaN proportions up front; many NaNs are the usual cause of failed fits.
    kpms.check_nan_proportions(coordinates, bodyparts, breakdown=True)

    # --- preprocessing ------------------------------------------------------
    coordinates, confidences = kpms.outlier_removal(
        coordinates, confidences, project_dir, overwrite=False, **config()
    )
    data, metadata = kpms.format_data(coordinates, confidences, **config())
    # Performance data point for the skill (see references/hpc-and-troubleshooting.md):
    # this skill has no tested real-world HPC/GPU timing yet, so every fit records its own.
    n_frames = int(data["mask"].sum())
    log(f"n_frames={n_frames} (valid, post-outlier-removal, across {len(coordinates)} recordings)")
    # noise_calibration is interactive and is skipped here. If fits produce NaNs,
    # calibrate once on a workstation and copy slope/intercept from config.yml.

    # --- PCA (cached) -------------------------------------------------------
    pca_file = Path(project_dir) / "pca.p"
    if pca_file.exists():
        pca = kpms.load_pca(project_dir)
    else:
        pca = kpms.fit_pca(**data, **config())
        kpms.save_pca(pca, project_dir)
    if a.latent_dim:
        latent_dim = a.latent_dim
    else:
        import numpy as np

        cum = np.cumsum(pca.explained_variance_ratio_)
        latent_dim = int(min(10, np.searchsorted(cum, 0.9) + 1))
    kpms.update_config(project_dir, latent_dim=latent_dim)
    kpms.update_config(
        project_dir,
        sigmasq_loc=kpms.estimate_sigmasq_loc(data["Y"], data["mask"], filter_size=int(round(config()["fps"]))),
    )
    log(f"latent_dim={latent_dim}")
    if a.prepare_only:
        log("prepare-only: project, config and PCA are ready")
        return 0

    # --- fit (resumable) ----------------------------------------------------
    total_iters = a.ar_iters + a.full_iters
    ckpt = Path(project_dir) / a.model_name / "checkpoint.h5"
    done_iter = 0
    if ckpt.exists():
        model, data, metadata, done_iter = kpms.load_checkpoint(project_dir, a.model_name)
        log(f"resuming {a.model_name} at iteration {done_iter}/{total_iters}")
    else:
        model = kpms.init_model(data, pca=pca, seed=jax.random.PRNGKey(a.seed), **config())

    # Fit-phase timing, for references/hpc-and-troubleshooting.md "Performance versus
    # memory trade-off": this skill has no tested real HPC/GPU numbers yet, so every
    # fit records its own (see run_summary.json below).
    ar_fit_seconds = None
    full_fit_seconds = None
    ar_iters_run = max(0, a.ar_iters - min(done_iter, a.ar_iters))
    full_iters_run = max(0, total_iters - max(done_iter, a.ar_iters))

    if done_iter < a.ar_iters:
        model = kpms.update_hypparams(model, kappa=a.kappa_ar)
        t0 = time.perf_counter()
        model = kpms.fit_model(
            model, data, metadata, project_dir, a.model_name,
            ar_only=True, start_iter=done_iter, num_iters=a.ar_iters, save_every_n_iters=a.save_every,
        )[0]
        ar_fit_seconds = time.perf_counter() - t0
        log_phase_timing("AR-HMM", ar_iters_run, ar_fit_seconds)
        model, data, metadata, done_iter = kpms.load_checkpoint(project_dir, a.model_name, iteration=a.ar_iters)

    if done_iter < total_iters:
        model = kpms.update_hypparams(model, kappa=a.kappa_full)
        t0 = time.perf_counter()
        model = kpms.fit_model(
            model, data, metadata, project_dir, a.model_name,
            ar_only=False, start_iter=done_iter, num_iters=total_iters, save_every_n_iters=a.save_every,
        )[0]
        full_fit_seconds = time.perf_counter() - t0
        log_phase_timing("full-model", full_iters_run, full_fit_seconds)

    # --- outputs ------------------------------------------------------------
    # Reindexing changes only the checkpoint, so it must precede extract_results.
    kpms.reindex_syllables_in_checkpoint(project_dir, a.model_name)
    model, data, metadata, _ = kpms.load_checkpoint(project_dir, a.model_name)
    # extract_results appends to an existing results.h5 (and only newer versions accept
    # overwrite=True), so remove the stale derived file for a clean, version-independent rerun.
    (Path(project_dir) / a.model_name / "results.h5").unlink(missing_ok=True)
    results = kpms.extract_results(model, metadata, project_dir, a.model_name)
    if not a.no_csv:
        kpms.save_results_as_csv(results, project_dir, a.model_name)

    summary = {
        "model_name": a.model_name,
        "results_h5": str(Path(project_dir) / a.model_name / "results.h5"),
        "recordings": len(results),
        "latent_dim": latent_dim,
        "kappa_ar": a.kappa_ar,
        "kappa_full": a.kappa_full,
        "seed": a.seed,
        # Performance data for references/hpc-and-troubleshooting.md: this skill has no tested
        # real HPC/GPU numbers yet. If this ran on a cluster, paste this file back so the
        # docs-only sizing there can be replaced with something measured.
        "n_frames": n_frames,
        "jax_backend": jax.default_backend(),
        "jax_device": getattr(jax.devices()[0], "device_kind", str(jax.devices()[0])),
        "ar_iters_run": ar_iters_run,
        "ar_fit_seconds": ar_fit_seconds,
        "full_iters_run": full_iters_run,
        "full_fit_seconds": full_fit_seconds,
    }
    (Path(project_dir) / a.model_name / "run_summary.json").write_text(json.dumps(summary, indent=2))
    log(json.dumps(summary))


if __name__ == "__main__":
    sys.exit(main())
