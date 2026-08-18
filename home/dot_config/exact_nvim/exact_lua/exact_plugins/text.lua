local M = {}
local toggles = require("config.toggles")

M.spec = {
  {
    "nvim-mini/mini.ai",
    dependencies = {
      "nvim-mini/mini.extra",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = function(_, opts)
      local MiniAi = require("mini.ai")

      opts.n_lines = 4000
      opts.custom_textobjects = opts.custom_textobjects or {}
      opts.custom_textobjects.F = MiniAi.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })
      opts.custom_textobjects.c = MiniAi.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })
      opts.custom_textobjects.o = MiniAi.gen_spec.treesitter({
        a = { "@conditional.outer", "@loop.outer" },
        i = { "@conditional.inner", "@loop.inner" },
      })
      opts.custom_textobjects.e = MiniExtra.gen_ai_spec.buffer()
    end,
  },
  {
    "nvim-mini/mini.indentscope",
    init = function()
      vim.g.miniindentscope_disable = true
    end,
    opts = {},
    config = function(_, opts)
      local MiniIndentscope = require("mini.indentscope")
      MiniIndentscope.setup(opts)

      local function refresh_indentscope()
        if vim.g.miniindentscope_disable == true or vim.b.miniindentscope_disable == true then
          MiniIndentscope.undraw()
        else
          MiniIndentscope.draw()
        end
      end

      toggles.map_toggle("i", {
        desc = "indent scope indicator",
        global = function()
          vim.g.miniindentscope_disable = not vim.g.miniindentscope_disable
          refresh_indentscope()
        end,
        local_scope = "buffer",
        local_toggle = function()
          vim.b.miniindentscope_disable = not vim.b.miniindentscope_disable
          refresh_indentscope()
        end,
      })
    end,
  },
  {
    "nvim-mini/mini.comment",
    opts = {},
    config = function(_, opts)
      require("mini.comment").setup(opts)
      vim.keymap.set("n", [[\\]], "gcc", { desc = "Toggle comment on current line", remap = true })
      vim.keymap.set("x", [[\\]], "gc", { desc = "Toggle comment on selection", remap = true })
    end,
  },
  {
    "nvim-mini/mini.move",
    opts = {
      mappings = {
        left = "<",
        right = ">",
        down = "+",
        up = "_",
        line_left = "<<",
        line_right = ">>",
        line_down = "+",
        line_up = "_",
      },
    },
    config = function(_, opts)
      local MiniMove = require("mini.move")
      MiniMove.setup(opts)

      local function map_repeatable_line_move(lhs, direction, desc)
        local plug = "<Plug>(MiniMoveLine" .. direction:gsub("^%l", string.upper) .. ")"
        vim.keymap.set("n", plug, function()
          MiniMove.move_line(direction)
          vim.fn["repeat#set"](plug, vim.v.count)
        end, { desc = desc, silent = true })
        vim.keymap.set("n", lhs, plug, { desc = desc, remap = true })
      end

      map_repeatable_line_move("+", "down", "Move line down")
      map_repeatable_line_move("_", "up", "Move line up")
    end,
  },
  {
    "Wansmer/treesj",
    keys = {
      {
        "gS",
        function()
          require("treesj").toggle()
        end,
        desc = "Toggle split/join",
      },
    },
    opts = {
      use_default_keymaps = false,
    },
  },
  {
    "nvim-mini/mini.extra",
    opts = {},
  },
  {
    "nvim-mini/mini.pairs",
    opts = {},
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      modes = {
        char = {
          enabled = false,
        },
      },
    },
    config = function(_, opts)
      Flash = require("flash")
      Flash.setup(opts)
    end,
    keys = {
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          Flash.jump()
        end,
        desc = "Flash",
      },
      {
        "R",
        mode = { "n", "x", "o" },
        function()
          Flash.treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          Flash.remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          Flash.treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          Flash.toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },
  {
    "nvim-mini/mini.surround",
    opts = {},
  },
  {
    "gbprod/cutlass.nvim",
    opts = {
      cut_key = "m",
    },
  },
  {
    "gbprod/substitute.nvim",
    opts = {},
    config = function(_, opts)
      Substitute = require("substitute")
      Substitute.setup(opts)
    end,
    keys = {
      {
        ":",
        function()
          Substitute.operator()
        end,
      },
      {
        "::",
        function()
          Substitute.line()
        end,
      },
    },
  },
}

return M.spec
