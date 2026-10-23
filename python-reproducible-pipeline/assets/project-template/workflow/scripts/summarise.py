"""Combine per-sample files into one table of means. Standard library only."""
import csv
import statistics
import sys

sys.stderr = open(snakemake.log[0], "w")

rows = []
for path in snakemake.input:
    with open(path, newline="") as handle:
        reader = csv.DictReader(handle)
        values = [float(r["y"]) for r in reader]
    sample = path.split("/")[-1].removesuffix(".csv")
    rows.append((sample, len(values), round(statistics.fmean(values), 4)))
    print(f"read {path}: {len(values)} rows", file=sys.stderr)

with open(snakemake.output[0], "w", newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["sample", "n", "mean_y"])
    writer.writerows(sorted(rows))
