# Logging and console output for batch Python

## Contents
- Logging setup
- Buffering
- Progress reporting
- Multi-process logging
- What not to do

## Logging setup

```python
import logging, os, socket, sys

def setup_logging(level=logging.INFO):
    task = os.environ.get("SLURM_ARRAY_TASK_ID", "-")
    job = os.environ.get("SLURM_JOB_ID", "local")
    logging.basicConfig(
        stream=sys.stdout,           # Slurm writes stdout to --output
        level=level,
        format=f"%(asctime)s %(levelname)s job={job} task={task} %(message)s",
    )
    logging.info("host=%s python=%s", socket.gethostname(), sys.version.split()[0])
```

Log to stdout and let `#SBATCH --output` own the file; this keeps one log per job
and avoids multiple tasks appending to a shared file. If a separate file is
needed, include `%j`/task ID in its name.

## Buffering

- stdout is block-buffered when redirected to a file, so lines appear late or only
  at exit (and are lost if the job is SIGKILLed).
- Fixes: `python -u script.py`, `export PYTHONUNBUFFERED=1` in the job script, or
  `print(..., flush=True)`. The `logging.StreamHandler` flushes after each record.
- Unbuffered output has a performance cost with very frequent prints; reduce
  frequency rather than re-enabling buffering for debugging runs.

## Progress reporting

- Log every N items or every M seconds:

  ```python
  import time
  last = time.monotonic()
  for i, item in enumerate(items):
      ...
      if time.monotonic() - last > 60:
          logging.info("processed %d/%d", i + 1, len(items)); last = time.monotonic()
  ```
- Progress bars write carriage returns that turn into one huge line in a log file.
  Disable them in batch (`tqdm(disable=not sys.stderr.isatty())`).

## Multi-process logging

- Plain `logging` handlers in forked workers write to the same stdout; lines can
  interleave. Include process ID or task index in the format
  (`%(process)d`), or use `logging.handlers.QueueHandler` with a listener in the parent.
- Do not share one log file across array tasks.

## What not to do

- Do not print large arrays, data frames, or per-sample results; this can create
  gigabyte logs per task and fill the quota (and slow the job).
- Do not swallow exceptions; let them propagate (non-zero exit) or log them with
  `logging.exception` and re-raise, so Slurm records `FAILED`.
- Do not log credentials, tokens, or full environment dumps.
- Do not rely on `print` ordering between stdout and stderr when both go to the
  same file; use one stream.
