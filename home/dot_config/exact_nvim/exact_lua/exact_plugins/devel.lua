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
    "dlyongemallo/diffview-plus.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewToggle",
      "DiffviewFileHistory",
      "DiffviewDiffFiles",
      "DiffviewLog",
    },
    opts = {},
  },
  {
    "lewis6991/gitsigns.nvim",
    ---@module "gitsigns"
    ---@type Gitsigns.Config
    opts = {}, ---@diagnostic disable-line: missing-fields
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "dlyongemallo/diffview-plus.nvim",
      "folke/snacks.nvim",
    },
    ---@module "neogit"
    ---@type NeogitConfig
    opts = {
      integrations = {
        diffview = true,
        snacks = true,
      },
      diff_viewer = "diffview",
    },
    cmd = "Neogit",
    keys = {
      {
        "<leader>gc",
        "<cmd>Neogit commit<cr>",
        desc = "Git Commit",
      },
      {
        "<leader>ga",
        function()
          vim.cmd.update()
          local result = vim.system({ "git", "add", "--", vim.api.nvim_buf_get_name(0) }, { text = true }):wait()
          if result.code == 0 then
            vim.notify("Staged current file")
          else
            vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
          end
        end,
        desc = "Git Stage Current File",
      },
      {
        "<leader>gu",
        function()
          local result = vim.system({ "git", "reset", "--", vim.api.nvim_buf_get_name(0) }, { text = true }):wait()
          if result.code == 0 then
            vim.notify("Unstaged current file")
          else
            vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
          end
        end,
        desc = "Git Unstage Current File",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          vim.b[bufnr].conform_format_tick_before = nil
          return
        end
        vim.b[bufnr].conform_format_tick_before = vim.api.nvim_buf_get_changedtick(bufnr)
        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      local undo_format_group = vim.api.nvim_create_augroup("conform_disable_after_undo", { clear = true })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = undo_format_group,
        callback = function(args)
          local tick_before = vim.b[args.buf].conform_format_tick_before
          local tick_after = vim.api.nvim_buf_get_changedtick(args.buf)
          vim.b[args.buf].conform_format_tick_before = nil

          if tick_before and tick_after ~= tick_before then
            vim.b[args.buf].conform_format_undo_seq = vim.fn.undotree().seq_cur
            vim.b[args.buf].conform_format_tick_after = tick_after
          else
            vim.b[args.buf].conform_format_undo_seq = nil
            vim.b[args.buf].conform_format_tick_after = nil
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = undo_format_group,
        callback = function(args)
          local format_seq = vim.b[args.buf].conform_format_undo_seq
          if not format_seq then
            return
          end

          local changedtick = vim.api.nvim_buf_get_changedtick(args.buf)
          if changedtick == vim.b[args.buf].conform_format_tick_after then
            return
          end

          if vim.fn.undotree().seq_cur < format_seq then
            vim.b[args.buf].disable_autoformat = true
            vim.schedule(function()
              vim.notify("Autoformat disabled for this buffer after undo", vim.log.levels.INFO)
            end)
          end

          vim.b[args.buf].conform_format_undo_seq = nil
          vim.b[args.buf].conform_format_tick_after = nil
        end,
      })

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          -- FormatDisable! disables formatting globally.
          vim.g.disable_autoformat = true
        else
          vim.b.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })
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
        "<C-Space>",
        function()
          local line = vim.api.nvim_win_get_cursor(0)[1]
          require("pi-nvim.ui").open({
            selection = {
              text = vim.api.nvim_get_current_line(),
              file = vim.fn.expand("%:."),
              start_line = line,
              end_line = line,
              ft = vim.bo.filetype,
            },
          })
        end,
        mode = "n",
        desc = "Pi: send line",
      },
      {
        "<C-Space>",
        ":Pi<CR>",
        mode = "v",
        desc = "Pi: send selection",
      },
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
    ---@module "pi-nvim"
    ---@type pi_nvim.Config
    opts = {
      set_default_keymaps = false,
    },
  },
  {
    "folke/trouble.nvim",
    specs = {
      {
        "folke/snacks.nvim",
        opts = function(_, opts)
          return vim.tbl_deep_extend("force", opts or {}, {
            picker = {
              actions = require("trouble.sources.snacks").actions,
              win = {
                input = {
                  keys = {
                    ["<C-t>"] = { "trouble_open", mode = { "n", "i" } },
                  },
                },
              },
            },
          })
        end,
      },
    },
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
    ---@module "octo"
    ---@type OctoConfig
    opts = { ---@diagnostic disable-line: missing-fields
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
