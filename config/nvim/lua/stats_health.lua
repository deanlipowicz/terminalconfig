local M = {}

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return ""
  end
  local content = file:read("*a") or ""
  file:close()
  return content
end

local function write_file(path, content)
  local file = assert(io.open(path, "w"))
  file:write(content)
  file:close()
end

local function path_join(...)
  local path = table.concat({ ... }, "/")
  return (path:gsub("//+", "/"))
end

local function shell_escape(value)
  return vim.fn.shellescape(value)
end

local function executable_report(name)
  local path = vim.fn.exepath(name)
  if path ~= "" then
    return { available = true, path = path }
  end

  local mason_path = path_join(vim.fn.stdpath("data"), "mason", "bin", name)
  if vim.fn.executable(mason_path) == 1 then
    return { available = true, path = mason_path }
  end

  return { available = false, path = nil }
end

local function list_contains(values, target)
  for _, value in ipairs(values) do
    if value == target then
      return true
    end
  end
  return false
end

local function check_logs()
  local state = vim.fn.stdpath("state")
  local lsp_log = read_file(path_join(state, "lsp.log"))
  local nvim_log = read_file(path_join(state, "nvim.log"))
  local checks = {
    sql_lsp_crash = lsp_log:find("ERR_PACKAGE_PATH_NOT_EXPORTED", 1, true) ~= nil,
    clangd_missing_compile_database = lsp_log:find("Failed to find compilation database", 1, true) ~= nil,
    treesitter_decoration_error = nvim_log:find("decor_provider_error", 1, true) ~= nil,
  }
  return checks
end

local representative_files = {
  { role = "DuckDB SQL", path = "analysis/sql/transform.sql", expected = "lint-only" },
  { role = "R analysis", path = "analysis/r/script.R", expected = "r_language_server" },
  { role = "Stan model", path = "analysis/stan/model.stan", expected = "stanc-check" },
  { role = "C++ kernel", path = "analysis/cpp/kernel.cpp", expected = "clangd" },
  { role = "HTML report", path = "dist/index.html", expected = "html" },
}

local function inspect_buffers(root)
  local original = vim.api.nvim_get_current_buf()
  local reports = {}

  for _, item in ipairs(representative_files) do
    local full_path = path_join(root, item.path)
    local report = {
      role = item.role,
      path = item.path,
      exists = vim.uv.fs_stat(full_path) ~= nil,
      expected = item.expected,
      filetype = nil,
      lsp_clients = {},
      diagnostics = nil,
    }

    if report.exists then
      vim.cmd("silent edit " .. vim.fn.fnameescape(full_path))
      local bufnr = vim.api.nvim_get_current_buf()
      vim.wait(800, function()
        return #vim.lsp.get_clients({ bufnr = bufnr }) > 0 or item.expected == "lint-only" or item.expected == "stanc-check"
      end, 50)

      report.filetype = vim.bo[bufnr].filetype
      report.diagnostics = #vim.diagnostic.get(bufnr)
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        table.insert(report.lsp_clients, client.name)
      end
    end

    table.insert(reports, report)
  end

  if vim.api.nvim_buf_is_valid(original) then
    vim.api.nvim_set_current_buf(original)
  end

  return reports
end

local function markdown_report(report)
  local lines = {
    "# Statistical Workbench Health",
    "",
    "Generated: `" .. report.generated_at .. "`",
    "",
    "Project root: `" .. report.project_root .. "`",
    "",
    "## Tools",
    "",
    "| tool | available | path |",
    "| --- | --- | --- |",
  }

  for _, name in ipairs(report.tool_order) do
    local meta = report.tools[name]
    table.insert(lines, ("| %s | %s | %s |"):format(name, tostring(meta.available), meta.path or ""))
  end

  table.insert(lines, "")
  table.insert(lines, "## Representative Buffers")
  table.insert(lines, "")
  table.insert(lines, "| role | path | filetype | expected | LSP clients | diagnostics |")
  table.insert(lines, "| --- | --- | --- | --- | --- | --- |")
  for _, buffer in ipairs(report.buffers) do
    table.insert(
      lines,
      ("| %s | `%s` | %s | %s | %s | %s |"):format(
        buffer.role,
        buffer.path,
        buffer.filetype or "",
        buffer.expected,
        table.concat(buffer.lsp_clients or {}, ", "),
        buffer.diagnostics == nil and "" or tostring(buffer.diagnostics)
      )
    )
  end

  table.insert(lines, "")
  table.insert(lines, "## Terminal Buffers")
  table.insert(lines, "")
  local term_buffers = vim.tbl_filter(function(bufnr)
    return vim.bo[bufnr].buftype == "terminal"
  end, vim.api.nvim_list_bufs())
  if #term_buffers > 0 then
    table.insert(lines, ("Neovim terminal buffers found: `%d`"):format(#term_buffers))
    for _, bufnr in ipairs(term_buffers) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      table.insert(lines, ("- `%s`"):format(name ~= "" and name or "(no name)"))
    end
  else
    table.insert(lines, "No Neovim terminal buffers open. Open a terminal with `:term` then use vim-slime to send code.")
  end

  table.insert(lines, "")
  table.insert(lines, "## Log Signals")
  table.insert(lines, "")
  for name, present in pairs(report.log_signals) do
    table.insert(lines, ("- `%s`: `%s`"):format(name, tostring(present)))
  end

  table.insert(lines, "")
  table.insert(lines, "## Warnings")
  table.insert(lines, "")
  if #report.warnings == 0 then
    table.insert(lines, "No warnings.")
  else
    for _, warning in ipairs(report.warnings) do
      table.insert(lines, "- " .. warning)
    end
  end

  return table.concat(lines, "\n") .. "\n"
end

function M.run(opts)
  opts = opts or {}
  local root = opts.root or vim.fn.getcwd()
  root = vim.fn.fnamemodify(root, ":p"):gsub("/$", "")
  local out_dir = path_join(root, ".artifacts", "neovim-maintenance")
  vim.fn.mkdir(out_dir, "p")

  local tool_order = {
    "Rscript",
    "r-languageserver",
    "sqlfluff",
    "prettier",
    "eslint",
    "quarto",
    "clangd",
    "marksman",
    "lua-language-server",
  }
  local tools = {}
  for _, name in ipairs(tool_order) do
    tools[name] = executable_report(name)
  end

  local log_signals = check_logs()
  local buffers = inspect_buffers(root)
  local warnings = {}

  if log_signals.sql_lsp_crash then
    table.insert(warnings, "Previous Neovim LSP logs contain sql-language-server crash output; sqlls is disabled in this config.")
  end
  if log_signals.clangd_missing_compile_database and vim.fn.filereadable(path_join(root, "compile_commands.json")) == 0 then
    table.insert(warnings, "clangd logs mention a missing compilation database and this project has no compile_commands.json.")
  end
  if log_signals.treesitter_decoration_error then
    table.insert(warnings, "Previous Neovim logs contain a Tree-sitter decoration error; update parsers/plugins if it recurs.")
  end

  for _, buffer in ipairs(buffers) do
    if buffer.expected == "r_language_server" and not list_contains(buffer.lsp_clients, "r_language_server") then
      table.insert(warnings, "R buffer did not attach r_language_server: " .. buffer.path)
    elseif buffer.expected == "clangd" and not list_contains(buffer.lsp_clients, "clangd") then
      table.insert(warnings, "C++ buffer did not attach clangd: " .. buffer.path)
    elseif buffer.expected == "html" and #buffer.lsp_clients == 0 then
      table.insert(warnings, "HTML buffer did not attach an LSP client: " .. buffer.path)
    end
  end

  local term_buffers = vim.tbl_filter(function(bufnr)
    return vim.bo[bufnr].buftype == "terminal"
  end, vim.api.nvim_list_bufs())

  local report = {
    generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    project_root = root,
    tools = tools,
    tool_order = tool_order,
    buffers = buffers,
    term_buffer_count = #term_buffers,
    log_signals = log_signals,
    warnings = warnings,
  }

  local json_path = path_join(out_dir, "workbench-health.json")
  local md_path = path_join(out_dir, "workbench-health.md")
  write_file(json_path, vim.json.encode(report) .. "\n")
  write_file(md_path, markdown_report(report))

  vim.notify("Workbench health written to " .. md_path, vim.log.levels.INFO)
  return report
end

function M.setup()
  vim.api.nvim_create_user_command("StatsWorkbenchHealth", function(opts)
    M.run({ root = opts.args ~= "" and opts.args or nil })
  end, {
    complete = "dir",
    nargs = "?",
    desc = "Write bounded statistical workbench health artifacts",
  })
end

return M
