# Neovim Maintenance

This note keeps routine review of the statistical-computing Neovim setup
bounded and non-mutating. It is for editor health, plugin drift, and tool
availability checks. It is not an analysis execution plan.

## Authoritative Paths

- Active config: `/home/workstation/.config/nvim`
- Symlink target:
  `/home/workstation/.config/nvim`
- Lazy lockfile: use the path printed by `scripts/smoke-check.sh`.

When Neovim is launched normally, the active config is loaded through
`/home/workstation/.config/nvim`. If the same files are loaded directly with
`nvim -u /path/to/init.lua`, Lazy may resolve paths differently. Prefer normal
startup for maintenance checks unless you are deliberately testing an alternate
config path.

## Periodic Review Checklist

Run this review after plugin updates, system package changes, terminal changes,
or when language tooling behaves differently than expected.

- Confirm headless startup succeeds.
- Confirm Lazy resolves the expected lockfile and key plugins are registered.
- Check for lockfile drift before accepting plugin updates.
- Open representative scratch buffers for `sql`, `r`, `stan`, `cpp`, `html`,
  `javascript`, `css`, and `quarto`.
- Confirm snippet counts are present for the statistical-computing filetypes.
- Check LSP availability with `:LspInfo` in representative buffers.
- Check Treesitter parser availability with `:TSInstallInfo`.
- Check formatter and linter executable availability.
- Confirm the terminal buffer target with `:SlimeConfig` before sending code (open a terminal with `:term` first).
- Confirm Quarto preview/render commands are defined; run them only when
  runtime execution is explicitly intended.
- Confirm Molten/Image behavior in the active terminal if notebook-style output
  is needed.
- Run `:StatsWorkbenchHealth` from the project root to write bounded LSP,
  formatter, Mason, terminal buffers, and log-signal artifacts under
  `.artifacts/neovim-maintenance/`.

## Bounded Command Reference

Use these commands for compact editor inspection:

```sh
nvim --headless '+qa!'
```

```sh
.config/nvim/scripts/smoke-check.sh
```

```sh
nvim --headless '+checkhealth' '+qa!'
```

Inside Neovim:

```text
:Lazy
:LspInfo
:TSInstallInfo
:ConformInfo
:checkhealth
:SlimeConfig
:QuartoPreview
:QuartoRender
:StatsWorkbenchHealth
```

Use `:QuartoPreview`, `:QuartoRender`, Molten evaluation, Slime sending, and
language-specific execution only when runtime execution is intended.

## Review Artifacts

Keep long maintenance output out of source files and conversations. Store it
under `.artifacts/`, for example:

```sh
mkdir -p .artifacts/neovim-maintenance
.config/nvim/scripts/smoke-check.sh \
  > .artifacts/neovim-maintenance/smoke-check.txt 2>&1
```

Small summaries can stay in the conversation. Large logs, health reports, or
tool inventories should be written as artifacts.

## External Tool Expectations

The smoke check reports whether these commands or paths are visible. It does
not run DuckDB, R scripts, C++, Stan, Quarto renders, browser tooling, or build
pipelines.

- `Rscript`
- `sqlfluff`
- `prettier`
- `eslint`
- `quarto`
- `.pi/bin/stanc-check`
- `/home/workstation/.local/venvs/quarto-jupyter/bin/python`

The R package `styler` is expected by the formatter configuration, but checking
R package installation requires running R and should be done only when the user
explicitly asks for that runtime check.

## Statistical Boundary

Maintenance review may identify broken editor features, missing executables,
or drift in plugin behavior. It should not decide research questions,
estimands, modelling strategy, assumptions, variable definitions, or final
interpretation.
