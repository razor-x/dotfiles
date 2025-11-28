require("config").setup()
local pick = require("mini.pick")
pick.setup()

vim.keymap.set('n', '<leader>e', function()
  pick.builtin.files({
    tool = 'git'  -- Uses git ls-files (tracked files only)
  })
end, { desc = 'Pick git tracked files' })

vim.keymap.set('n', '<leader>f', function()
  pick.builtin.files()  -- Defaults to 'rg' which respects .gitignore and global ignore
end, { desc = 'Pick all files in cwd' })
