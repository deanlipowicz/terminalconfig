# Token Discipline Defaults

Use compact context by default.

- Inspect narrowly before reading or changing files.
- Prefer `rg`, `sed -n`, `tail -n`, `git diff`, focused path lists, and version lines over whole-file or whole-log dumps.
- Avoid reading large data files or generated artifacts into the conversation.
- Store derived summaries for large data or logs under `.artifacts/` when a summary is needed.
- For build or compiler failures, inspect the first real error before reading the rest of the log.
- Prefer diffs, minimal patches, and line-specific references over full-file rewrites.
- Do not repeat project background that is already present in instruction files.
- Keep responses concise: skip preambles, recaps, and long explanations unless the user asks for them.
- Before a long context reset or handoff, preserve only decisions, changed files, next steps, and known risks.
