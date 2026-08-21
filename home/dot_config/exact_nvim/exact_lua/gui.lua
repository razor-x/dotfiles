local M = {}

function M.setup()
  if vim.g.neovide then
    vim.cmd.colorscheme("catppuccin-nvim")
  end
end
