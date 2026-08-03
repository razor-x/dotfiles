local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
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
    "romus204/tree-sitter-manager.nvim",
    lazy = false,
    ---@module "tree-sitter-manager"
    ---@type table
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "clojure",
        "cpp",
        "css",
        "diff",
        "fish",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gosum",
        "gotmpl",
        "gowork",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "nu",
        "php",
        "printf",
        "python",
        "query",
        "regex",
        "ruby",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
    },
  },
  {
    "carderne/pi-nvim",
    cmd = {
      "Pi",
      "PiPing",
      "PiSend",
      "PiSendBuffer",
      "PiSendFile",
      "PiSendSelection",
      "PiSessions",
    },
    keys = {
      {
        "<leader>dd",
        ":Pi<CR>",
        mode = { "n", "v" },
        desc = "Pi dialog",
      },
      {
        "<leader>df",
        ":PiSendFile<CR>",
        desc = "Pi: send file",
      },
      {
        "<leader>db",
        ":PiSendBuffer<CR>",
        desc = "Pi: send buffer",
      },
      {
        "<leader>dv",
        ":PiSendSelection<CR>",
        mode = "v",
        desc = "Pi: send selection",
      },
      {
        "<leader>ds",
        ":PiSessions<CR>",
        desc = "Pi sessions",
      },
    },
    opts = {
      set_default_keymaps = false,
    },
  },
  {
    "folke/trouble.nvim",
    ---@module "trouble"
    ---@type trouble.Config
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>D",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>dD",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Workspace Diagnostics (Trouble)",
      },
    },
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    opts = {
      picker = "snacks",
      enable_builtin = true,
    },
    keys = {},
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "nvim-mini/mini.icons",
    },
  },
}

return M.spec
