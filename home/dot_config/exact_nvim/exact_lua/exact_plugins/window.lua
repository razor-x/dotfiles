local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "mrjones2014/smart-splits.nvim",
    ---@module "smart-splits"
    ---@type SmartSplitsConfig
    opts = { ---@diagnostic disable-line:missing-fields
    },
    config = function(_, opts)
      local SmartSplits = require("smart-splits")
      SmartSplits.setup(opts)

      -- resize splits
      vim.keymap.set("n", "<A-h>", SmartSplits.resize_left)
      vim.keymap.set("n", "<A-j>", SmartSplits.resize_down)
      vim.keymap.set("n", "<A-k>", SmartSplits.resize_up)
      vim.keymap.set("n", "<A-l>", SmartSplits.resize_right)
      -- swapping splits
      vim.keymap.set("n", "<A-H>", SmartSplits.swap_buf_left)
      vim.keymap.set("n", "<A-J>", SmartSplits.swap_buf_down)
      vim.keymap.set("n", "<A-K>", SmartSplits.swap_buf_up)
      vim.keymap.set("n", "<A-L>", SmartSplits.swap_buf_right)
      -- moving between splits
      vim.keymap.set("n", "<C-h>", SmartSplits.move_cursor_left)
      vim.keymap.set("n", "<C-j>", SmartSplits.move_cursor_down)
      vim.keymap.set("n", "<C-k>", SmartSplits.move_cursor_up)
      vim.keymap.set("n", "<C-l>", SmartSplits.move_cursor_right)
    end,
  },
  {
    "nvim-mini/mini.bufremove",
    opts = {},
    keys = {
      {
        "<leader>w",
        function()
          require("mini.bufremove").delete(0, false)
        end,
        desc = "Delete Buffer",
      },
      {
        "<leader>W",
        function()
          require("mini.bufremove").delete(0, true)
        end,
        desc = "Force Delete Buffer",
      },
    },
  },
  {
    "mikesmithgh/kitty-scrollback.nvim",
    ---@module "kitty-scrollback"
    ---@type KsbOpts
    opts = {},
    cmd = {
      "KittyScrollbackGenerateKittens",
      "KittyScrollbackCheckHealth",
      "KittyScrollbackGenerateCommandLineEditing",
    },
    event = { "User KittyScrollbackLaunch" },
  },
}

return M.spec
