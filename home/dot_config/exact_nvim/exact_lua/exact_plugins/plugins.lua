---@module "lazy.types"
---@type LazySpec
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      auto_integrations = true,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "nvim-mini/mini.jump2d",
    opts = {
      mappings = {
        start_jumping = "<CR>",
      },
    },
  },
  {
    "folke/which-key.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "nvim-mini/mini.cmdline",
    opts = {},
  },
  {
    "nvim-mini/mini.files",
    opts = {},
  },
  {
    "nvim-mini/mini.surround",
    opts = {},
  },
  {
    "nvim-mini/mini.completion",
    opts = {},
  },
  {
    "nvim-mini/mini.pick",
    opts = {},
    config = function(_, opts)
      local MiniPick = require("mini.pick")
      MiniPick.setup(opts)

      vim.keymap.set("n", "<leader>e", function()
        MiniPick.builtin.files({
          tool = "git", -- Uses git ls-files (tracked files only)
        })
      end, { desc = "Pick git tracked files" })

      vim.keymap.set("n", "<leader>f", function()
        MiniPick.builtin.files()
      end, { desc = "Pick all files in cwd" })

      -- TODO: Need a buffer picker
      -- vim.keymap.set("i", "<C-e>", function()
      --   MiniPick.builtin.buffer_lines({ scope = "current" })
      -- end)
    end,
  },
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
    "gbprod/cutlass.nvim",
    opts = {
      cut_key = "m",
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
