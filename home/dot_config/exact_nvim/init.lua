require("config").setup()
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

local smart_splits = require("smart-splits")

vim.keymap.set("n", "<A-h>", smart_splits.resize_left)
vim.keymap.set("n", "<A-j>", smart_splits.resize_down)
vim.keymap.set("n", "<A-k>", smart_splits.resize_up)
vim.keymap.set("n", "<A-l>", smart_splits.resize_right)
-- moving between splits
vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left)
vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down)
vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up)
vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right)
vim.keymap.set("n", "<C-\\>", smart_splits.move_cursor_previous)
-- swapping buffers between windows
vim.keymap.set("n", "<leader><leader>h", smart_splits.swap_buf_left)
vim.keymap.set("n", "<leader><leader>j", smart_splits.swap_buf_down)
vim.keymap.set("n", "<leader><leader>k", smart_splits.swap_buf_up)
vim.keymap.set("n", "<leader><leader>l", smart_splits.swap_buf_right)

require("cutlass")

vim.lsp.enable("clangd")

vim.lsp.enable("clojure_lsp")
-- TODO cljfmt, kondo ?

vim.lsp.enable("gopls")
vim.lsp.enable("golangci_lint_ls")

vim.lsp.enable("ts_ls")
vim.lsp.enable("biome")

vim.lsp.enable("lua_ls")
vim.lsp.enable("stylua")
vim.lsp.enable("selene3p_ls")

vim.lsp.enable("psalm")
vim.lsp.enable("phpactor")
-- TODO mago ?

vim.lsp.enable("pyright")
vim.lsp.enable("ruff")
vim.lsp.enable("ruff_ls")

vim.lsp.enable("ruby_lsp")
vim.lsp.enable("rubocop")

vim.lsp.enable("bashls")
vim.lsp.enable("fish_lsp")

local map_multistep = require('mini.keymap').map_multistep
map_multistep('i', '<Tab>',   { 'pmenu_next' })
map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
map_multistep('i', '<CR>',    { 'pmenu_accept', 'minipairs_cr' })
map_multistep('i', '<BS>',    { 'minipairs_bs' })

vim.keymap.set('i', '<C-e>', function()
  MiniPick.builtin.buffer_lines({ scope = 'current' })
end)
