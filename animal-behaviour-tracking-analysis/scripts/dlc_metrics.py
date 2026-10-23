#!/usr/bin/env python3
"""Basic behavioural metrics from DeepLabCut (DLC) output: distance, speed, immobility, ROI occupancy.

Reads DLC .csv or .h5 (single- or multi-animal), masks low-likelihood points, interpolates short gaps,
optionally scales pixels to cm and smooths, then writes per-frame tracks, a per-animal summary and
time-binned metrics. The R twin is scripts/dlc_metrics.R (same definitions and column names).

    python dlc_metrics.py trial1_DLC.csv --bodypart spine2 --fps 30 --likelihood 0.9 \
        --max-gap-frames 10 --px-per-cm 12.4 --smooth-window 5 --move-threshold 2 \
        --min-immobile-s 2 --roi rois.json --bin-s 60 --out metrics

ROI file (JSON, coordinates in VIDEO PIXELS: origin top-left, y grows downwards):
    {"centre": {"type": "circle", "centre": [320, 240], "radius": 80},
     "left":   {"type": "rect", "x0": 0, "y0": 0, "x1": 300, "y1": 480},
     "poly":   {"type": "polygon", "points": [[10, 10], [200, 10], [100, 150]]}}

Definitions (identical in R):
  * speed[t] = distance(pos[t], pos[t-1]) * fps, in cm/s if --px-per-cm is given, else px/s.
  * distance_total = sum of valid step distances; steps touching a NaN are skipped.
  * immobile frame: speed < --move-threshold; an immobility bout is a run of such frames lasting
    >= --min-immobile-s ("freezing" only if validated against manual scoring; see the skill reference).
  * ROI occupancy uses the cleaned, smoothed position; frames with missing position count as outside.
  * entry = start of a run of in-ROI frames lasting >= --min-roi-s.
Requires: numpy, pandas, scipy (h5 input also needs pytables).
"""
import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.signal import savgol_filter


# ----------------------------------------------------------------------------- input
def read_dlc(path, bodypart):
    """Return {individual: DataFrame[x, y, likelihood]} for one body part."""
    path = Path(path)
    if path.suffix.lower() in (".h5", ".hdf5"):
        df = pd.read_hdf(path)
    else:
        with open(path) as f:
            second = f.readlines()[1]
        nheader = 4 if second.split(",")[0].strip() == "individuals" else 3
        df = pd.read_csv(path, header=list(range(nheader)), index_col=0)
    cols = df.columns
    out = {}

    def one(sub):
        # sub has levels (scorer, bodyparts, coords) -> columns x, y, likelihood
        if bodypart not in sub.columns.get_level_values("bodyparts"):
            return None
        return sub.xs(bodypart, axis=1, level="bodyparts").droplevel(0, axis=1)

    if "individuals" in cols.names:
        for ind in cols.get_level_values("individuals").unique():
            res = one(df.xs(ind, axis=1, level="individuals"))
            if res is not None:
                out[ind] = res
    else:
        res = one(df)
        if res is None:
            raise SystemExit(f"bodypart {bodypart!r} not in {sorted(set(cols.get_level_values('bodyparts')))}")
        out["animal"] = res
    if not out:
        raise SystemExit(f"bodypart {bodypart!r} not found for any individual")
    return {k: v[["x", "y", "likelihood"]].astype(float).reset_index(drop=True) for k, v in out.items()}


# ----------------------------------------------------------------------------- processing
def interpolate_short_gaps(v, max_gap):
    """Linear interpolation of NaN runs of length <= max_gap that have valid neighbours on both sides."""
    v = v.copy()
    isn = np.isnan(v)
    n = len(v)
    i = 0
    while i < n:
        if isn[i]:
            j = i
            while j < n and isn[j]:
                j += 1
            if i > 0 and j < n and (j - i) <= max_gap:
                v[i:j] = np.interp(np.arange(i, j), [i - 1, j], [v[i - 1], v[j]])
            i = j
        else:
            i += 1
    return v


def smooth_segments(v, window, order=2):
    """Savitzky-Golay per contiguous non-NaN segment; segments shorter than the window stay raw."""
    if window <= 1:
        return v
    out = v.copy()
    ok = ~np.isnan(v)
    n = len(v)
    i = 0
    while i < n:
        if ok[i]:
            j = i
            while j < n and ok[j]:
                j += 1
            if j - i >= window:
                out[i:j] = savgol_filter(v[i:j], window, order)
            i = j
        else:
            i += 1
    return out


def runs(mask):
    """Start (inclusive) and end (exclusive) indices of True runs."""
    m = np.r_[False, mask, False].astype(int)
    d = np.diff(m)
    return np.flatnonzero(d == 1), np.flatnonzero(d == -1)


def in_roi(x, y, spec):
    t = spec["type"]
    if t == "circle":
        cx, cy = spec["centre"]
        return (x - cx) ** 2 + (y - cy) ** 2 <= spec["radius"] ** 2
    if t == "rect":
        return (x >= min(spec["x0"], spec["x1"])) & (x <= max(spec["x0"], spec["x1"])) & \
               (y >= min(spec["y0"], spec["y1"])) & (y <= max(spec["y0"], spec["y1"]))
    if t == "polygon":  # even-odd ray casting
        px = np.array([p[0] for p in spec["points"]], float)
        py = np.array([p[1] for p in spec["points"]], float)
        inside = np.zeros(len(x), bool)
        j = len(px) - 1
        for i in range(len(px)):
            straddle = (py[i] > y) != (py[j] > y)  # horizontal edges never straddle, so no division by zero
            with np.errstate(divide="ignore", invalid="ignore"):
                x_cross = (px[j] - px[i]) * (y - py[i]) / (py[j] - py[i]) + px[i]
            inside ^= straddle & (x < x_cross)
            j = i
        return inside
    raise ValueError(f"unknown ROI type {t!r}")


def process_track(tr, fps, likelihood, max_gap, px_per_cm, smooth_window, move_thr, min_immobile_s, rois, min_roi_s):
    n = len(tr)
    x, y, lk = tr.x.to_numpy(), tr.y.to_numpy(), tr.likelihood.to_numpy()
    bad = np.isnan(x) | np.isnan(y) | np.isnan(lk) | (lk < likelihood)
    x = np.where(bad, np.nan, x)
    y = np.where(bad, np.nan, y)
    frac_missing_raw = float(np.isnan(x).mean())
    x = interpolate_short_gaps(x, max_gap)
    y = interpolate_short_gaps(y, max_gap)
    frac_missing = float(np.isnan(x).mean())
    x = smooth_segments(x, smooth_window)
    y = smooth_segments(y, smooth_window)

    scale = 1.0 / px_per_cm if px_per_cm else 1.0
    unit = "cm" if px_per_cm else "px"
    step = np.full(n, np.nan)
    step[1:] = np.hypot(np.diff(x), np.diff(y)) * scale
    speed = step * fps
    t = np.arange(n) / fps

    immobile = np.zeros(n, bool)
    valid_speed = ~np.isnan(speed)
    slow = valid_speed & (speed < move_thr)
    for a, b in zip(*runs(slow)):
        if (b - a) / fps >= min_immobile_s:
            immobile[a:b] = True
    n_imm_bouts = int(sum((b - a) / fps >= min_immobile_s for a, b in zip(*runs(slow))))

    frames = pd.DataFrame({"frame": np.arange(n), "time_s": t, "x_px": x, "y_px": y, "speed": speed, "immobile": immobile})
    summary = {
        "n_frames": n, "duration_s": n / fps, "frac_missing_raw": frac_missing_raw, "frac_missing_final": frac_missing,
        "unit": unit, "distance_total": float(np.nansum(step)),
        "mean_speed": float(np.nanmean(speed)) if valid_speed.any() else np.nan,
        "frac_immobile": float(immobile.sum() / max(valid_speed.sum(), 1)),
        "n_immobile_bouts": n_imm_bouts,
    }
    min_roi_frames = max(1, int(round(min_roi_s * fps)))
    for name, spec in rois.items():
        ok = ~np.isnan(x)
        inside = np.zeros(n, bool)
        inside[ok] = in_roi(x[ok], y[ok], spec)
        frames[f"roi_{name}"] = inside
        starts = [a for a, b in zip(*runs(inside)) if (b - a) >= min_roi_frames]
        summary[f"{name}_time_s"] = float(inside.sum() / fps)
        summary[f"{name}_frac_valid"] = float(inside.sum() / max(ok.sum(), 1))
        summary[f"{name}_entries"] = len(starts)
        summary[f"{name}_latency_s"] = float(starts[0] / fps) if starts else np.nan
    return frames, summary


def bin_metrics(frames, fps, bin_s, rois):
    b = (frames.time_s // bin_s).astype(int)
    g = frames.assign(bin=b, step=frames.speed / fps).groupby("bin")
    out = pd.DataFrame({
        "bin": sorted(b.unique()),
    })
    out["bin_start_s"] = out.bin * bin_s
    out["distance"] = g["step"].sum(min_count=1).reindex(out.bin).to_numpy()
    out["mean_speed"] = g["speed"].mean().reindex(out.bin).to_numpy()
    out["frac_immobile"] = g["immobile"].mean().reindex(out.bin).to_numpy()
    for name in rois:
        out[f"{name}_time_s"] = (g[f"roi_{name}"].sum() / fps).reindex(out.bin).to_numpy()
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("inputs", nargs="+", help="DLC .csv/.h5 files")
    ap.add_argument("--bodypart", required=True, help="Body part used for position (a stable central point; see reference)")
    ap.add_argument("--fps", type=float, required=True)
    ap.add_argument("--likelihood", type=float, default=0.9, help="Mask points below this (default 0.9; choose by looking at the distribution)")
    ap.add_argument("--max-gap-frames", type=int, default=5, help="Interpolate gaps up to this long; longer stay missing")
    ap.add_argument("--px-per-cm", type=float, help="Calibration; without it results are in pixels")
    ap.add_argument("--smooth-window", type=int, default=0, help="Savitzky-Golay window in frames (odd, >=3; 0 = off), order 2")
    ap.add_argument("--move-threshold", type=float, default=2.0, help="Speed below this (cm/s or px/s) counts as immobile")
    ap.add_argument("--min-immobile-s", type=float, default=1.0)
    ap.add_argument("--roi", help="JSON with ROI definitions in video pixels")
    ap.add_argument("--min-roi-s", type=float, default=0.0, help="Minimum visit length to count an entry (suppresses edge flicker)")
    ap.add_argument("--bin-s", type=float, default=0.0, help="Also write time-binned metrics (seconds per bin)")
    ap.add_argument("--out", default="dlc_metrics")
    a = ap.parse_args()
    if a.smooth_window and (a.smooth_window < 3 or a.smooth_window % 2 == 0):
        raise SystemExit("--smooth-window must be odd and >= 3")
    rois = json.loads(Path(a.roi).read_text()) if a.roi else {}

    out = Path(a.out)
    (out / "frames").mkdir(parents=True, exist_ok=True)
    rows, bins = [], []
    for path in a.inputs:
        for ind, tr in read_dlc(path, a.bodypart).items():
            frames, s = process_track(tr, a.fps, a.likelihood, a.max_gap_frames, a.px_per_cm, a.smooth_window,
                                      a.move_threshold, a.min_immobile_s, rois, a.min_roi_s)
            rec = f"{Path(path).stem}" + ("" if ind == "animal" else f"__{ind}")
            rows.append({"recording": rec, **s})
            frames.to_csv(out / "frames" / f"{rec}.csv", index=False)
            if a.bin_s > 0:
                bins.append(bin_metrics(frames, a.fps, a.bin_s, rois).assign(recording=rec))
    pd.DataFrame(rows).to_csv(out / "summary.csv", index=False)
    if bins:
        pd.concat(bins).to_csv(out / "bins.csv", index=False)
    print(f"{len(rows)} tracks -> {out}")


if __name__ == "__main__":
    main()
