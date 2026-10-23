#!/usr/bin/env python3
"""HPC-ready skeleton: logging, allocation-aware workers, signals, atomic checkpoints, resume.

Stdlib only. Run locally (works on Windows/macOS/Linux) or inside a Slurm job:

    python hpc_skeleton.py --ckpt-dir ckpt --n-items 200
    python hpc_skeleton.py --ckpt-dir ckpt --n-items 200 --resume auto

Exit codes: 0 = finished, 99 = checkpointed after a signal (script should requeue).
"""
import argparse
import logging
import os
import pickle
import signal
import socket
import sys
import time
from multiprocessing import Pool
from pathlib import Path

EXIT_REQUEUE = 99
stop_requested = False


def setup_logging() -> None:
    job = os.environ.get("SLURM_JOB_ID", "local")
    task = os.environ.get("SLURM_ARRAY_TASK_ID", "-")
    logging.basicConfig(
        stream=sys.stdout,
        level=logging.INFO,
        format=f"%(asctime)s %(levelname)s job={job} task={task} %(message)s",
    )


def n_workers(requested: int | None) -> int:
    """Use the Slurm allocation, not os.cpu_count() (which reports the whole node)."""
    if requested:
        return requested
    return int(os.environ.get("SLURM_CPUS_PER_TASK", 1))


def _on_signal(signum, frame):
    # Keep handlers minimal: just set a flag; checkpoint at the next safe point.
    global stop_requested
    stop_requested = True
    logging.warning("signal %s received; will checkpoint and exit", signum)


def install_signal_handlers() -> None:
    for name in ("SIGUSR1", "SIGTERM"):  # SIGUSR1 does not exist on Windows
        if hasattr(signal, name):
            signal.signal(getattr(signal, name), _on_signal)


def _worker_init() -> None:
    # Workers ignore the warning signal so only the parent coordinates the checkpoint.
    if hasattr(signal, "SIGUSR1"):
        signal.signal(signal.SIGUSR1, signal.SIG_IGN)
    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, signal.SIG_IGN)


def atomic_pickle(obj, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "wb") as f:
        pickle.dump(obj, f)
    os.replace(tmp, path)  # atomic: a kill mid-write cannot corrupt the old file


def work(item: int) -> tuple[int, int]:
    time.sleep(0.01)  # replace with real computation
    return item, item * item


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt-dir", required=True, type=Path)
    ap.add_argument("--n-items", type=int, default=100)
    ap.add_argument("--workers", type=int, default=None)
    ap.add_argument("--resume", default="auto", choices=["auto", "no"])
    ap.add_argument("--chunk", type=int, default=20, help="items between checkpoints")
    args = ap.parse_args()

    setup_logging()
    install_signal_handlers()
    ckpt = args.ckpt_dir / "state.pkl"
    done_marker = args.ckpt_dir / "DONE"
    logging.info("host=%s python=%s restart=%s", socket.gethostname(),
                 sys.version.split()[0], os.environ.get("SLURM_RESTART_COUNT", "0"))

    if done_marker.exists():
        logging.info("already complete; nothing to do")
        return 0

    results: dict[int, int] = {}
    if args.resume == "auto" and ckpt.exists():
        with open(ckpt, "rb") as f:
            results = pickle.load(f)
        logging.info("resumed %d results from %s", len(results), ckpt)

    todo = [i for i in range(args.n_items) if i not in results]
    nw = n_workers(args.workers)
    logging.info("%d items to do with %d workers", len(todo), nw)
    t0 = time.monotonic()

    with Pool(processes=nw, initializer=_worker_init) as pool:
        for start in range(0, len(todo), args.chunk):
            if stop_requested:
                break
            for item, value in pool.map(work, todo[start:start + args.chunk]):
                results[item] = value
            atomic_pickle(results, ckpt)
            logging.info("checkpointed %d/%d", len(results), args.n_items)

    if len(results) < args.n_items:
        atomic_pickle(results, ckpt)
        logging.warning("stopped early with %d/%d; exiting %d for requeue",
                        len(results), args.n_items, EXIT_REQUEUE)
        return EXIT_REQUEUE

    done_marker.touch()
    logging.info("finished in %.1fs", time.monotonic() - t0)
    return 0


if __name__ == "__main__":
    sys.exit(main())
