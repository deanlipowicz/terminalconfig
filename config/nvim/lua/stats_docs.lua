local M = {}

local CRAN_REFMAN = "https://search.r-project.org/CRAN/refmans"
local STAN_DOCS = "https://mc-stan.org/docs/"
local STAN_FUNCTIONS = "https://mc-stan.org/docs/functions-reference/"

local common_r_packages = {
  aov = "stats",
  approx = "stats",
  cor = "stats",
  glm = "stats",
  lm = "stats",
  loess = "stats",
  median = "stats",
  model_matrix = "stats",
  model_frame = "stats",
  na_omit = "stats",
  optimize = "stats",
  pnorm = "stats",
  qnorm = "stats",
  rnorm = "stats",
  sd = "stats",
  t_test = "stats",
  var = "stats",
  aggregate = "stats",
  anova = "stats",
  reshape = "stats",
  subset = "base",
  transform = "base",
  merge = "base",
  cbind = "base",
  rbind = "base",
}

local function sanitize_token(value)
  if not value or value == "" then
    return nil
  end
  local token = value:gsub("^%s+", ""):gsub("%s+$", "")
  token = token:gsub("^`", ""):gsub("`$", "")
  token = token:gsub("^%?", "")
  token = token:gsub("[%(%),]+$", "")
  if token == "" then
    return nil
  end
  return token
end

local function encode(value)
  value = tostring(value or "")
  return (value:gsub("([^%w%-_%.~])", function(char)
    return string.format("%%%02X", string.byte(char))
  end))
end

local function open_url(url)
  if vim.ui and type(vim.ui.open) == "function" then
    vim.ui.open(url)
    return
  end

  if vim.fn.executable("xdg-open") == 1 then
    vim.fn.jobstart({ "xdg-open", url }, { detach = true })
    return
  end

  vim.notify("No URL opener found for " .. url, vim.log.levels.WARN)
end

local function cursor_text()
  return sanitize_token(vim.fn.expand("<cWORD>")) or sanitize_token(vim.fn.expand("<cword>"))
end

local function selection_text()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]
  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return nil
  end

  lines[1] = lines[1]:sub(start_col)
  lines[#lines] = lines[#lines]:sub(1, end_col)
  return sanitize_token(table.concat(lines, " "))
end

local function parse_r_topic(topic, package)
  topic = sanitize_token(topic)
  package = sanitize_token(package)
  if topic then
    local parsed_package, parsed_topic = topic:match("([%w%.]+)::+([%w%._]+)")
    if parsed_package and parsed_topic then
      package = parsed_package
      topic = parsed_topic
    end
  end
  return topic, package
end

local function r_topic_url(topic, package)
  return ("%s/%s/html/%s.html"):format(CRAN_REFMAN, encode(package), encode(topic))
end

local function r_package_url(package)
  return ("%s/%s/html/00Index.html"):format(CRAN_REFMAN, encode(package))
end

local function prompt_input(prompt, default, callback)
  vim.ui.input({ prompt = prompt, default = default or "" }, function(input)
    input = sanitize_token(input)
    if input then
      callback(input)
    end
  end)
end

function M.open_r_doc(topic, package)
  topic, package = parse_r_topic(topic or cursor_text(), package)
  if not topic then
    prompt_input("R help topic: ", "", function(input_topic)
      M.open_r_doc(input_topic, package)
    end)
    return
  end

  if package then
    open_url(r_topic_url(topic, package))
    return
  end

  local default_package = common_r_packages[topic:gsub("%.", "_")]
  prompt_input("R package for " .. topic .. ": ", default_package or "", function(input_package)
    open_url(r_topic_url(topic, input_package))
  end)
end

function M.open_r_package(package)
  package = sanitize_token(package)
  if not package then
    prompt_input("R package: ", "", function(input_package)
      open_url(r_package_url(input_package))
    end)
    return
  end
  open_url(r_package_url(package))
end

function M.open_stan_docs()
  open_url(STAN_DOCS)
end

function M.open_stan_functions()
  open_url(STAN_FUNCTIONS)
end

function M.search_stan(query)
  query = sanitize_token(query) or selection_text() or cursor_text()
  if not query then
    prompt_input("Stan docs search: ", "", function(input_query)
      M.search_stan(input_query)
    end)
    return
  end

  open_url("https://duckduckgo.com/?q=" .. encode("site:mc-stan.org/docs " .. query))
end

function M.setup()
  vim.api.nvim_create_user_command("RDoc", function(opts)
    local args = opts.fargs
    M.open_r_doc(args[1], args[2])
  end, {
    nargs = "*",
    complete = "file",
    desc = "Open CRAN R topic documentation",
  })

  vim.api.nvim_create_user_command("RDocPkg", function(opts)
    M.open_r_package(opts.args)
  end, {
    nargs = "?",
    complete = "file",
    desc = "Open CRAN package documentation index",
  })

  vim.api.nvim_create_user_command("StanDoc", M.open_stan_docs, {
    desc = "Open official Stan documentation",
  })

  vim.api.nvim_create_user_command("StanFunctions", M.open_stan_functions, {
    desc = "Open official Stan Functions Reference",
  })

  vim.api.nvim_create_user_command("StanSearch", function(opts)
    M.search_stan(opts.args)
  end, {
    nargs = "*",
    desc = "Search official Stan documentation",
  })
end

return M
