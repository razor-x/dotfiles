local bootstrap = require("nvimrc.bootstrap")
local dotfiles = require("nvimrc.dotfiles")
local editor = require("nvimrc.editor")
local plugins = require("nvimrc.plugins")

local M = {}

M.setup = function()
  bootstrap()

  -- editor.setup()

  vim.cmd("source " .. vim.fn.stdpath("config") .. "/legacy.vim")

  require("lazy").setup({
    lockfile = dotfiles.source_dir .. "/.lazy-lock.json",
    spec = plugins,
  })
end

return M
