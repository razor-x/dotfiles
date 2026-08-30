local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "rmagatti/auto-session",
    lazy = false,
    ---@module "auto-session.config"
    ---@type AutoSession.Config
    opts = {
      git_use_branch_name = false,
      purge_after_minutes = 60 * 48,
    },
    keys = {
      {
        "<leader>N",
        function()
          local auto_session = require("auto-session")
          auto_session.delete_session()
          auto_session.disable_auto_save()
          vim.cmd("restart!")
        end,
        desc = "Reset Session",
      },
    },
  },
  {
    "mbbill/undotree",
    keys = {
      { "<Leader>u", "<Cmd>UndotreeShow<Bar>UndotreeFocus<CR>", desc = "Open or focus undo tree" },
      { "<Leader>U", "<Cmd>UndotreeToggle<CR>", desc = "Toggle undo tree" },
    },
  },
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-mini/mini.icons" },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
}

return M.spec
