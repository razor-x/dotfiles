local M = {}
local toggles = require("config.toggles")

vim.keymap.set("n", [[\\]], "gcc", { desc = "Toggle comment on current line", remap = true })
vim.keymap.set("x", [[\\]], "gc", { desc = "Toggle comment on selection", remap = true })

---@module "lazy.types"
---@type LazySpec
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
      opts.custom_textobjects.C = MiniAi.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })
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
    "nvim-mini/mini.trailspace",
    opts = {},
    config = function(_, opts)
      local MiniTrailspace = require("mini.trailspace")
      MiniTrailspace.setup(opts)
      vim.api.nvim_create_user_command("TrimWhitespace", MiniTrailspace.trim, { desc = "Trim trailing whitespace" })
    end,
  },
  {
    "nvim-mini/mini.bracketed",
    opts = {
      buffer = { suffix = "b" },
      comment = { suffix = "\\" },
      conflict = { suffix = "x" },
      diagnostic = { suffix = "d" },
      file = { suffix = "" },
      indent = { suffix = "" },
      jump = { suffix = "j" },
      location = { suffix = "l" },
      oldfile = { suffix = "" },
      quickfix = { suffix = "q" },
      treesitter = { suffix = "n" },
      undo = { suffix = "" },
      window = { suffix = "" },
      yank = { suffix = "" },
    },
    config = function(_, opts)
      local MiniBracketed = require("mini.bracketed")
      MiniBracketed.setup(opts)

      vim.keymap.set({ "n", "x" }, "[|", function()
        MiniBracketed.comment("first")
      end, { desc = "Comment first" })
      vim.keymap.set("o", "[|", "V<Cmd>lua MiniBracketed.comment('first')<CR>", { desc = "Comment first" })
      vim.keymap.set({ "n", "x" }, "]|", function()
        MiniBracketed.comment("last")
      end, { desc = "Comment last" })
      vim.keymap.set("o", "]|", "V<Cmd>lua MiniBracketed.comment('last')<CR>", { desc = "Comment last" })
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
        line_down = "<C-->",
        line_up = "<C-=>",
      },
    },
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
    ---@module "flash"
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
        "s",
        mode = { "n", "x", "o" },
        function()
          Flash.jump()
        end,
        desc = "Flash",
      },
      {
        "S",
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
        "<c-g>",
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
    "gbprod/yanky.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {},
    cmd = { "YankyRingHistory", "YankyClearHistory" },
    keys = {
      {
        "<leader>cy",
        function()
          Snacks.picker.yanky()
        end,
        mode = { "n", "x" },
        desc = "Yank History",
      },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" } },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" } },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" } },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" } },
      { "<C-N>", "<Plug>(YankyPreviousEntry)", desc = "Use previous yank for paste" },
      { "<C-P>", "<Plug>(YankyNextEntry)", desc = "Use next yank for paste" },
    },
  },
  {
    "gregorias/coerce.nvim",
    dependencies = { "gregorias/coop.nvim" },
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      local Coerce = require("coerce")
      Coerce.setup(opts)

      local expand = require("coerce.keymaps").which_key_expand
      for _, mapping in ipairs({
        { prefix = "gcr", mode = "n", cases = expand.normal_mode() },
        { prefix = "gCr", mode = "n", cases = expand.motion_mode() },
        { prefix = "gcr", mode = "x", cases = expand.visual_mode() },
      }) do
        for _, case in ipairs(mapping.cases) do
          vim.keymap.set(mapping.mode, mapping.prefix .. case[1], case[2], { desc = case.desc })
        end
      end
    end,
  },
  {
    "gbprod/substitute.nvim",
    dependencies = { "gbprod/yanky.nvim" },
    opts = {},
    config = function(_, opts)
      Substitute = require("substitute")
      opts.on_substitute = require("yanky.integration").substitute()
      Substitute.setup(opts)
    end,
    keys = {
      {
        "X",
        function()
          require("substitute.exchange").operator()
        end,
        desc = "Exchange using motion",
      },
      {
        "XX",
        function()
          require("substitute.exchange").line()
        end,
        desc = "Exchange line",
      },
      {
        "X",
        mode = "x",
        function()
          require("substitute.exchange").visual()
        end,
        desc = "Exchange selection",
      },
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
