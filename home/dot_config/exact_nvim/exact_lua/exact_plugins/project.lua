local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "nvim-mini/mini.files",
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
}

return M.spec
