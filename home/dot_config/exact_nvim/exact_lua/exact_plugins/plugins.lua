---@type LazySpec
return {
  {
    "nvim-mini/mini.nvim",
    config = function()
      local pick = require("mini.pick")
      pick.setup()

      require("mini.completion").setup()

      vim.keymap.set("n", "<leader>e", function()
        pick.builtin.files({
          tool = "git", -- Uses git ls-files (tracked files only)
        })
      end, { desc = "Pick git tracked files" })

      vim.keymap.set("n", "<leader>f", function()
        pick.builtin.files() -- Defaults to 'rg' which respects .gitignore and global ignore
      end, { desc = "Pick all files in cwd" })

      local map_multistep = require("mini.keymap").map_multistep
      map_multistep("i", "<Tab>", { "pmenu_next" })
      map_multistep("i", "<S-Tab>", { "pmenu_prev" })
      map_multistep("i", "<C-l>", { "pmenu_accept", "minipairs_cr" })
      map_multistep("i", "<BS>", { "minipairs_bs" })

      vim.keymap.set("i", "<C-e>", function()
        MiniPick.builtin.buffer_lines({ scope = "current" })
      end)
    end,
  },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    ---@param opts SmartSplitsConfig
    config = function(_, opts)
      local smart_splits = require("smart-splits")
      smart_splits.setup(opts)

      vim.keymap.set("n", "<A-h>", smart_splits.resize_left)
      vim.keymap.set("n", "<A-j>", smart_splits.resize_down)
      vim.keymap.set("n", "<A-k>", smart_splits.resize_up)
      vim.keymap.set("n", "<A-l>", smart_splits.resize_right)
      -- moving between splits
      vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left)
      vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down)
      vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up)
      vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right)
      vim.keymap.set("n", "<C-\\>", smart_splits.move_cursor_previous)
      -- swapping buffers between windows
      vim.keymap.set("n", "<leader><leader>h", smart_splits.swap_buf_left)
      vim.keymap.set("n", "<leader><leader>j", smart_splits.swap_buf_down)
      vim.keymap.set("n", "<leader><leader>k", smart_splits.swap_buf_up)
      vim.keymap.set("n", "<leader><leader>l", smart_splits.swap_buf_right)
    end,
  },
  {
    ---@class CutlassOptions
    ---@field cut_key? string
    "gbprod/cutlass.nvim",
    opts = {
      cut_key = "m",
    } --[[@as CutlassOptions]],
  },
  {
    "folke/trouble.nvim",
    opts = {} --[[@as trouble.Config]],
    cmd = "Trouble",
    keys = {
      {
        "<leader>D",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>d",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = true,
    lazy = true,
    cmd = {
      "KittyScrollbackGenerateKittens",
      "KittyScrollbackCheckHealth",
      "KittyScrollbackGenerateCommandLineEditing",
    },
    event = { "User KittyScrollbackLaunch" },
    opts = {} --[[@as KsbOpts]],
  },
}
