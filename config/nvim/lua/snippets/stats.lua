local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local c = ls.choice_node
local rep = require("luasnip.extras").rep
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta

local function line_to_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(1, col)
end

local function count_unescaped_dollars(line)
  local count = 0
  local i_pos = 1
  while true do
    local start = line:find("$", i_pos, true)
    if not start then
      break
    end
    local slash_count = 0
    local j = start - 1
    while j > 0 and line:sub(j, j) == "\\" do
      slash_count = slash_count + 1
      j = j - 1
    end
    if slash_count % 2 == 0 then
      count = count + 1
    end
    i_pos = start + 1
  end
  return count
end

local function in_dollar_math()
  local current = line_to_cursor()
  if count_unescaped_dollars(current) % 2 == 1 then
    return true
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
  local fences = 0
  for _, line in ipairs(lines) do
    local _, matches = line:gsub("%$%$", "")
    fences = fences + matches
  end
  return fences % 2 == 1
end

local function in_mathzone()
  if vim.fn.exists("*vimtex#syntax#in_mathzone") == 1 then
    local ok, result = pcall(vim.fn["vimtex#syntax#in_mathzone"])
    if ok and result == 1 then
      return true
    end
  end
  return in_dollar_math()
end

local function get_visual(args, parent)
  if parent and parent.snippet and parent.snippet.env then
    local selection = parent.snippet.env.LS_SELECT_RAW
    if selection and #selection > 0 then
      return selection
    end
  end
  return args[1] or {}
end

local function visual_node(default)
  return d(1, function(_, parent)
    local selected = get_visual(nil, parent)
    if #selected > 0 then
      return sn(nil, { i(1, table.concat(selected, "\n")) })
    end
    return sn(nil, { i(1, default or "") })
  end)
end

local function math_autosnippet(trigger, expansion, nodes)
  local body = nodes and fmta(expansion, nodes) or t(expansion)
  return s({ trig = trigger, snippetType = "autosnippet", wordTrig = false, condition = in_mathzone }, body)
end

local math_snippets = {
  s("dm", {
    t({ "$$", "" }),
    i(0),
    t({ "", "$$" }),
  }),
  s("im", {
    t("$"),
    i(0),
    t("$"),
  }),
  s("frac", fmta("\\frac{<>}{<>}<>", { i(1, "num"), i(2, "den"), i(0) })),
  s("sqrt", fmta("\\sqrt{<>}<>", { i(1, "x"), i(0) })),
  s("sum", fmta("\\sum_{<>}^{<>} <>", { i(1, "i=1"), i(2, "n"), i(0) })),
  s("prod", fmta("\\prod_{<>}^{<>} <>", { i(1, "i=1"), i(2, "n"), i(0) })),
  s("lim", fmta("\\lim_{<> \\to <>} <>", { i(1, "n"), i(2, "\\infty"), i(0) })),
  s("int", fmta("\\int_{<>}^{<>} <> \\, d<>", { i(1, "a"), i(2, "b"), i(0), i(3, "x") })),
  s("part", fmta("\\frac{\\partial <>}{\\partial <>}<>", { i(1, "f"), i(2, "x"), i(0) })),
  s("align", {
    t({ "\\begin{aligned}", "" }),
    i(1, "y"),
    t(" &= "),
    i(0),
    t({ "", "\\end{aligned}" }),
  }),
  s("cases", {
    t({ "\\begin{cases}", "  " }),
    i(1, "value"),
    t(" & "),
    i(2, "condition"),
    t({ "", "\\end{cases}" }),
    i(0),
  }),
  s("mat", {
    t({ "\\begin{bmatrix}", "" }),
    i(1, "a & b \\\\"),
    t({ "", "\\end{bmatrix}" }),
  }),
  s("pmat", {
    t({ "\\begin{pmatrix}", "" }),
    i(1, "a & b \\\\"),
    t({ "", "\\end{pmatrix}" }),
  }),
  s("bb", fmta("\\mathbb{<>}<>", { i(1, "R"), i(0) })),
  s("cal", fmta("\\mathcal{<>}<>", { i(1, "F"), i(0) })),
  s("bf", fmta("\\mathbf{<>}<>", { i(1, "x"), i(0) })),
  s("hat", fmta("\\hat{<>}<>", { i(1, "theta"), i(0) })),
  s("bar", fmta("\\bar{<>}<>", { i(1, "x"), i(0) })),
  s("vec", fmta("\\vec{<>}<>", { i(1, "v"), i(0) })),
  s("dot", fmta("\\dot{<>}<>", { i(1, "x"), i(0) })),
  s("ddot", fmta("\\ddot{<>}<>", { i(1, "x"), i(0) })),
  s("norm", fmta("\\left\\lVert <> \\right\\rVert<>", { visual_node("x"), i(0) })),
  s("abs", fmta("\\left| <> \\right|<>", { visual_node("x"), i(0) })),
  s("paren", fmta("\\left( <> \\right)<>", { visual_node("x"), i(0) })),
  s("brack", fmta("\\left[ <> \\right]<>", { visual_node("x"), i(0) })),
  s("set", fmta("\\left\\{ <> \\right\\}<>", { visual_node("x"), i(0) })),
  s("sub", fmta("_{<>}<>", { i(1, "i"), i(0) })),
  s("sup", fmta("^{<>}<>", { i(1, "n"), i(0) })),
}

local math_auto_snippets = {
  math_autosnippet("ff", "\\frac{<>}{<>}<>", { i(1), i(2), i(0) }),
  math_autosnippet("sq", "\\sqrt{<>}<>", { i(1), i(0) }),
  math_autosnippet(";a", "\\alpha"),
  math_autosnippet(";b", "\\beta"),
  math_autosnippet(";g", "\\gamma"),
  math_autosnippet(";G", "\\Gamma"),
  math_autosnippet(";d", "\\delta"),
  math_autosnippet(";D", "\\Delta"),
  math_autosnippet(";e", "\\epsilon"),
  math_autosnippet(";z", "\\zeta"),
  math_autosnippet(";t", "\\theta"),
  math_autosnippet(";T", "\\Theta"),
  math_autosnippet(";l", "\\lambda"),
  math_autosnippet(";L", "\\Lambda"),
  math_autosnippet(";m", "\\mu"),
  math_autosnippet(";p", "\\pi"),
  math_autosnippet(";P", "\\Pi"),
  math_autosnippet(";s", "\\sigma"),
  math_autosnippet(";S", "\\Sigma"),
  math_autosnippet(";o", "\\omega"),
  math_autosnippet(";O", "\\Omega"),
  math_autosnippet(";in", "\\in"),
  math_autosnippet(";inf", "\\infty"),
  math_autosnippet(";to", "\\to"),
  math_autosnippet(";le", "\\le"),
  math_autosnippet(";ge", "\\ge"),
  math_autosnippet(";neq", "\\neq"),
  math_autosnippet(";approx", "\\approx"),
  math_autosnippet(";cdot", "\\cdot"),
}

local latex_text_snippets = {
  s("tt", fmta("\\texttt{<>}<>", { visual_node("text"), i(0) })),
  s("tii", fmta("\\textit{<>}<>", { visual_node("text"), i(0) })),
  s("tbf", fmta("\\textbf{<>}<>", { visual_node("text"), i(0) })),
  s("em", fmta("\\emph{<>}<>", { visual_node("text"), i(0) })),
  s("hr", fmta("\\href{<>}{<>}<>", { i(1, "url"), i(2, "display text"), i(0) })),
  s("env", fmta([[
\\begin{<>}
  <>
\\end{<>}
<>]], { i(1, "environment"), i(2), rep(1), i(0) })),
  s("beg", fmta([[
\\begin{<>}
  <>
\\end{<>}
<>]], { i(1, "environment"), i(2), rep(1), i(0) })),
  s("figenv", fmta([[
\\begin{figure}[<>]
  \\centering
  \\includegraphics[width=<>\\linewidth]{<>}
  \\caption{<>}
  \\label{fig:<>}
\\end{figure}
<>]], { i(1, "htbp"), i(2, "0.8"), i(3, "figures/name"), i(4, "Caption"), i(5, "label"), i(0) })),
  s("tabenv", fmta([[
\\begin{table}[<>]
  \\centering
  \\caption{<>}
  \\label{tab:<>}
  \\begin{tabular}{<>}
    <>
  \\end{tabular}
\\end{table}
<>]], { i(1, "htbp"), i(2, "Caption"), i(3, "label"), i(4, "ll"), i(5), i(0) })),
  s("sec", fmta("\\section{<>}<>", { i(1, "Title"), i(0) })),
  s("ssec", fmta("\\subsection{<>}<>", { i(1, "Title"), i(0) })),
  s("sssec", fmta("\\subsubsection{<>}<>", { i(1, "Title"), i(0) })),
  s("enum", fmta([[
\\begin{enumerate}
  \\item <>
\\end{enumerate}
<>]], { i(1), i(0) })),
  s("item", fmta([[
\\begin{itemize}
  \\item <>
\\end{itemize}
<>]], { i(1), i(0) })),
}

local quarto_snippets = {
  s("rchunk", {
    t({ "```{r}", "#| label: " }),
    i(1, "chunk-name"),
    t({ "", "" }),
    i(0),
    t({ "", "```" }),
  }),
  s("juliachunk", {
    t({ "```{julia}", "#| label: " }),
    i(1, "chunk-name"),
    t({ "", "" }),
    i(0),
    t({ "", "```" }),
  }),
  s("sqlchunk", {
    t({ "```{sql}", "#| label: " }),
    i(1, "chunk-name"),
    t({ "", "" }),
    i(0),
    t({ "", "```" }),
  }),
  s("pychunk", {
    t({ "```{python}", "#| label: " }),
    i(1, "chunk-name"),
    t({ "", "" }),
    i(0),
    t({ "", "```" }),
  }),
  s("callout", {
    t("::: {.callout-"),
    c(1, { t("note"), t("tip"), t("warning"), t("important"), t("caution") }),
    t({ "}", "" }),
    i(0),
    t({ "", ":::" }),
  }),
  s("fig", {
    t("!["),
    i(1, "Caption"),
    t("]("),
    i(2, "figures/name.png"),
    t("){#fig-"),
    i(3, "name"),
    t("}"),
  }),
  s("cite", {
    t("[@"),
    i(1, "key"),
    t("]"),
  }),
}

local function extend(base, extra)
  return vim.list_extend(vim.deepcopy(base), vim.deepcopy(extra))
end

local markdown_snippets = extend(math_snippets, latex_text_snippets)
local quarto_all = extend(extend(math_snippets, latex_text_snippets), quarto_snippets)
local tex_snippets = extend(math_snippets, latex_text_snippets)

ls.add_snippets("quarto", quarto_all)
ls.add_snippets("quarto", vim.deepcopy(math_auto_snippets), { type = "autosnippets" })
ls.add_snippets("markdown", markdown_snippets)
ls.add_snippets("markdown", vim.deepcopy(math_auto_snippets), { type = "autosnippets" })
ls.add_snippets("tex", tex_snippets)
ls.add_snippets("tex", vim.deepcopy(math_auto_snippets), { type = "autosnippets" })
ls.add_snippets("latex", vim.deepcopy(tex_snippets))
ls.add_snippets("latex", vim.deepcopy(math_auto_snippets), { type = "autosnippets" })

ls.add_snippets("r", {
  s("lib", {
    t("library("),
    i(1, "package"),
    t(")"),
  }),
  s("rheader", fmta([[
# Purpose: <>
# Inputs: <>
# Outputs: <>
# Assumptions: <>

]], { i(1, "analysis goal"), i(2, "input artifacts or tables"), i(3, "output artifacts"), i(4, "key analysis assumptions") })),
  s("tidy", {
    t({ "library(tidyverse)", "library(here)", "" }),
    i(0),
  }),
  s("diagtable", fmt([=[
diagnostics <- [] |>
  summarise(
    rows = n(),
    across(everything(), ~ sum(is.na(.x)), .names = "missing_{.col}")
  )

readr::write_csv(diagnostics, [])
[]]=], { i(1, "analysis_data"), i(2, "\".artifacts/r/diagnostics.csv\""), i(0) }, { delimiters = "[]" })),
  s("plotsave", fmt([=[
p <- ggplot([], aes(x = [], y = [])) +
  geom_point(alpha = 0.6) +
  theme_minimal()

ggsave(
  filename = [],
  plot = p,
  width = [],
  height = [],
  dpi = []
)
[]]=], { i(1, "analysis_data"), i(2, "x"), i(3, "y"), i(4, "\".artifacts/r/plot.png\""), i(5, "7"), i(6, "5"), i(7, "300"), i(0) }, { delimiters = "[]" })),
  s("diagnostics", fmta([[
# Diagnostics
# - Missingness:
# - Model fit:
# - Sensitivity:
# - Warnings:

<>]], { i(0) })),
})

ls.add_snippets("sql", {
  s("readparquet", fmta("read_parquet(<>)<>", { i(1, "'data/*.parquet'"), i(0) })),
  s("readcsv", fmta("read_csv_auto(<>)<>", { i(1, "'data/file.csv'"), i(0) })),
  s("copyparquet", fmta([[
COPY (
  <>
) TO <> (FORMAT parquet);
<>]], { i(1, "SELECT * FROM table_name"), i(2, "'dist/data/output.parquet'"), i(0) })),
  s("ortable", fmta([[
CREATE OR REPLACE TABLE <> AS
<>
;
<>]], { i(1, "schema.table_name"), i(2, "SELECT * FROM source_table"), i(0) })),
  s("describe", fmta("DESCRIBE <>;<>", { i(1, "table_name"), i(0) })),
  s("summarize", fmta("SUMMARIZE <>;<>", { i(1, "table_name"), i(0) })),
  s("limitreview", fmta([[
SELECT *
FROM <>
LIMIT <>;
<>]], { i(1, "table_name"), i(2, "20"), i(0) })),
})

ls.add_snippets("stan", {
  s("stanblocks", fmta([[
data {
  <>
}

parameters {
  <>
}

transformed parameters {
  <>
}

model {
  <>
}

generated quantities {
  <>
}
]], { i(1, "int<lower=1> N;"), i(2, "real alpha;"), i(3, "// derived parameters"), i(4, "alpha ~ normal(0, 1);"), i(5, "// posterior predictive quantities") })),
  s("prior", fmta([[
// Prior: <> on the domain scale.
<> ~ <>(<>, <>);
<>]], { i(1, "state rationale"), i(2, "theta"), i(3, "normal"), i(4, "0"), i(5, "1"), i(0) })),
  s("ppc", fmta([[
array[N] real y_rep;
for (n in 1:N) {
  y_rep[n] = <>;
}
<>]], { i(1, "normal_rng(mu[n], sigma)"), i(0) })),
  s("loglik", fmta([[
vector[N] log_lik;
for (n in 1:N) {
  log_lik[n] = <>;
}
<>]], { i(1, "normal_lpdf(y[n] | mu[n], sigma)"), i(0) })),
})

ls.add_snippets("cpp", {
  s("rcppexport", {
    t({ "#include <Rcpp.h>", "", "// [[Rcpp::export]]" }),
    i(1, "double"),
    t(" "),
    i(2, "kernel_name"),
    t("("),
    i(3, "double x"),
    t({ ") {", "  " }),
    i(0, "return x;"),
    t({ "", "}" }),
  }),
  s("eigenkernel", {
    t({
      "#include <RcppEigen.h>",
      "",
      "// [[Rcpp::depends(RcppEigen)]]",
      "// [[Rcpp::export]]",
      "Eigen::VectorXd ",
    }),
    i(1, "linear_predictor"),
    t({
      "(const Eigen::MatrixXd& X, const Eigen::VectorXd& beta) {",
      "  if (X.cols() != beta.size()) {",
      "    Rcpp::stop(\"X columns must match beta length\");",
      "  }",
      "",
      "  return ",
    }),
    i(2, "X * beta"),
    t({ ";", "}" }),
  }),
  s("numguard", fmta([[
if (!std::isfinite(<>)) {
  Rcpp::stop("<> must be finite");
}
<>]], { i(1, "value"), rep(1), i(0) })),
  s("cpptest", fmta([[
void test_<>() {
  <>
}
]], { i(1, "kernel_name"), i(0, "// deterministic checks") })),
})

ls.add_snippets("html", {
  s("html5", {
    t({ "<!doctype html>", "<html lang=\"" }),
    i(1, "en"),
    t({ "\">", "<head>", "  <meta charset=\"utf-8\">", "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">", "  <title>" }),
    i(2, "Document"),
    t({ "</title>", "</head>", "<body>", "  " }),
    i(0),
    t({ "", "</body>", "</html>" }),
  }),
  s("script", {
    t("<script src=\""),
    i(1, "app.js"),
    t("\"></script>"),
  }),
  s("style", {
    t("<link rel=\"stylesheet\" href=\""),
    i(1, "style.css"),
    t("\">"),
  }),
  s("div", {
    t("<div class=\""),
    i(1, "class-name"),
    t({ "\">", "  " }),
    i(0),
    t({ "", "</div>" }),
  }),
  s("section", {
    t("<section class=\""),
    i(1, "section-name"),
    t({ "\">", "  <h2>" }),
    i(2, "Heading"),
    t({ "</h2>", "  " }),
    i(0),
    t({ "", "</section>" }),
  }),
  s("fig", {
    t({ "<figure>", "  <img src=\"" }),
    i(1, "image.png"),
    t("\" alt=\""),
    i(2, ""),
    t({ "\">", "  <figcaption>" }),
    i(3, "Caption"),
    t({ "</figcaption>", "</figure>" }),
  }),
  s("picohtml", fmt([=[
<!doctype html>
<html lang="[]">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>[]</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
  <script src="https://unpkg.com/alpinejs" defer></script>
</head>
<body>
  <main class="container">
    <header>
      <h1>[]</h1>
      <p>[]</p>
    </header>

    []
  </main>
</body>
</html>
]=], { i(1, "en"), i(2, "Report"), i(3, "Report"), i(4, "Analysis summary"), i(0) }, { delimiters = "[]" })),
  s("plothtml", {
    t({ "<!doctype html>", "<html lang=\"" }),
    i(1, "en"),
    t({
      "\">",
      "<head>",
      "  <meta charset=\"utf-8\">",
      "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
      "  <title>",
    }),
    i(2, "Observable Plot Report"),
    t({
      "</title>",
      "  <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css\">",
      "  <script type=\"module\">",
      "    import * as Plot from \"https://cdn.jsdelivr.net/npm/@observablehq/plot@0.6/+esm\";",
      "",
      "    const data = [];",
      "",
      "    const plot = Plot.plot({",
      "      marks: [",
      "        Plot.dot(data, { x: \"",
    }),
    i(3, "x"),
    t("\", y: \""),
    i(4, "y"),
    t({
      "\" })",
      "      ]",
      "    });",
      "",
      "    document.addEventListener(\"DOMContentLoaded\", () => {",
      "      document.querySelector(\"#",
    }),
    i(5, "plot"),
    t({
      "\").append(plot);",
      "    });",
      "  </script>",
      "</head>",
      "<body>",
      "  <main class=\"container\">",
      "    <h1>",
    }),
    i(6, "Report"),
    t({
      "</h1>",
      "    <figure>",
      "      <div id=\"",
    }),
    rep(5),
    t({
      "\"></div>",
      "      <figcaption>",
    }),
    i(7, "Figure caption"),
    t({
      "</figcaption>",
      "    </figure>",
      "  </main>",
      "</body>",
      "</html>",
    }),
  }),
  s("reportsection", fmt([=[
<section aria-labelledby="[]-heading">
  <header>
    <h2 id="[]-heading">[]</h2>
    <p>[]</p>
  </header>

  <figure>
    <div id="[]"></div>
    <figcaption>[]</figcaption>
  </figure>
</section>
]=], { i(1, "section"), rep(1), i(2, "Section heading"), i(3, "Short interpretation note"), i(4, "figure-id"), i(5, "Figure caption") }, { delimiters = "[]" })),
  s("artifacttable", fmt([=[
<table>
  <caption>[]</caption>
  <thead>
    <tr>
      <th scope="col">[]</th>
      <th scope="col">[]</th>
      <th scope="col">[]</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">[]</th>
      <td>[]</td>
      <td>[]</td>
    </tr>
  </tbody>
</table>
]=], { i(1, "Table caption"), i(2, "Term"), i(3, "Estimate"), i(4, "Interval"), i(5, "parameter"), i(6, "0.00"), i(7, "0.00, 0.00") }, { delimiters = "[]" })),
  s("notefigure", fmt([=[
<figure>
  <img src="[]" alt="[]">
  <figcaption>
    <strong>[]</strong>
    <span>[]</span>
  </figcaption>
</figure>
]=], { i(1, "figures/result.png"), i(2, "Accessible description"), i(3, "Figure title."), i(4, "Caption and notes.") }, { delimiters = "[]" })),
  s("alpinetoggle", fmt([=[
<section x-data="{ open: false }">
  <button type="button" @click="open = !open" :aria-expanded="open.toString()">
    []
  </button>
  <div x-show="open">
    []
  </div>
</section>
]=], { i(1, "Toggle details"), i(0, "<p>Details</p>") }, { delimiters = "[]" })),
  s("alpinetabs", fmt([=[
<section x-data="{ tab: '[]' }">
  <nav role="tablist">
    <button type="button" role="tab" @click="tab = '[]'" :aria-selected="(tab === '[]').toString()">[]</button>
    <button type="button" role="tab" @click="tab = '[]'" :aria-selected="(tab === '[]').toString()">[]</button>
  </nav>

  <section x-show="tab === '[]'" role="tabpanel">
    []
  </section>
  <section x-show="tab === '[]'" role="tabpanel">
    []
  </section>
</section>
]=], { i(1, "summary"), rep(1), rep(1), i(2, "Summary"), i(3, "diagnostics"), rep(3), i(4, "Diagnostics"), rep(1), i(5, "<p>Summary content</p>"), rep(3), i(6, "<p>Diagnostic content</p>") }, { delimiters = "[]" })),
  s("alpinefilter", fmt([=[
<section x-data="{ query: '' }">
  <label>
    []
    <input type="search" x-model="query" placeholder="[]">
  </label>

  <template x-for="item in [].filter((item) => item.[].toLowerCase().includes(query.toLowerCase()))" :key="item.[]">
    <article>
      []
    </article>
  </template>
</section>
]=], { i(1, "Filter"), i(2, "Search"), i(3, "items"), i(4, "label"), i(5, "id"), i(0, "<h3 x-text=\"item.label\"></h3>") }, { delimiters = "[]" })),
  s("alpinenote", fmt([=[
<aside x-data="{ expanded: false }">
  <button type="button" class="outline" @click="expanded = !expanded">
    []
  </button>
  <p x-show="expanded">[]</p>
</aside>
]=], { i(1, "Assumption note"), i(0, "State the note without changing the analysis interpretation.") }, { delimiters = "[]" })),
  s("revealdeck", fmt([=[
<!doctype html>
<html lang="[]">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>[]</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/reveal.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/theme/white.css">
</head>
<body>
  <div class="reveal">
    <div class="slides">
      <section>
        <h1>[]</h1>
        <p>[]</p>
      </section>

      []
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/reveal.js"></script>
  <script>
    Reveal.initialize({ hash: true, slideNumber: true });
  </script>
</body>
</html>
]=], { i(1, "en"), i(2, "Slides"), i(3, "Slide title"), i(4, "Subtitle"), i(0) }, { delimiters = "[]" })),
  s("revealslide", fmt([=[
<section>
  <h2>[]</h2>
  []
</section>
]=], { i(1, "Slide heading"), i(0, "<p>Slide content</p>") }, { delimiters = "[]" })),
  s("revealnotes", fmt([=[
<aside class="notes">
  []
</aside>
]=], { i(0, "Speaker note") }, { delimiters = "[]" })),
  s("revealtwofig", fmt([=[
<section>
  <h2>[]</h2>
  <div class="r-stack">
    <figure>
      <img src="[]" alt="[]">
      <figcaption>[]</figcaption>
    </figure>
    <figure class="fragment">
      <img src="[]" alt="[]">
      <figcaption>[]</figcaption>
    </figure>
  </div>
</section>
]=], { i(1, "Figure comparison"), i(2, "figures/first.png"), i(3, "First figure description"), i(4, "First caption"), i(5, "figures/second.png"), i(6, "Second figure description"), i(7, "Second caption") }, { delimiters = "[]" })),
})

ls.add_snippets("javascript", {
  s("d3sel", {
    t("const "),
    i(1, "selection"),
    t(" = d3.select(\""),
    i(2, "#chart"),
    t("\");"),
  }),
  s("chartjs", {
    t({ "const chart = new Chart(" }),
    i(1, "ctx"),
    t({ ", {", "  type: \"" }),
    i(2, "bar"),
    t({ "\",", "  data: " }),
    i(3, "data"),
    t({ ",", "  options: {", "    responsive: true,", "  },", "});" }),
  }),
  s("d3bespoke", fmt([=[// D3 is reserved here for bespoke visualisation that needs custom marks or layout.
const <> = d3.select("<>");
<>]=], { i(1, "root"), i(2, "#vis"), i(0) }, { delimiters = "<>" })),
  s("plotscatter", fmt([=[
const plot = Plot.plot({
  marks: [
    Plot.dot(<>, { x: "<>", y: "<>", fill: "<>" }),
    Plot.ruleY([0])
  ]
});

document.querySelector("<>").append(plot);
]=], { i(1, "data"), i(2, "x"), i(3, "y"), i(4, "group"), i(5, "#plot") }, { delimiters = "<>" })),
  s("plotfacet", fmt([=[
const plot = Plot.plot({
  facet: {
    data: <>,
    x: "<>"
  },
  marks: [
    Plot.dot(<>, { x: "<>", y: "<>" })
  ]
});

document.querySelector("<>").append(plot);
]=], { i(1, "data"), i(2, "group"), rep(1), i(3, "x"), i(4, "y"), i(5, "#plot") }, { delimiters = "<>" })),
  s("plothist", fmt([=[
const plot = Plot.plot({
  marks: [
    Plot.rectY(
      <>,
      Plot.binX({ y: "count" }, { x: "<>", fill: "<>" })
    ),
    Plot.ruleY([0])
  ]
});

document.querySelector("<>").append(plot);
]=], { i(1, "data"), i(2, "value"), i(3, "group"), i(4, "#plot") }, { delimiters = "<>" })),
  s("plotline", fmt([=[
const plot = Plot.plot({
  marks: [
    Plot.areaY(<>, { x: "<>", y1: "<>", y2: "<>", fillOpacity: 0.2 }),
    Plot.lineY(<>, { x: "<>", y: "<>" })
  ]
});

document.querySelector("<>").append(plot);
]=], { i(1, "data"), i(2, "x"), i(3, "lower"), i(4, "upper"), rep(1), rep(2), i(5, "estimate"), i(6, "#plot") }, { delimiters = "<>" })),
  s("plotbar", fmt([=[
const plot = Plot.plot({
  marks: [
    Plot.barY(<>, { x: "<>", y: "<>", fill: "<>" }),
    Plot.ruleY([0])
  ]
});

document.querySelector("<>").append(plot);
]=], { i(1, "data"), i(2, "category"), i(3, "value"), i(4, "group"), i(5, "#plot") }, { delimiters = "<>" })),
  s("chartline", fmt([=[
const chart = new Chart(<>, {
  type: "line",
  data: <>,
  options: {
    responsive: true,
    interaction: { mode: "index", intersect: false },
    scales: {
      y: { beginAtZero: false }
    }
  }
});
]=], { i(1, "ctx"), i(2, "data") }, { delimiters = "<>" })),
  s("chartbar", fmt([=[
const chart = new Chart(<>, {
  type: "bar",
  data: <>,
  options: {
    responsive: true,
    scales: {
      y: { beginAtZero: true }
    }
  }
});
]=], { i(1, "ctx"), i(2, "data") }, { delimiters = "<>" })),
  s("chartstatus", fmt([=[
const chart = new Chart(<>, {
  type: "doughnut",
  data: <>,
  options: {
    responsive: true,
    plugins: {
      legend: { position: "bottom" }
    }
  }
});
]=], { i(1, "ctx"), i(2, "data") }, { delimiters = "<>" })),
})
