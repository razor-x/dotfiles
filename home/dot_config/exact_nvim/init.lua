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
  change_detection = {
    enabled = false,
  },
  spec = {
    { import = "plugins" },
    {
      "folke/lazydev.nvim",
      ---@module "lazydev"
      ---@type lazydev.Config
      opts = {
        library = {
          { path = "conform.nvim", words = { "conform" } },
          { path = "flash", words = { "Flash" } },
          { path = "mini.ai", words = { "MiniAi" } },
          { path = "mini.basics", words = { "MiniBasics" } },
          { path = "mini.bracketed", words = { "MiniBracketed" } },
          { path = "mini.bufremove", words = { "MiniBufremove" } },
          { path = "mini.cmdline", words = { "MiniCmdline" } },
          { path = "mini.completion", words = { "MiniCompletion" } },
          { path = "mini.extra", words = { "MiniExtra" } },
          { path = "mini.icons", words = { "MiniIcons" } },
          { path = "mini.indentscope", words = { "MiniIndentscope" } },
          { path = "mini.keymap", words = { "MiniKeymap" } },
          { path = "mini.move", words = { "MiniMove" } },
          { path = "mini.pairs", words = { "MiniPairs" } },
          { path = "mini.snippets", words = { "MiniSnippets" } },
          { path = "mini.statuscolumn", words = { "MiniStatuscolumn" } },
          { path = "mini.surround", words = { "MiniSurround" } },
          { path = "mini.trailspace", words = { "MiniTrailspace" } },
          { path = "snacks.nvim", words = { "Snacks" } },
          { path = "substitute", words = { "Substitute" } },
          { path = "which-key", words = { "WhichKey" } },
        },
        enabled = function(root_dir)
          return vim.fs.normalize(root_dir) == vim.fs.normalize(dotfiles.root_dir)
        end,
      },
      ft = "lua",
    },
  },
})

vim.cmd.colorscheme(dotfiles.colorscheme)

require("gui")

if vim.g.neovide then
end
