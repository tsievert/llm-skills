# CRLF and other Windows-origin script problems

## Contents

- Symptoms
- Finding and fixing CRLF
- Detecting it reliably in Git Bash
- Preventing it
- Related script-writing traps

## Symptoms

`sbatch: Batch script contains DOS line breaks`, `bad interpreter: /bin/bash^M`, or odd syntax errors on the cluster. CRLF often affects several file types at once (shell, Python, yaml, json). `scripts/check_sbatch.sh` flags CRLF in a job script.

## Finding and fixing CRLF

```bash
grep -rlIU $'\r' --include='*.sh' --include='*.py' --include='*.yaml' --include='*.json' .
sed -i 's/\r$//' <files>
chmod +x <scripts>        # restore the executable bit if it was lost
```

Files made by the editor's write tool on Windows are CRLF too (check with `file`; alternative fix `sed -i 's/[[:cntrl:]]$//'`). If a multi-line replace in an editing tool reports "string not found" on a Windows-origin script, suspect CRLF, and run `file` after tool edits to catch mixed endings.

## Detecting it reliably in Git Bash

Plain `grep -c $'\r'` and `cat -A` can report zero carriage returns on CRLF files there. `grep -U` counts them, and so does `file`; use one of those in any script or test that detects CRLF.

## Preventing it

Set `*.sh text eol=lf` (and the other script types) in `.gitattributes` so the working copy is LF.

## Related script-writing traps

- A large bash heredoc can silently truncate a script; the only sign may be the shell warning "here-document delimited by end-of-file", so check the last lines.
- Quoting `$'\r'` or backslash sequences through `sed`/`awk` fails silently: change such lines with the edit tool and recheck with `grep -U`.
- Slurm reads `#SBATCH` lines from the content, so a `.slurm` or other extension should not matter (cause of one "did not work" report not established); name batch scripts `.sh` and run `file script.sh` to rule out CRLF.
