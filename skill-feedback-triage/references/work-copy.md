# Work copy of the inbox

The assistant's R session is blocked from paths outside the project, so copy the inbox into a git-ignored folder
first with bash (lesson text is then never committed):

```bash
rm -rf .posit/assistant/lessons-work    # a leftover copy re-triages already archived files
mkdir -p .posit/assistant/lessons-work
cp -r ~/.posit/lessons/inbox ~/.posit/lessons/usage.tsv .posit/assistant/lessons-work/
cp ~/.posit/lessons/dispositions.tsv .posit/assistant/lessons-work/ 2>/dev/null   # per-entry ledger; absent on the first run
rm -rf .posit/assistant/lessons-work/inbox/processed
ls -p ~/.posit/lessons/inbox | grep -v / | wc -l; ls .posit/assistant/lessons-work/inbox | wc -l   # counts must match (-p/grep -v excludes the processed folder)
```

Delete `.posit/assistant/lessons-work` once the run is archived. If the permission layer blocks the `rm -rf`
(for example after a postponed run), leave the folder and ask the user to approve the deletion; the first
command above removes a leftover copy at the start of the next run.
Variant-named leftovers (for example `lessons-work2`) are not touched by that command: check what they contain, then delete them only with the user's approval.
