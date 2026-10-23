# Secrets, accidental data and history rewrites

Contents: prevention; detection; response order; running git filter-repo; when not to rewrite; personal or protected data.

## Prevention

- Credentials live in environment variables. For R, `~/.Renviron` (outside the project, or ignored if inside); never in scripts, notebooks, `_targets.R`, config YAML or the README. A token typed literally into R code is echoed to the console and saved in the R history.
- The starter `.gitignore` ignores `.env`, `.Renviron`, `*.pem`, `*.key`. This catches file names only.
- Do not write tokens into the assistant's memory files, `AGENTS.md`, lesson entries, commit messages or issue text.
- Run `audit_repo()` before the first push and before a release.

## Detection

`audit_repo()` looks at (a) file names such as `.env`, `.Renviron`, `id_rsa`, `*.pem`, `*.key`, (b) text lines matching GitHub tokens, AWS key ids, private-key blocks, and assignments such as `token <- "..."` with a 16+ character value, and (c) with `history = TRUE`, names of credential-like files ever added in any commit. Values are never printed, only `file:line` and the pattern name.

Limits (tested on seeded examples, not on real leaks): Zenodo, Figshare and many other tokens have no recognisable prefix, so they are caught only when assigned to a variable named like `token`, `key`, `secret` or `password`. File contents are scanned only for the working tree and files under 1 MiB, not for old commits. Dedicated scanners (for example gitleaks, trufflehog) scan history and use many more rules; neither is installed here and neither was tested.

## Response, in this order

1. **Rotate or revoke the credential first.** Once pushed to a public repository, treat it as exposed; bots scan new commits. GitHub's guidance says rewriting history may not even be necessary after rotation.
2. Decide whether a rewrite is worth it: needed for personal data, unpublished sensitive data, or a credential that cannot be rotated. For an already-rotated token in a private repository it often is not.
3. If rewriting: tell the user the consequences (hashes change, collaborators must reclone or rebase, forks keep the old commits, the remote needs a force push, GitHub Support purges cached views). The assistant shows the commands and the user runs them.
4. Remove the file from the working tree and add it to `.gitignore` so it is not re-added.

## Running git filter-repo

GitHub's current instructions (read 2026-10-23) need git-filter-repo 2.47 or newer for `--sensitive-data-removal`, run on a fresh clone:

```bash
git clone https://github.com/OWNER/REPO && cd REPO
git-filter-repo --sensitive-data-removal --invert-paths --path path/to/file    # whole file, full Git path
git-filter-repo --sensitive-data-removal --replace-text ../patterns.txt         # text inside non-binary files
grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs                    # affected pull requests
git push --force --mirror origin                                               # irreversible step; pull refs may fail, that is expected
```

If a file was renamed, add a `--path` for each old path. Afterwards contact GitHub Support with owner and repository name, the number of affected pull requests and the "First Changed Commit(s)" from the output; collaborators rebase (never merge) old branches; forks must be handled by their owners.

Local test on Windows (2026-10-23): `git filter-repo` is not installed, but `uvx git-filter-repo` works (the `--version` call prints a commit hash, not a number). On a scratch clone, `uvx git-filter-repo --sensitive-data-removal --invert-paths --path .env --path big.bin` removed both files from all commits (checked with `git log --all --name-only`), wrote `.git/filter-repo/` with `changed-refs`, `first-changed-commits` and `sensitive_data_removal`, and **kept the `origin` remote** (ordinary filter-repo runs remove it, per its documentation; that case was not run). Not tested: the push, GitHub Support, forks, LFS orphan messages.

## When not to rewrite

- The credential is rotated and the repository is private and unshared.
- Other people already cloned and merged; a rewrite creates more trouble than it removes.
- The "secret" is a false positive (a long example string). Check before acting.

## Personal data or protected-species locations

Treat these like secrets for history purposes (same removal procedure) but they also have legal and ethical dimensions (permits, consent, data protection). Do not decide for the user: say what was found, say that removal from the current tree does not remove it from history, and ask how they want to proceed (and whether their institution's data protection contact must be told).
