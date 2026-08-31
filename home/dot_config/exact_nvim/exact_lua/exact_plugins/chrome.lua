local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "HiPhish/rainbow-delimiters.nvim",
    submodules = false,
  },
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
    "amansingh-afk/milli.nvim",
    lazy = false,
    config = function()
      local function hide_editor_chrome()
        if vim.b.milli_chrome_hidden then
          return
        end
        vim.b.milli_chrome_hidden = true
        vim.b.minitrailspace_disable = true
        require("mini.trailspace").unhighlight()

        local window = vim.api.nvim_get_current_win()
        local guicursor = vim.o.guicursor
        vim.o.guicursor = "a:hor1-MilliHiddenCursor"
        vim.api.nvim_set_hl(0, "MilliHiddenCursor", { blend = 100, nocombine = true })

        local options = {
          colorcolumn = "",
          cursorline = false,
          foldcolumn = "0",
          list = false,
          number = false,
          relativenumber = false,
          signcolumn = "no",
          spell = false,
          statuscolumn = "",
        }
        local previous = {}
        for option, value in pairs(options) do
          previous[option] = vim.wo[option]
          vim.wo[option] = value
        end

        vim.api.nvim_create_autocmd("BufLeave", {
          buffer = 0,
          once = true,
          callback = function()
            vim.o.guicursor = guicursor
            vim.api.nvim_set_hl(0, "MilliHiddenCursor", {})
            if vim.api.nvim_win_is_valid(window) then
              for option, value in pairs(previous) do
                vim.wo[window][option] = value
              end
            end
          end,
        })
      end

      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = { "milli://*", "milli-shader://*" },
        callback = hide_editor_chrome,
      })
    end,
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
  },
}

return M.spec
