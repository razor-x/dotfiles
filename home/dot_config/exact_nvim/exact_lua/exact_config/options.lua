local M = {}

function M.setup()
  -- Use atomic updates.
  vim.opt.backupcopy = "yes"

  -- Enable persistent undo history.
  vim.opt.undofile = true

  -- Hide buffers instead of closing them.
  vim.opt.hidden = true

  -- Open splits below by default.
  vim.opt.splitbelow = true

  -- Show line numbers.
  vim.opt.number = true

  -- Always show the sign column.
  vim.opt.signcolumn = "yes"

  -- Set nonzero scrolloff.
  vim.opt.scrolloff = 3

  -- Set indentation preferences.
  vim.opt.smartindent = true
  vim.opt.tabstop = 2
  vim.opt.softtabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.expandtab = true
  vim.opt.autoindent = true

  -- Set search preferences.
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  -- Set folding preferences.
  vim.opt.foldmethod = "syntax"
  vim.opt.foldenable = false

  -- Disable bell and visual bell.
  vim.opt.errorbells = false
  vim.opt.visualbell = true
  -- vim.opt.t_vb = ""

  -- Set default autocompletion behavior.
  vim.opt.completeopt:append("noinsert")

  -- Hide some autocompletion messages.
  vim.opt.shortmess:append("c")

  -- Enable omni completion.
  vim.opt.omnifunc = "syntaxcomplete#Complete"

  -- Set default tex flavor.
  vim.g.tex_flavor = "latex"

  -- Set WildMenu preferences.
  vim.opt.wildmode = "longest:full,full"
end

return M
