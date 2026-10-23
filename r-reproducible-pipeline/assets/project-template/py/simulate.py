"""Example Python step: simulate x and y for one sample and write a CSV.

Usage: simulate.py N_OBS SLOPE SEED OUT_CSV
Standard library only, so the locked environment in this folder has no dependencies.
"""
import csv
import random
import sys

n_obs, slope, seed, out = int(sys.argv[1]), float(sys.argv[2]), int(sys.argv[3]), sys.argv[4]

rng = random.Random(seed)
with open(out, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["x", "y"])
    for _ in range(n_obs):
        x = rng.random()
        writer.writerow([x, slope * x + rng.gauss(0, 0.1)])
