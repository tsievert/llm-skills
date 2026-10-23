"""Simulate n observations for one sample. Reads only snakemake.params, never snakemake.config."""
import csv
import random
import sys

# Send diagnostics to the rule's log file
sys.stderr = open(snakemake.log[0], "w")

rng = random.Random(snakemake.params.seed)
print(f"sample={snakemake.wildcards.sample} n={snakemake.params.n} seed={snakemake.params.seed}", file=sys.stderr)

with open(snakemake.output[0], "w", newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["sample", "x", "y"])
    for i in range(snakemake.params.n):
        writer.writerow([snakemake.wildcards.sample, i, round(2 * i + rng.gauss(0, 1), 4)])
