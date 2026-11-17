# Usage and maintenance review

Purpose: rank skills by use and edits and spot bloat, overlap or scope creep. This is read-only
with respect to the inbox: no archiving, no dispositions, no watermark change. Earlier triage runs may still have
left dispositions, so take `table(lesson_status(L, D)$status)` as the source of truth for what is closed, not a task list.

1. All-time loads: `read_usage(path)` with no `since`. `read_usage(since = watermark)` returns almost
   nothing right after a run, so `lesson_overview()` then shows zero loads for nearly every skill.
   `skill-lessons` loads are mostly hook-fired; treat them as weak evidence.
2. Edit counts: `git log --format=%H -- <skill>/ | wc -l` per skill folder (since a chosen date).
3. Size: `SKILL.md` bytes and the whole tree bytes/file count per skill.
4. Description length: parse the YAML frontmatter (for example `yaml::yaml.front.matter()` or
   `rmarkdown::yaml_front_matter()`); a regex over the joined file text gives absurd values for
   folded or multi-line descriptions.
5. Combine into one table, then read the top skills for bloat, overlap (see
   `github-skill-maintenance/references/skill-boundaries.md`) and sections needing research.
6. Write the follow-up tasks to a persistent task list in `research/` so they survive restarts.
