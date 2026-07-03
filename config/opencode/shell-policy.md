# Shell Policy

## Default shell: zsh

The `shell` config is set to `/usr/bin/zsh`. This is used for all general shell
scripts and commands. It preserves the zsh aliases, Oh My Zsh plugins, and
integrations documented in `terminal-applications/terminal-env.md` (eza, bat,
fd, lazygit, tmux, zoxide, etc.).

## Data querying: nushell

For tasks that involve querying, filtering, or transforming structured data —
JSON, CSV, TSV, tables, nested records, directories-as-tables — use nushell
explicitly:

```zsh
nu -c "open data.json | select field1 field2 | where field1 > 5"
nu -c "ls | where type == file | sort-by size | reverse | first 10"
nu -c "open data.csv | group-by category | pivot"
nu -c "http get https://api.example.com/data | from json | select id name"
```

Nushell is installed at `~/.local/bin/nu` (version 0.113.1) with these plugins:
- `nu_plugin_formats` — extra file format support
- `nu_plugin_query` — web query (CSS, XPath, JSON)
- `nu_plugin_polars` — DataFrame operations for larger datasets

## Shell over Python

Prefer zsh or nushell over Python for workflow tasks:
- File operations, process management, text manipulation → zsh
- Data querying, filtering, structured output → nushell (`nu -c "..."`)
- Only use Python when the task requires libraries unavailable in shell
  (e.g., ML/NLP, complex math, binary protocols, web scraping beyond what
  nushell's `http get` or `nu_plugin_query` can handle)
