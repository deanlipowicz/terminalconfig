#!/usr/bin/env bash
set -u

status=0

section() {
  printf '\n== %s ==\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  status=1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1"
}

run_required() {
  desc="$1"
  shift
  if "$@"; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

section "Config"
active_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
printf 'active_config=%s\n' "$active_config"
if command -v readlink >/dev/null 2>&1; then
  printf 'resolved_config=%s\n' "$(readlink -f "$active_config" 2>/dev/null || printf '%s' "$active_config")"
fi

section "Headless Startup"
run_required "nvim headless startup" nvim --headless '+qa!'

section "Lazy Registration"
nvim --headless \
  '+lua local lazy=require("lazy.core.config"); print("lockfile=" .. tostring(lazy.options.lockfile)); local expected={"blink.cmp","LuaSnip","nvim-treesitter","quarto-nvim","otter.nvim","vim-slime","molten-nvim","image.nvim","conform.nvim","nvim-lint","nvim-lspconfig","snacks.nvim"}; for _,name in ipairs(expected) do print(name .. "=" .. tostring(lazy.plugins[name] ~= nil)) end; print("")' \
  '+qa!'
if [ "$?" -eq 0 ]; then
  pass "Lazy plugin registration query"
else
  fail "Lazy plugin registration query"
fi

section "Representative Filetypes"
nvim --headless \
  '+lua local files={["analysis.sql"]="sql",["analysis.R"]="r",["model.stan"]="stan",["kernel.cpp"]="cpp",["report.html"]="html",["app.js"]="javascript",["style.css"]="css",["report.qmd"]="quarto",["article.tex"]="tex",["package.sty"]="tex",["class.cls"]="tex",["letter.ltx"]="tex"}; for name,ft in pairs(files) do vim.cmd("enew"); vim.api.nvim_buf_set_name(0, name); vim.bo.filetype=ft end' \
  '+qa!'
if [ "$?" -eq 0 ]; then
  pass "representative scratch filetypes"
else
  fail "representative scratch filetypes"
fi

section "Filetype Detection"
nvim --headless \
  '+lua local files={["report.qmd"]="quarto",["model.stan"]="stan",["letter.ltx"]="tex",["package.sty"]="tex",["class.cls"]="tex"}; local ok=true; for name,ft in pairs(files) do local detected=vim.filetype.match({ filename=name }); print(name .. "=" .. tostring(detected)); ok=ok and detected == ft end; if not ok then error("unexpected filetype detection") end; print("")' \
  '+qa!'
if [ "$?" -eq 0 ]; then
  pass "local filetype detection"
else
  fail "local filetype detection"
fi

section "Lint Mappings"
nvim --headless \
  '+lua require("lazy").load({ plugins = { "nvim-lint" } }); local lint=require("lint"); local expected={"tex","plaintex","r","markdown","quarto","html","css","json","yaml"}; local ok=true; for _,ft in ipairs(expected) do local configured=lint.linters_by_ft[ft] ~= nil and #lint.linters_by_ft[ft] > 0; print(ft .. "=" .. tostring(configured)); ok=ok and configured end; if not ok then error("missing lint mapping") end; print("")' \
  '+qa!'
if [ "$?" -eq 0 ]; then
  pass "nvim-lint mapping query"
else
  fail "nvim-lint mapping query"
fi

section "Snippet Counts"
nvim --headless --cmd 'lua vim.loader.enable(false)' \
  '+lua require("lazy").load({ plugins = { "LuaSnip" } }); local ls=require("luasnip"); for _,ft in ipairs({"sql","r","stan","cpp","html","javascript","quarto"}) do print(ft .. "=" .. tostring(#ls.get_snippets(ft))) end; print("")' \
  '+qa!'
if [ "$?" -eq 0 ]; then
  pass "LuaSnip snippet query"
else
  fail "LuaSnip snippet query"
fi

section "Documentation Commands"
nvim --headless \
  '+lua require("stats_docs"); local expected={"RDoc","RDocPkg","StanDoc","StanFunctions","StanSearch"}; local commands=vim.api.nvim_get_commands({}); for _,name in ipairs(expected) do print(name .. "=" .. tostring(commands[name] ~= nil)) end; print("")' \
  '+qa!'
if [ "$?" -eq 0 ]; then
  pass "documentation command registration query"
else
  fail "documentation command registration query"
fi

section "Workbench Health"
health_output="$(nvim --headless "+StatsWorkbenchHealth $(pwd)" '+qa!' 2>&1)"
health_status="$?"
printf '%s\n' "$health_output"
if [ "$health_status" -eq 0 ] && ! printf '%s\n' "$health_output" | grep -Eq 'Error in command line|stack traceback|^Error detected'; then
  pass "workbench health artifact"
else
  fail "workbench health artifact"
fi

section "Executable Presence"
for exe in Rscript chktex sqlfluff prettier eslint quarto xdg-open; do
  if command -v "$exe" >/dev/null 2>&1; then
    printf 'FOUND: %s -> %s\n' "$exe" "$(command -v "$exe")"
  else
    warn "$exe not found"
  fi
done

if [ -x ".pi/bin/stanc-check" ]; then
  printf 'FOUND: .pi/bin/stanc-check\n'
else
  warn ".pi/bin/stanc-check not executable from $(pwd)"
fi

python_host="/home/workstation/.local/venvs/quarto-jupyter/bin/python"
if [ -x "$python_host" ]; then
  printf 'FOUND: %s\n' "$python_host"
else
  warn "$python_host not executable"
fi

section "Boundary"
printf '%s\n' "No DuckDB, R script, C++, Stan, Quarto render, browser, or build tooling was executed."

exit "$status"
