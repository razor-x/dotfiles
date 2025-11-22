vim.cmd('source ' .. vim.fn.stdpath('config') .. '/legacy.vim')

require("lazy").setup()
