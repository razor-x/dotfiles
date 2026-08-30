local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    ---@module "catppuccin"
    ---@type CatppuccinOptions
    opts = {
      auto_integrations = true,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "nvim-mini/mini.icons",
    opts = {},
    config = function(_, opts)
      require("mini.icons").setup(opts)
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
  {
    "nvim-mini/mini.statuscolumn",
    opts = {},
  },
  {
    "catgoose/nvim-colorizer.lua",
    ---@module "colorizer.config"
    ---@type colorizer.SetupOptions
    opts = { ---@diagnostic disable-line:missing-fields
    },
    event = "BufReadPre",
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    opts = {
      options = {
        theme = "catppuccin-nvim",
        component_separators = "",
        section_separators = { left = "", right = "" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    event = "VeryLazy",
    ---@module "which-key"
    ---@type wk.Opts
    opts = {
      delay = function(ctx)
        if ctx.keys == "z=" then
          return 0
        end
        return ctx.plugin and 0 or 500
      end,
      spec = {
        { "<c-e>", group = "mark" },
        { "<c-f>", group = "fold" },
        { "<c-g>", group = "picker", mode = "i" },
        { "z<CR>", hidden = true },
        { "z<Left>", hidden = true },
        { "z<Right>", hidden = true },
        { "z+", hidden = true },
        { "z-", hidden = true },
        { "z.", hidden = true },
        { "zA", hidden = true },
        { "zC", hidden = true },
        { "zD", hidden = true },
        { "zE", hidden = true },
        { "zF", hidden = true },
        { "zH", hidden = true },
        { "zL", hidden = true },
        { "zM", hidden = true },
        { "zN", hidden = true },
        { "zO", hidden = true },
        { "zR", hidden = true },
        { "zX", hidden = true },
        { "z^", hidden = true },
        { "za", hidden = true },
        { "zb", hidden = true },
        { "zc", hidden = true },
        { "zd", hidden = true },
        { "ze", hidden = true },
        { "zf", hidden = true },
        { "zh", hidden = true },
        { "zi", hidden = true },
        { "zj", hidden = true },
        { "zk", hidden = true },
        { "zl", hidden = true },
        { "zm", hidden = true },
        { "zn", hidden = true },
        { "zo", hidden = true },
        { "zr", hidden = true },
        { "zs", hidden = true },
        { "zt", hidden = true },
        { "zv", hidden = true },
        { "zx", hidden = true },
        { "zz", hidden = true },
      },
      triggers = {
        { "<auto>", mode = "nixsotc" },
        { "<c-e>", mode = "n" },
        { "<c-f>", mode = "n" },
        { "<c-g>", mode = "i" },
      },
    },
    config = function(_, opts)
      WhichKey = require("which-key")
      WhichKey.setup(opts)
    end,
    keys = {
      {
        "<leader>?",
        function()
          WhichKey.show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}

return M.spec
