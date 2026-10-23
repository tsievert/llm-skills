#!/usr/bin/env python3
"""Static checks for a uv + Snakemake analysis project. Run from the project root:

    uv run --no-project --with pyyaml python <skill-dir>/scripts/check_pipeline.py [project_dir]

Prints one line per finding (LEVEL  check  message) and exits 1 if there is any ERROR.
Runs locally only: it reads files, and calls `uv lock --check` if uv is on PATH.
It does not run Snakemake and cannot see the cluster. PyYAML is available inside a
Snakemake environment, and `--with pyyaml` provides it otherwise; `--no-project` stops uv from
rewriting the project lock file before the check (a plain `uv run` would hide a stale lock).
"""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

findings: list[tuple[str, str, str]] = []


def add(level: str, check: str, message: str) -> None:
    findings.append((level, check, message))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def main(root: Path) -> int:
    snakefile = next((p for p in (root / "workflow" / "Snakefile", root / "Snakefile") if p.exists()), None)
    if snakefile is None:
        add("ERROR", "layout", "no workflow/Snakefile or Snakefile found")
        return report()
    snake_text = read(snakefile)
    workflow_dir = snakefile.parent

    # --- environment files -------------------------------------------------
    pyproject = root / "pyproject.toml"
    deps: list[str] = []
    if not pyproject.exists():
        add("ERROR", "environment", "pyproject.toml missing: dependencies are not declared")
    else:
        data = tomllib.loads(read(pyproject))
        deps = [re.split(r"[<>=!~\[ ;]", d, maxsplit=1)[0].lower() for d in data.get("project", {}).get("dependencies", [])]
        if "snakemake" not in deps:
            add("WARN", "environment", "snakemake is not a direct dependency in pyproject.toml")
        if "exclude-newer" not in read(pyproject):
            add("INFO", "environment", "no exclude-newer date pin (optional; the lock file already fixes versions)")
    if not (root / "uv.lock").exists():
        add("ERROR", "environment", "uv.lock missing: run `uv lock` and commit it")
    elif shutil.which("uv"):
        res = subprocess.run(["uv", "lock", "--check"], cwd=root, capture_output=True, text=True)
        if res.returncode != 0:
            add("ERROR", "environment", "uv.lock is out of date with pyproject.toml (`uv lock --check` failed): run `uv lock`")
    else:
        add("INFO", "environment", "uv not on PATH: could not run `uv lock --check`")
    if not (root / ".python-version").exists():
        add("WARN", "environment", ".python-version missing: the interpreter version is not pinned")

    # --- git hygiene -------------------------------------------------------
    gitignore = read(root / ".gitignore") if (root / ".gitignore").exists() else ""
    for entry in (".venv", ".snakemake", "results"):
        if entry not in gitignore:
            add("WARN", "gitignore", f"{entry}/ is not in .gitignore")

    # --- report needs pygments ---------------------------------------------
    if "report(" in snake_text and "pygments" not in deps:
        add("ERROR", "report", "workflow uses report() but pygments is not a dependency: `snakemake --report` fails without it")

    # --- scripts: config values that Snakemake does not track ----------------
    scripts = [p for p in workflow_dir.rglob("*") if p.suffix in {".py", ".R", ".r"} and "scripts" in p.parts]
    for script in scripts:
        # Ignore comments and docstrings so that prose mentioning the pattern is not flagged
        text = re.sub(r'""".*?"""|\'\'\'.*?\'\'\'', "", read(script), flags=re.S)
        text = re.sub(r"(?m)^\s*#.*$", "", text)
        if re.search(r"snakemake\.config|snakemake@config", text):
            add("WARN", "provenance", f"{script.relative_to(root)} reads snakemake.config: changing that value will NOT rerun the rule; pass it via params: or input:")
        if re.search(r"\bpip install\b|install\.packages\(", text):
            add("ERROR", "environment", f"{script.relative_to(root)} installs packages at run time; declare them in the environment instead")
    if re.search(r"\bpip install\b", snake_text):
        add("ERROR", "environment", "Snakefile runs `pip install`; declare dependencies in pyproject.toml")

    # --- Snakefile hygiene -------------------------------------------------
    for pattern, label in ((r"[\"']/(home|users|scratch|work)/", "absolute Unix path"), (r"[\"'][A-Za-z]:[\\/]", "absolute Windows path")):
        if re.search(pattern, snake_text, flags=re.I):
            add("WARN", "paths", f"Snakefile contains an {label}: use paths relative to the project root")
    rule_blocks = re.split(r"^rule\s+", snake_text, flags=re.M)[1:]
    for block in rule_blocks:
        name = block.split(":", 1)[0].strip()
        if name == "all":
            continue
        if not re.search(r"^\s+log:", block, flags=re.M):
            add("INFO", "logging", f"rule {name} has no log: directive")
        if not re.search(r"^\s+resources:", block, flags=re.M):
            add("INFO", "resources", f"rule {name} has no resources: (falls back to profile defaults)")
        if re.search(r"^\s+seed\s*=\s*\d+\s*$", block, flags=re.M):
            add("INFO", "seeds", f"rule {name} hard-codes a seed; prefer one from config")

    # --- Slurm profiles ----------------------------------------------------
    profile_files = [p for p in (workflow_dir / "profiles").glob("*/*.yaml")] + [p for p in (root / "profiles").glob("*/*.yaml")]
    try:
        import yaml  # type: ignore
    except ImportError:
        yaml = None
        if profile_files:
            add("INFO", "profile", "PyYAML not importable: profile checks skipped")
    for pf in profile_files if yaml else []:
        rel = pf.relative_to(root)
        text = read(pf)
        cfg = yaml.safe_load(text) or {}
        if str(cfg.get("executor", "")) != "slurm":
            continue
        if re.search(r"<[A-Z_]+>", text):
            add("ERROR", "profile", f"{rel} still contains <PLACEHOLDER> values: fill them from the site documentation or the user's cluster output")
        blocks = [("default-resources", cfg.get("default-resources") or {})]
        blocks += [(f"set-resources:{k}", v) for k, v in (cfg.get("set-resources") or {}).items() if isinstance(v, dict)]
        for label, res in blocks:
            if "mem_mb" in res and "mem_mb_per_cpu" in res:
                add("ERROR", "profile", f"{rel} {label}: mem_mb and mem_mb_per_cpu are mutually exclusive")
        d = cfg.get("default-resources") or {}
        if "runtime" not in d:
            add("WARN", "profile", f"{rel}: no default runtime (minutes); jobs get the site default")
        if "slurm_partition" not in d:
            add("INFO", "profile", f"{rel}: no default slurm_partition (fine if the site has a default partition)")
        if "jobs" not in cfg and "cores" not in cfg:
            add("ERROR", "profile", f"{rel}: neither jobs nor cores is set; the Slurm executor requires --jobs")
        if int(cfg.get("latency-wait", 5)) < 30:
            add("INFO", "profile", f"{rel}: latency-wait < 30 s; shared filesystems can lag behind job completion")
        # Rules asking for more than the default through resources: are fine; just flag huge jobs counts
        if int(cfg.get("jobs", 1)) > 100:
            add("WARN", "profile", f"{rel}: jobs > 100 may breach site fair-use limits; check the cluster docs")

    return report()


def report() -> int:
    order = {"ERROR": 0, "WARN": 1, "INFO": 2}
    findings.sort(key=lambda f: order[f[0]])
    if not findings:
        print("OK  no findings")
    for level, check, message in findings:
        print(f"{level:<5} {check:<12} {message}")
    return 1 if any(f[0] == "ERROR" for f in findings) else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()))
