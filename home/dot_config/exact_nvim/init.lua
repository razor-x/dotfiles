local bootstrap = require("bootstrap")

local has_dotfiles, dotfiles = pcall(require, "dotfiles")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

bootstrap("https://github.com/folke/lazy.nvim.git", "11.17.5")

if not has_dotfiles then
  require("lazy").setup({ { import = "plugins" } })
  return
end

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

vim.cmd.colorscheme(dotfiles.colorscheme)
