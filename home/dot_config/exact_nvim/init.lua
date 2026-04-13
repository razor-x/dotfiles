local config = require("config")

---@type string | nil
local plugin_import = "plugins"
if os.getenv("NVIM_DISABLE_PLUGINS") then
  plugin_import = nil
end
config.setup(plugin_import)

local pick = require("mini.pick")
pick.setup()

require("mini.completion").setup()

vim.keymap.set("n", "<leader>e", function()
  pick.builtin.files({
    tool = "git", -- Uses git ls-files (tracked files only)
  })
end, { desc = "Pick git tracked files" })

vim.keymap.set("n", "<leader>f", function()
  pick.builtin.files() -- Defaults to 'rg' which respects .gitignore and global ignore
end, { desc = "Pick all files in cwd" })

local map_multistep = require("mini.keymap").map_multistep
map_multistep("i", "<Tab>", { "pmenu_next" })
map_multistep("i", "<S-Tab>", { "pmenu_prev" })
map_multistep("i", "<C-l>", { "pmenu_accept", "minipairs_cr" })
map_multistep("i", "<BS>", { "minipairs_bs" })

vim.keymap.set("i", "<C-e>", function()
  MiniPick.builtin.buffer_lines({ scope = "current" })
end)
