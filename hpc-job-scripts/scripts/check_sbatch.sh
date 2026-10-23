#!/usr/bin/env bash
# Lint a Slurm batch script for common silent failures.
# Usage: check_sbatch.sh job.sh
# Exit codes: 0 = no errors (warnings/info may print), 1 = at least one ERROR, 2 = usage.
# Run from the directory you will submit from: relative log paths are checked against it.

f="${1:-}"
[ -n "$f" ] && [ -f "$f" ] || { echo "usage: check_sbatch.sh job.sh" >&2; exit 2; }

errs=0
err()  { echo "ERROR: $*"; errs=$((errs + 1)); }
warn() { echo "WARN:  $*"; }
info() { echo "INFO:  $*"; }

# --- file-level problems ---
if grep -q $'\r' "$f"; then
  err "CRLF line endings (file edited on Windows?). Fix: sed -i 's/\\r\$//' $f ; add '*.sh text eol=lf' to .gitattributes"
fi
head -n 1 "$f" | grep -q '^#!' || err "no shebang on line 1 (e.g. #!/bin/bash)"

# --- directives after the first command are ignored ---
first_cmd=$(awk '/^[[:space:]]*#/ {next} /^[[:space:]]*$/ {next} {print NR; exit}' "$f")
if [ -n "$first_cmd" ]; then
  while IFS=: read -r n _; do
    [ "$n" -gt "$first_cmd" ] && err "line $n: #SBATCH after first command (line $first_cmd) is ignored by Slurm"
  done < <(grep -nE '^[[:space:]]*#SBATCH' "$f")
fi

sb=$(grep -E '^[[:space:]]*#SBATCH' "$f" | tr -d '\r')
has() { grep -Eq -- "$1" <<<"$sb"; }
body=$(grep -vE '^[[:space:]]*#' "$f" | tr -d '\r')
bhas() { grep -Eq -- "$1" <<<"$body"; }

# --- resources ---
has '(--time|-t)[ =]' || warn "no --time; the site default may be very short or very long"
if ! has '--mem[ =]|--mem-per-cpu[ =]|--mem-per-gpu[ =]'; then
  warn "no memory request; default is site-specific (check hpc-cluster-docs profile)"
fi
if has '--mem[ =]' && has '--mem-per-cpu[ =]'; then
  err "--mem and --mem-per-cpu are mutually exclusive"
fi

# --- logs ---
out=$(sed -nE 's/^[[:space:]]*#SBATCH[[:space:]]+(--output|-o)[= ]+([^[:space:]#]+).*/\2/p' <<<"$sb" | head -n 1)
if [ -z "$out" ]; then
  info "no --output: log goes to slurm-%j.out in the submit directory"
else
  dir=$(dirname "$out")
  case "$dir" in
    *%*) info "log directory contains a % pattern; cannot check that it exists" ;;
    .)   : ;;
    *)   [ -d "$dir" ] || warn "log directory '$dir' does not exist (relative to $PWD). Slurm will not create it and the job fails silently. mkdir -p it before sbatch" ;;
  esac
  case "$out" in
    *%j*|*%A*|*%x*) : ;;
    *) warn "log name '$out' has no %j/%A/%x; reruns overwrite earlier logs" ;;
  esac
fi

# --- arrays, signals, requeue ---
if has '--array[ =]' && ! has '--array[ =][^[:space:]]*%'; then
  info "--array has no %N throttle; consider e.g. --array=0-999%20 (check site array limits)"
fi
if has '--signal[ =]' && ! grep -qE '^[[:space:]]*trap[[:space:]]' <<<"$body"; then
  warn "--signal set but no trap in script; the signal will have no effect (B: signals the batch shell)"
fi
if has '--requeue' && ! has '--open-mode[ =]append'; then
  info "--requeue without --open-mode=append: a restart may truncate the log"
fi

# --- environment and Python ---
if bhas 'module[[:space:]]+load' && ! bhas 'module[[:space:]]+purge'; then
  info "module load without a preceding module purge"
fi
if bhas '(^|[[:space:]])(srun[[:space:]]+)?python3?[[:space:]]' \
   && ! bhas 'PYTHONUNBUFFERED' && ! bhas 'python3?[[:space:]]+-u[[:space:]]'; then
  info "python without -u or PYTHONUNBUFFERED: log output may appear late"
fi
if has '--cpus-per-task[ =]([2-9]|[1-9][0-9]+)' && ! bhas 'OMP_NUM_THREADS'; then
  info "--cpus-per-task > 1 but OMP_NUM_THREADS is not set; set it to \$SLURM_CPUS_PER_TASK (threads) or 1 (multiprocessing)"
fi

# --- races, scratch, GPUs ---
if has '--array[ =]'; then
  # Look only at the redirect target, not the text being written
  racy=$(sed -nE 's/.*>>[[:space:]]*([^[:space:]]+).*/\1/p' <<<"$body" | grep -vE 'ARRAY_TASK_ID|ARRAY_JOB_ID|SLURM_JOB_ID|/dev/null|%' || true)
  [ -n "$racy" ] && warn "array job appends (>>) to a path without a task/job ID; concurrent tasks will race. Use per-task files and merge afterwards"
fi
if bhas 'TMPDIR|SLURM_SCRATCH' && ! grep -qE '^[[:space:]]*trap[[:space:]]' <<<"$body"; then
  info "uses node-local scratch but has no trap; results on scratch are lost if the job is cancelled or times out"
fi
if has '--gres[ =][^[:space:]]*gpu|--gpus' ; then
  has '--cpus-per-task[ =]|-c[ =]' || info "GPU requested without --cpus-per-task; data loading may starve the GPU"
  if has '--gpus-per-task' && bhas 'torchrun'; then
    warn "--gpus-per-task with torchrun: each spawned worker may see only one GPU. Use one task per node with --gpus-per-node/--gres, or one task per GPU with srun and no torchrun"
  fi
fi
if bhas 'MASTER_PORT=.*RANDOM'; then
  info "random MASTER_PORT can collide with other jobs on the node; derive it from \$SLURM_JOB_ID"
fi
bhas '^[[:space:]]*set[[:space:]]+-[a-z]*e' || info "no 'set -e' / 'set -euo pipefail'; errors will not stop the script"

if [ "$errs" -gt 0 ]; then
  echo "$errs error(s) found in $f"
  exit 1
fi
echo "no errors in $f"
exit 0
