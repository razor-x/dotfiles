local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
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
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  {
    "folke/which-key.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    event = "VeryLazy",
    opts = {
      delay = function(ctx)
        if ctx.keys == "z=" then
          return 0
        end
        return ctx.plugin and 0 or 500
      end
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
