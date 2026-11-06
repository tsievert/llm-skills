# Dropped-off conversation exports

Read this only when the user provides conversation-export JSON files as context, either instead of or alongside lesson files.

Read them with `jsonlite::fromJSON(simplifyVector = FALSE)`: each turn is under `messages[[i]]$message$uiMessage` (`role`, `content`), and `content` is plain text with embedded tool-call and tool-result markup mixed in. The markup dominates file size (a 1 MB export can be mostly noise); strip it with a regex before printing, and print each turn truncated.

In practice (3 exports, 0.9 to 1.4 MB each) the exports mostly corroborated lesson files already in the inbox. Read the lesson files first and use an export only to verify a claim or to look for a user correction the lesson writer missed, rather than re-deriving the whole triage from scratch.

Exports can contain personal data and project content: apply the same privacy rule as for lesson entries (see the Privacy section of `SKILL.md`) and never copy text from an export into skills, `AGENTS.md`, commits or search queries.
