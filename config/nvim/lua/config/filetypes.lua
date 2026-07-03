vim.filetype.add({
  extension = {
    qmd = "quarto",
    stan = "stan",
    ltx = "tex",
    sty = "tex",
    cls = "tex",
  },
  pattern = {
    [".*/%.Rprofile"] = "r",
    [".*/%.Renviron"] = "sh",
  },
})
