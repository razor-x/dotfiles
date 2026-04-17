---@module "lazy.types"
---@type LazySpec
return {
  {
    "nvim-mini/mini.basics",
    priority = 1000,
    opts = {
      options = {
        -- Basic options ('number', 'ignorecase', and many more)
        basic = true,

        -- Extra UI features ('winblend', 'listchars', 'pumheight', ...)
        extra_ui = true,

        -- Presets for window borders ('single', 'double', ...)
        -- Default 'auto' infers from 'winborder' option
        win_borders = "auto",
      },

      -- Mappings. Set field to `false` to disable.
      mappings = {
        -- Basic mappings (better 'jk', save with Ctrl+S, ...)
        basic = false,

        -- Prefix for mappings that toggle common options ('wrap', 'spell', ...).
        -- Supply empty string to not create these mappings.
        option_toggle_prefix = [[\]],

        -- Window navigation with <C-hjkl>, resize with <C-arrow>
        windows = false,

        -- Move cursor in Insert, Command, and Terminal mode with <M-hjkl>
        move_with_alt = false,
      },

      -- Autocommands. Set field to `false` to disable
      autocommands = {
        -- Basic autocommands (highlight on yank, start Insert in terminal, ...)
        basic = true,

        -- Set 'relativenumber' only in linewise and blockwise Visual mode
        relnum_in_visual_mode = true,
      },

      -- Whether to disable showing non-error feedback
      silent = false,
    },
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
    "nvim-mini/mini.clue",
    opts = {
      triggers = {
        -- Leader triggers
        { mode = { "n", "x" }, keys = "<Leader>" },

        -- `[` and `]` keys
        { mode = "n", keys = "[" },
        { mode = "n", keys = "]" },

        -- Built-in completion
        { mode = "i", keys = "<C-x>" },

        -- `g` key
        { mode = { "n", "x" }, keys = "g" },

        -- Marks
        { mode = { "n", "x" }, keys = "'" },
        { mode = { "n", "x" }, keys = "`" },

        -- Registers
        { mode = { "n", "x" }, keys = '"' },
        { mode = { "i", "c" }, keys = "<C-r>" },

        -- Window commands
        { mode = "n", keys = "<C-w>" },

        -- `z` key
        { mode = { "n", "x" }, keys = "z" },
      },
    },
    config = function(_, opts)
      local MiniClue = require("mini.clue")
      opts.clues = {
        -- Enhance this by adding descriptions for <Leader> mapping groups
        MiniClue.gen_clues.square_brackets(),
        MiniClue.gen_clues.builtin_completion(),
        MiniClue.gen_clues.g(),
        MiniClue.gen_clues.marks(),
        MiniClue.gen_clues.registers(),
        MiniClue.gen_clues.windows(),
        MiniClue.gen_clues.z(),
      }
      MiniClue.setup(opts)
    end,
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
    dependencies = { "nvim-mini/mini.keymap" },
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
