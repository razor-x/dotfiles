-- Use atomic updates.
vim.opt.backupcopy = 'yes'

-- Enable persistent undo history.
vim.opt.undofile = true

-- Hide buffers instead of closing them.
vim.opt.hidden = true

-- Open splits below by default.
vim.opt.splitbelow = true

-- Show line numbers.
vim.opt.number = true

-- Always show the sign column.
vim.opt.signcolumn = 'yes'

-- Set nonzero scrolloff.
vim.opt.scrolloff = 3

-- Set indentation preferences.
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Set search preferences.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Set folding preferences.
vim.opt.foldmethod = 'syntax'
vim.opt.foldenable = false

-- Disable bell and visual bell.
vim.opt.errorbells = false
vim.opt.visualbell = true
vim.opt.t_vb = ''

-- Set default autocompletion behavior.
vim.opt.completeopt:append('noinsert')

-- Hide some autocompletion messages.
vim.opt.shortmess:append('c')

-- Enable omni completion.
vim.opt.omnifunc = 'syntaxcomplete#Complete'

-- Set default tex flavor.
vim.g.tex_flavor = 'latex'

-- Set WildMenu preferences.
vim.opt.wildmode = 'longest:full,full'

-- Map space to leader.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Add aliases for consistent behavior of ctrl-space.
vim.keymap.set('n', '<NUL>', '<C-Space>')
vim.keymap.set('i', '<NUL>', '<C-Space>')
vim.keymap.set('c', '<NUL>', '<C-Space>')

-- Map enter to escape in insert mode.
vim.keymap.set('i', '<CR>', '<Esc>')

-- Use backspace as left in insert mode.
vim.keymap.set('i', '<BS>', '<Left>')

-- Use ctrl-k as split line in insert mode.
-- NOTE: This is redefined in lexima.vim.
-- vim.keymap.set('i', '<C-H>', '<BS>')

-- Use ctrl-k as split line in insert mode.
-- NOTE: This is redefined in autocompletion.vim.
-- vim.keymap.set('i', '<C-K>', '<CR><Up><C-O>$')

-- Use ctrl-l as Right in insert mode.
-- NOTE: This is redefined in autocompletion.vim.
-- vim.keymap.set('i', '<C-L>', '<Right>')

-- Use ctrl-enter or shift-enter to split line and insert in normal mode.
vim.keymap.set('n', '<C-CR>', 'i<C-CR>')
vim.keymap.set('n', '<S-CR>', 'i<C-CR>')

-- Use enter to open command-line mode.
vim.keymap.set('n', '<CR>', ':')
vim.keymap.set('v', '<CR>', ':')

-- Fix enter behavior in quickfix and command-line windows.
local cr_group = vim.api.nvim_create_augroup('cr-local-mappings', { clear = true })
vim.api.nvim_create_autocmd('BufReadPost', {
  group = cr_group,
  pattern = 'quickfix',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true })
  end,
})
vim.api.nvim_create_autocmd('CmdwinEnter', {
  group = cr_group,
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>')
  end,
})
vim.api.nvim_create_autocmd('CmdwinLeave', {
  group = cr_group,
  callback = function()
    vim.keymap.set('n', '<CR>', ':')
  end,
})

-- Use q and Q for ge and gE.
vim.keymap.set('n', 'q', 'ge')
vim.keymap.set('v', 'q', 'ge')
vim.keymap.set('o', 'q', 'ge')
vim.keymap.set('n', 'Q', 'gE')
vim.keymap.set('v', 'Q', 'gE')
vim.keymap.set('o', 'Q', 'gE')

-- Map U to redo and <C-R> to U.
vim.keymap.set('n', 'U', '<C-R>')
vim.keymap.set('n', '<C-R>', 'U')

-- Swap ` with '.
vim.keymap.set('n', '`', "'")
vim.keymap.set('v', '`', "'")
vim.keymap.set('n', "'", '`')
vim.keymap.set('v', "'", '`')

-- Make & behave like &&.
vim.keymap.set('n', '&', ':<C-U>&&<CR>', { silent = true })
vim.keymap.set('x', '&', ':<C-U>&&<CR>', { silent = true })

-- Allow shift-escape to open and close command-line window.
vim.keymap.set('n', '<S-Esc>', 'q:')
local cmdwin_group = vim.api.nvim_create_augroup('command-line-local-mappings', { clear = true })
vim.api.nvim_create_autocmd('CmdwinEnter', {
  group = cmdwin_group,
  callback = function()
    vim.keymap.set('n', '<S-Esc>', ':<C-U>q<CR>', { buffer = true, silent = true })
    vim.keymap.set('v', '<S-Esc>', ':<C-U>q<CR>', { buffer = true, silent = true })
  end,
})
vim.api.nvim_create_autocmd('CmdwinLeave', {
  group = cmdwin_group,
  callback = function()
    vim.keymap.set('n', '<S-Esc>', 'q:')
    vim.keymap.set('v', '<S-Esc>', 'q:')
  end,
})

-- Use ctrl-h and ctrl-l to navigate command input.
vim.keymap.set('c', '<C-H>', '<Left>')
vim.keymap.set('c', '<C-L>', '<Right>')

-- Use ctrl-k and ctrl-j to navigate command history.
vim.keymap.set('c', '<C-K>', '<Up>')
vim.keymap.set('c', '<C-J>', '<Down>')

-- Provide alternate mapping for q since it is overridden above.
vim.keymap.set('n', '<Tab>', 'q')
vim.keymap.set('n', '<Tab><Tab>', 'qq<Esc>')
vim.keymap.set('v', '<Tab>', 'q')
vim.keymap.set('v', '<Tab><Tab>', 'qq')

-- Provide alternate mapping for tab.
vim.keymap.set('n', '<C-Tab>', '<Tab>')

-- Add shortcut for @q.
vim.keymap.set('n', '<C-Q>', '@q')
vim.keymap.set('v', '<C-Q>', '@q')

-- Add shortcut to toggle folds.
vim.keymap.set('n', '<Leader><Leader>', 'za')

-- Add shortcuts to navigate out of the terminal.
vim.keymap.set('t', '<C-CR>', '<C-\\><C-N>')
local term_group = vim.api.nvim_create_augroup('neovim-terminal-mappings', { clear = true })
vim.api.nvim_create_autocmd('TermOpen', {
  group = term_group,
  callback = function()
    vim.keymap.set('t', '<C-H>', '<C-\\><C-N><C-H>', { buffer = true })
    vim.keymap.set('t', '<C-J>', '<C-\\><C-N><C-J>', { buffer = true })
    vim.keymap.set('t', '<C-K>', '<C-\\><C-N><C-K>', { buffer = true })
    vim.keymap.set('t', '<C-L>', '<C-\\><C-N><C-W>', { buffer = true })
  end,
})

-- Add shortcuts to split the window.
vim.keymap.set('n', '<Leader>h', ':<C-U>leftabove vsplit<CR>', { silent = true })
vim.keymap.set('n', '<Leader>l', ':<C-U>rightbelow vsplit<CR>', { silent = true })
vim.keymap.set('n', '<Leader>k', ':<C-U>leftabove split<CR>', { silent = true })
vim.keymap.set('n', '<Leader>j', ':<C-U>rightbelow split<CR>', { silent = true })

-- Add shortcuts to split the frame.
vim.keymap.set('n', '<Leader>H', ':<C-U>topleft vsplit<CR>', { silent = true })
vim.keymap.set('n', '<Leader>L', ':<C-U>botright vsplit<CR>', { silent = true })
vim.keymap.set('n', '<Leader>K', ':<C-U>topleft split<CR>', { silent = true })
vim.keymap.set('n', '<Leader>J', ':<C-U>botright split<CR>', { silent = true })

-- Add shortcuts to open and close tabs.
vim.keymap.set('n', '<Leader><Tab>', ':<C-U>tabnew<CR>', { silent = true })
vim.keymap.set('n', '<Leader><S-Tab>', ':<C-U>tabclose<CR>', { silent = true })

-- Add shortcuts to cycle through tabs.
vim.keymap.set('n', '<C-,>', 'gT')
vim.keymap.set('n', '<C-.>', 'gt')

-- Add shortcuts to open command-line and search history windows.
vim.keymap.set('n', '<Leader>:', 'q:')
vim.keymap.set('v', '<Leader>:', 'q:')
vim.keymap.set('n', '<Leader>/', 'q/')
vim.keymap.set('v', '<Leader>/', 'q/')
vim.keymap.set('n', '<Leader>?', 'q?')
vim.keymap.set('v', '<Leader>?', 'q?')

-- Add shortcut to close preview window.
vim.keymap.set('n', '<Leader>xz', ':<C-U>pclose<CR>', { silent = true })

-- Add shortcut to clear highlighting until next search.
vim.keymap.set('n', '<Leader>o', ':<C-U>nohlsearch<CR>', { silent = true })

-- Add shortcut for new.
vim.keymap.set('n', '<Leader>n', ':<C-U>enew<CR>', { silent = true })

-- Add shortcut to force reload file.
vim.keymap.set('n', '<Leader>E', ':<C-U>edit!<CR>', { silent = true })

-- Add shortcuts for update and force write.
vim.keymap.set('n', '<Leader>s', ':<C-U>update<CR>', { silent = true })
vim.keymap.set('n', '<Leader>S', ':<C-U>write!<CR>', { silent = true })

-- Add shortcuts for quit.
vim.keymap.set('n', '<Leader><CR>', ':<C-U>quit<CR>', { silent = true })
vim.keymap.set('v', '<Leader><CR>', ':<C-U>quit<CR>', { silent = true })

-- Add shortcuts for force quit and quit all.
vim.keymap.set('n', '<Leader>q', ':<C-U>quitall<CR>', { silent = true })
vim.keymap.set('v', '<Leader>q', ':<C-U>quitall<CR>', { silent = true })
vim.keymap.set('n', '<Leader>Q', ':<C-U>quitall!<CR>', { silent = true })
vim.keymap.set('v', '<Leader>Q', ':<C-U>quitall!<CR>', { silent = true })

-- Add shortcut to paste from the expression register.
vim.keymap.set('n', '<Leader>=', ':<C-U>put =')

-- Use <C-G> for M.
vim.keymap.set('n', '<C-G>', 'M')

-- Adds mappings for the system clipboard.
local function system_clipboard_mappings(register, quiet)
  -- Copy to system clipboard.
  vim.keymap.set('n', '<Leader>c', '"' .. register .. 'y')
  vim.keymap.set('v', '<Leader>c', '"' .. register .. 'y')
  vim.keymap.set('n', '<Leader>C', '"' .. register .. 'Y')
  vim.keymap.set('n', '<Leader>cc', '"' .. register .. 'yy')

  -- Move to system clipboard.
  vim.keymap.set('n', '<Leader>m', '"' .. register .. 'd')
  vim.keymap.set('v', '<Leader>m', '"' .. register .. 'd')
  vim.keymap.set('n', '<Leader>M', '"' .. register .. 'D')
  vim.keymap.set('n', '<Leader>mm', '"' .. register .. 'dd')

  -- Paste from system clipboard.
  vim.keymap.set('n', '<Leader>p', '"' .. register .. 'p')
  vim.keymap.set('n', '<Leader>P', '"' .. register .. 'P')

  -- Substitute from the system clipboard with easyclip.
  vim.keymap.set('v', '<C-;>', '"' .. register .. ':')
  vim.keymap.set('n', '<C-;>', '"' .. register .. ':')
  vim.keymap.set('n', '<C-;><C-;>', '"' .. register .. '::')

  -- Save the newly mapped register.
  vim.g.mapped_system_clipboard = register

  if not quiet then
    print('Setting system register to ' .. register)
  end
end

-- Create the system clipboard mappings using the + register.
system_clipboard_mappings('+', true)

-- Toggle system clipboard mappings between the + and * registers.
vim.keymap.set('n', 'yoP', function()
  if vim.g.mapped_system_clipboard == '+' then
    system_clipboard_mappings('*', false)
  else
    system_clipboard_mappings('+', false)
  end
end, { silent = true })

-- Toggle colored column.
vim.keymap.set('n', 'yom', function()
  if vim.opt.colorcolumn:get()[1] == nil then
    vim.opt.colorcolumn = '81'
  else
    vim.opt.colorcolumn = ''
  end
end, { silent = true, expr = false })
