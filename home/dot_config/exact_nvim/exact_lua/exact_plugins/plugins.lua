---@type LazySpec

return {
  {
    "nvim-mini/mini.files",
    opts = {},
  },
  {
    "nvim-mini/mini.completion",
    opts = {},
  },
  {
    "nvim-mini/mini.pick",
    dependencies = { "nvim-mini/mini.keymap" },
    config = function()
      local MiniPick = require("mini.pick")
      MiniPick.setup()

      vim.keymap.set("n", "<leader>e", function()
        MiniPick.builtin.files({
          tool = "git", -- Uses git ls-files (tracked files only)
        })
      end, { desc = "Pick git tracked files" })

      vim.keymap.set("n", "<leader>f", function()
        MiniPick.builtin.files() -- Defaults to 'rg' which respects .gitignore and global ignore
      end, { desc = "Pick all files in cwd" })

      local MiniKeymap = require("mini.keymap")
      MiniKeymap.map_multistep("i", "<Tab>", { "pmenu_next" })
      MiniKeymap.map_multistep("i", "<S-Tab>", { "pmenu_prev" })
      MiniKeymap.map_multistep("i", "<C-l>", { "pmenu_accept", "minipairs_cr" })
      MiniKeymap.map_multistep("i", "<BS>", { "minipairs_bs" })

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
      local SmartSplits = require("smart-splits")
      SmartSplits.setup(opts)

      vim.keymap.set("n", "<A-h>", SmartSplits.resize_left)
      vim.keymap.set("n", "<A-j>", SmartSplits.resize_down)
      vim.keymap.set("n", "<A-k>", SmartSplits.resize_up)
      vim.keymap.set("n", "<A-l>", SmartSplits.resize_right)
      -- moving between splits
      vim.keymap.set("n", "<C-h>", SmartSplits.move_cursor_left)
      vim.keymap.set("n", "<C-j>", SmartSplits.move_cursor_down)
      vim.keymap.set("n", "<C-k>", SmartSplits.move_cursor_up)
      vim.keymap.set("n", "<C-l>", SmartSplits.move_cursor_right)
      vim.keymap.set("n", "<C-\\>", SmartSplits.move_cursor_previous)
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
