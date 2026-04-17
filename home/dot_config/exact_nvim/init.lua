local bootstrap = require("bootstrap")
local dotfiles = require("dotfiles")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

bootstrap("https://github.com/folke/lazy.nvim.git", "11.17.5")

require("lazy").setup({
  lockfile = vim.fs.joinpath(dotfiles.config_dir, ".lazy-lock.json"),
  spec = {
    { import = "plugins" },
    {
      "folke/lazydev.nvim",
      ---@module "lazydev"
      ---@type lazydev.Config
      opts = {
        enabled = function(root_dir)
          return vim.fs.normalize(root_dir) == vim.fs.normalize(dotfiles.root_dir)
        end,
      },
      ft = "lua",
    },
  },
})
