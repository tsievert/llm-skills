#!/usr/bin/env python3
"""Summarise a keypoint-MoSeq results.h5 into tidy CSVs (bouts, usage, transitions).

Reads the file with h5py only (no JAX / keypoint_moseq import), so it runs on a
laptop or login node. Merge the output with your own metadata (animal, group,
treatment, session) by the `recording` column before modelling.

    python kpms_summarise_results.py proj/run1/results.h5 --out summary --fps 30

Outputs in --out:
    bouts.csv        one row per uninterrupted syllable run
    usage.csv        recording x syllable counts (zeros included)
    transitions.csv  recording x from x to counts between consecutive bouts
                     (self-transitions cannot occur at bout level)

Column definitions are this script's own. They are not guaranteed to match
keypoint_moseq's `compute_stats_df` ("frequency"); check its docs before comparing.
Requires: h5py, numpy, pandas.
"""
import argparse
from pathlib import Path

import h5py
import numpy as np
import pandas as pd


def read_recordings(path):
    """Return {recording_name: syllable array}. Handles nested groups (path_in_name=True)."""
    out = {}
    with h5py.File(path, "r") as f:
        def visit(name, obj):
            if isinstance(obj, h5py.Group) and "syllable" in obj and isinstance(obj["syllable"], h5py.Dataset):
                out[name] = obj["syllable"][()].astype(int)
        f.visititems(visit)
    if not out:
        raise SystemExit(f"No recordings with a 'syllable' dataset found in {path}")
    return dict(sorted(out.items()))


def bouts_for(rec, z, fps, min_bout_frames):
    change = np.flatnonzero(np.diff(z)) + 1
    starts = np.r_[0, change]
    ends = np.r_[change, len(z)]
    df = pd.DataFrame({"recording": rec, "syllable": z[starts], "start_frame": starts, "end_frame": ends})
    df["n_frames"] = df.end_frame - df.start_frame
    df["duration_s"] = df.n_frames / fps
    df["bout_index"] = np.arange(len(df))
    return df[df.n_frames >= min_bout_frames].reset_index(drop=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("results_h5")
    ap.add_argument("--out", default="kpms_summary")
    ap.add_argument("--fps", type=float, required=True, help="Frames per second used for the model")
    ap.add_argument("--min-bout-frames", type=int, default=1,
                    help="Drop bouts shorter than this before counting (default keeps all; "
                         "dropping makes the sequence discontinuous, so transitions are computed after the filter)")
    a = ap.parse_args()

    recs = read_recordings(a.results_h5)
    bouts = pd.concat([bouts_for(r, z, a.fps, a.min_bout_frames) for r, z in recs.items()], ignore_index=True)
    all_syll = np.sort(bouts.syllable.unique())

    usage = (
        bouts.groupby(["recording", "syllable"])
        .agg(n_frames=("n_frames", "sum"), n_bouts=("n_frames", "size"), mean_bout_s=("duration_s", "mean"))
        .reset_index()
    )
    full = pd.MultiIndex.from_product([list(recs), all_syll], names=["recording", "syllable"])
    usage = usage.set_index(["recording", "syllable"]).reindex(full).reset_index()
    usage[["n_frames", "n_bouts"]] = usage[["n_frames", "n_bouts"]].fillna(0).astype(int)
    tot = usage.groupby("recording")[["n_frames", "n_bouts"]].transform("sum")
    usage["frame_fraction"] = usage.n_frames / tot.n_frames
    usage["bout_fraction"] = usage.n_bouts / tot.n_bouts

    rows = []
    for rec, b in bouts.groupby("recording"):
        s = b.syllable.to_numpy()
        rows.append(pd.DataFrame({"recording": rec, "from": s[:-1], "to": s[1:]}))
    trans = pd.concat(rows, ignore_index=True).groupby(["recording", "from", "to"]).size().rename("n").reset_index()

    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    bouts.to_csv(out / "bouts.csv", index=False)
    usage.to_csv(out / "usage.csv", index=False)
    trans.to_csv(out / "transitions.csv", index=False)
    print(f"{len(recs)} recordings, {len(all_syll)} syllables, {len(bouts)} bouts -> {out}")


if __name__ == "__main__":
    main()
