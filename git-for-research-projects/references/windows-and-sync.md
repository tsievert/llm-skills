# Windows details and sync folders

Contents: Windows settings; repositories inside sync folders (short hazard note).

## Windows

- `core.autocrlf=true` comes from the system config of Git for Windows; see `ignore-and-attributes.md` for what to do about it. `git config --show-origin --get core.autocrlf` shows where the value comes from.
- Inspect line endings with `git ls-files --eol`.
- Long paths (`core.longpaths`) and case-insensitive collisions (two files differing only in case) are known Windows issues; neither was tested here, so check the Git for Windows documentation before advising.
- Scripts copied to a cluster from the working copy can carry CRLF even when the index is LF. Convert (`sed -i 's/\r$//' file` in Git Bash) or pin with `.gitattributes`.
- From the assistant's R session, writes outside the project folder can be blocked; do repository work inside the project or ask the user to run commands.

## Repositories inside sync folders (Syncthing, OneDrive, Dropbox)

Why it matters: sync tools copy files one by one, and a Git repository is a set of files that must change together. If two devices both change `.git`, the sync can leave an inconsistent repository (Syncthing's maintainers and the Git LFS maintainer both say so; read as forum and search excerpts on 2026-10-23, not tested). The one safe pattern is a repository that is used on a single device, with the sync acting as a backup.

`audit_repo()` flags a repository inside a Syncthing (`.stfolder`) or Dropbox (`.dropbox`) folder and notes whether the Syncthing root has a `.stignore` mentioning `.git`; it also warns when the path contains OneDrive, Dropbox, Google Drive, iCloud, Nextcloud or Seafile. It cannot see whether a second device is attached.

Options to put in front of the user (one short message, then drop it unless asked):

1. Keep as is and edit on one device at a time; run `git fsck` if something looks off.
2. Ignore `.git` (or whole repositories) in the folder's `.stignore`, and move work between devices with `git push` and `git pull`. A `.stignore` is per device and is never synced itself; Syncthing uses the first matching pattern.
3. Move repositories out of the sync folder.

Signs of damage: files named `*sync-conflict*`, `git fsck` errors, stale `.git/*.lock` files.
