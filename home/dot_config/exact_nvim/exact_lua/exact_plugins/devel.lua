local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
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
}

return M.spec
