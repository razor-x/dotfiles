local dotfiles = require("dotfiles")

---@module "lazy.types"
---@type LazySpec
return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.lsp.enable("clangd")

      vim.lsp.enable("clojure_lsp")
      -- TODO cljfmt, kondo ?

      vim.lsp.enable("gopls")
      vim.lsp.enable("golangci_lint_ls")

      vim.lsp.enable("ts_ls")
      vim.lsp.enable("biome")

      vim.lsp.enable("lua_ls")

      vim.lsp.enable("stylua")

      vim.lsp.enable("phpactor")
      -- TODO mago ?

      vim.lsp.enable("pyright")
      vim.lsp.enable("ruff")

      vim.lsp.enable("ruby_lsp")
      vim.lsp.enable("rubocop")

      vim.lsp.enable("bashls")
      vim.lsp.enable("fish_lsp")
    end,
  },
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
}
