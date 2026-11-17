# When something fails: search upstream before improvising

DLC moves fast, so an unexpected error is often a known bug, a regression in the installed version, or already fixed on `main`. Before inventing a workaround:

1. Get from the user the cluster's DLC version (`deeplabcut.__version__`), the engine, the PyTorch/CUDA versions, and the exact error message (first and last lines of the traceback). The searches below run locally, where the internet is available.
2. Search issues, open and closed, for the error text or function name (`gh` is preferred when installed; it was not on PATH on the maintainer machine, where the keyless REST API worked: `https://api.github.com/repos/DeepLabCut/DeepLabCut/releases`, `/pulls/<n>`, `/issues/<n>`):
   - `gh search issues --repo DeepLabCut/DeepLabCut "<error text>" --sort updated`
   - `gh issue view <number> --repo DeepLabCut/DeepLabCut --comments`
3. Search pull requests for fixes in progress or merged:
   - `gh search prs --repo DeepLabCut/DeepLabCut "<keyword>" --sort updated`
   - `gh pr view <number> --repo DeepLabCut/DeepLabCut`
   - If a code comment or config cites an issue number as the source of an in-progress feature, check for superseding or merged PRs too, not just the cited issue. Fast-moving repos often ship a different final design than the first proposal (reported once, 2026-10-26).
4. Check recent commits and releases:
   - `gh api "repos/DeepLabCut/DeepLabCut/commits?per_page=30"`
   - `gh release list --repo DeepLabCut/DeepLabCut`
   - For a suspect file: `gh api "repos/DeepLabCut/DeepLabCut/commits?path=<file path>&per_page=10"`
5. Check the forum: https://forum.image.sc/tag/deeplabcut
6. Compare dates with the installed version. If a fix is merged but unreleased, offer these options and let the user choose: pin an older release, install the pre-release (`pip install --pre deeplabcut`), or install from `main` (`pip install git+https://github.com/DeepLabCut/DeepLabCut.git`; less stable, and a non-CRAN-style source install the user must approve).
7. Report what you found with links, and say plainly whether an issue is confirmed, only similar, or not found. Do not present a workaround from an unrelated or unresolved issue as established. If nothing matches, say so before trying your own diagnosis.

## A feature-support check that returns `False` needs interpretation

A snippet that introspects the installed package for a named config field can report `False` for two reasons: the change has not merged anywhere yet, or it merged to a **non-default branch** the user's install does not track (reported once, 2026-10-26). Check which branch the fix merged into (steps 3 and 4), not just whether a PR merged, and say so. The installed version string is a cheap second signal: a clean release tag (no dev/commit suffix) despite a described from-source install can mean the install did not pick up recent `main` commits.
