local M = {}

function M.setup()
  -- Hide buffers instead of closing them.
  vim.opt.hidden = true

  -- Set nonzero scrolloff.
  vim.opt.scrolloff = 5

  -- Set indentation preferences.
  vim.opt.tabstop = 2
  vim.opt.softtabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.expandtab = true
  vim.opt.autoindent = true

  -- Set folding preferences.
  vim.opt.foldmethod = "syntax"
  vim.opt.foldenable = false

  -- Enable EditorConfig.
  vim.g.editorconfig = true

  -- Set default tex flavor.
  vim.g.tex_flavor = "latex"

  -- Set WildMenu preferences.
  vim.opt.wildmode = "longest:full,full"
end

return M
