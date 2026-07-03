# Statistical Computing Workflow

This Neovim setup is an editor surface for DuckDB, Arrow, R, Stan, and C++
source text. It should help author, inspect, and review code without becoming
the owner of analysis execution or statistical interpretation.

## DuckDB and Arrow

- Keep relational data shaping in DuckDB SQL.
- Use `.pi/bin/duckdb-schema` from the project root when a compact database
  summary is needed. It writes schema, table, column, row-count, null-count, and
  describe artifacts under `.artifacts/duckdb/`.
- Use bounded review queries, for example `LIMIT 20`, for small inspection
  slices.
- Keep Arrow and Parquet review compact. Do not paste large raw data into an AI
  context; write summaries under `.artifacts/`.
- SQL formatting uses `sqlfluff --dialect duckdb`. Review formatter diffs
  before accepting them, especially when SQL layout carries review context.
- SQL LSP diagnostics are intentionally disabled in this setup until a stable
  DuckDB-aware server is selected. Use `sqlfluff` linting plus bounded Pi data
  artifacts for SQL review.

## R and Tidyverse

- Use R for statistical analysis, diagnostics, summaries, and plots.
- Keep joins, filters, type casts, and staged relational transformations in
  DuckDB unless there is a deliberate reason to handle them in R.
- Surface material package defaults, model assumptions, contrasts, missing-data
  handling, and grouping definitions in comments or companion notes.
- Write compact diagnostic, table, and figure outputs under `.artifacts/` or
  `dist/data/`.
- Use `K` for language-server hover when available. Use `<leader>dr` or
  `:RDoc topic package` to open CRAN reference documentation, and
  `<leader>dR` or `:RDocPkg package` to open a package index.

## Stan

- Use `.pi/bin/stanc-check` as the bounded syntax check.
- Review parameter constraints, prior scale, transformed parameter validity,
  generated quantities consistency, and whether report quantities are
  recoverable.
- Keep data transformation outside Stan. Stan files should express the
  probability model and generated quantities.
- Add posterior predictive quantities or pointwise log likelihood when they are
  needed for diagnostics or model comparison.
- Use `<leader>ds` or `:StanDoc` for the official Stan documentation,
  `<leader>df` or `:StanFunctions` for the Functions Reference, and
  `<leader>dS` or `:StanSearch query` for scoped Stan documentation search.

## C++ Kernels

- Use C++ for deterministic numeric kernels, not statistical interpretation or
  hidden data shaping.
- Validate dimensions, bounds, non-finite values, overflow risk, and division
  by zero near the interface.
- Keep outputs small and explicit so R, Stan, or reports can consume them.
- `clangd` works best when the project provides `compile_commands.json`.
  Generate or maintain that file in the project build system when include paths
  for Rcpp, Eigen, Boost, or Stan Math are needed.
- `:StatsWorkbenchHealth` records whether representative SQL, R, Stan, C++,
  and report buffers have the expected editor support without running analysis
  jobs.

## Communication and Visualisation

- Prefer semantic HTML with Pico CSS for standalone reports and compact review
  artifacts.
- Use Alpine.js for small interactions such as toggles, tabs, filters, and
  expandable notes. Keep state local to the component when possible.
- Use Observable Plot for routine statistical graphics such as scatter plots,
  faceted plots, histograms, uncertainty ribbons, and grouped summaries.
- Use Chart.js for simple dashboards, status views, and small embedded charts.
- Use Reveal for slide decks, speaker notes, and figure-heavy presentations.
- Reserve D3 for bespoke visualisation that needs custom marks, layout, or
  interaction beyond the routine reporting stack.
- Keep final communication files plain HTML, CSS, and JavaScript where
  practical. Quarto remains available for literate reports and can be previewed
  with `<leader>qp` or rendered with `<leader>qr` when runtime execution is
  explicitly intended.

## Maintenance

- Use `MAINTENANCE.md` for periodic Neovim review routines, smoke checks, and
  bounded command references.
- Store long maintenance output under `.artifacts/` rather than source files or
  conversation context.
- Keep maintenance checks non-mutating unless runtime execution is explicitly
  requested.
