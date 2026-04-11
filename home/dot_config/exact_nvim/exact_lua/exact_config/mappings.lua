local M = {}

function M.setup()
  -- Map leader to space and local leader to \.
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"

  -- Add shortcut to restart server and reload configuration.
  vim.keymap.set("n", "<F5>", ":restart<CR>", { silent = true })

  -- Add aliases for consistent behavior of ctrl-space.
  vim.keymap.set("n", "<NUL>", "<C-Space>", { remap = true })
  vim.keymap.set("i", "<NUL>", "<C-Space>", { remap = true })
  vim.keymap.set("c", "<NUL>", "<C-Space>", { remap = true })

  -- Map enter to escape in insert mode.
  vim.keymap.set("i", "<CR>", "<Esc>")

  -- Use backspace as left in insert mode.
  vim.keymap.set("i", "<BS>", "<Left>")

  -- Use ctrl-enter or shift-enter to split line and insert in normal mode.
  vim.keymap.set("n", "<C-CR>", "i<C-CR>", { remap = true })
  vim.keymap.set("n", "<S-CR>", "i<C-CR>", { remap = true })

  -- Use enter to open command-line mode.
  vim.keymap.set("n", "<CR>", ":")
  vim.keymap.set("v", "<CR>", ":")

  -- Fix enter behavior in quickfix and command-line windows.
  local cr_local_mappings = vim.api.nvim_create_augroup("cr-local-mappings", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = cr_local_mappings,
    pattern = "quickfix",
    callback = function(event)
      vim.keymap.set("n", "<CR>", "<CR>", { buffer = event.buf })
    end,
  })
  vim.api.nvim_create_autocmd("CmdwinEnter", {
    group = cr_local_mappings,
    pattern = "*",
    callback = function()
      vim.keymap.set("n", "<CR>", "<CR>")
    end,
  })
  vim.api.nvim_create_autocmd("CmdwinLeave", {
    group = cr_local_mappings,
    pattern = "*",
    callback = function()
      vim.keymap.set("n", "<CR>", ":")
    end,
  })

  -- Use q and Q for ge and gE.
  vim.keymap.set("n", "q", "ge", { remap = true })
  vim.keymap.set("v", "q", "ge", { remap = true })
  vim.keymap.set("o", "q", "ge", { remap = true })
  vim.keymap.set("n", "Q", "gE", { remap = true })
  vim.keymap.set("v", "Q", "gE", { remap = true })
  vim.keymap.set("o", "Q", "gE", { remap = true })

  -- Map U to redo and <C-R> to U.
  vim.keymap.set("n", "U", "<C-R>")
  vim.keymap.set("n", "<C-R>", "U")

  -- Swap ` with '.
  vim.keymap.set("n", "`", "'")
  vim.keymap.set("v", "`", "'")
  vim.keymap.set("n", "'", "`")
  vim.keymap.set("v", "'", "`")

  -- Make & behave like &&.
  vim.keymap.set("n", "&", ":<C-U>&&<CR>", { silent = true })
  vim.keymap.set("x", "&", ":<C-U>&&<CR>", { silent = true })

  -- Allow shift-escape to open and close command-line window.
  vim.keymap.set("n", "<S-Esc>", "q:")
  local command_line_local_mappings = vim.api.nvim_create_augroup("command-line-local-mappings", { clear = true })
  vim.api.nvim_create_autocmd("CmdwinEnter", {
    group = command_line_local_mappings,
    pattern = "*",
    callback = function()
      vim.keymap.set("n", "<S-Esc>", ":<C-U>q<CR>", { silent = true })
      vim.keymap.set("v", "<S-Esc>", ":<C-U>q<CR>", { silent = true })
    end,
  })
  vim.api.nvim_create_autocmd("CmdwinLeave", {
    group = command_line_local_mappings,
    pattern = "*",
    callback = function()
      vim.keymap.set("n", "<S-Esc>", "q:")
      vim.keymap.set("v", "<S-Esc>", "q:")
    end,
  })

  -- Use ctrl-h to as backspace in insert mode.
  vim.keymap.set("i", "<C-H>", "<BS>")

  -- Use ctrl-k as split line in insert mode.
  vim.keymap.set("i", "<C-K>", "<CR><Up><C-O>$")

  -- Use ctrl-k as split line in insert mode.
  vim.keymap.set("i", "<C-L>", "<Right>")

  -- Use backspace, ctrl-h, and ctrl-l to navigate command input.
  vim.keymap.set("c", "<BS>", "<Left>")
  vim.keymap.set("c", "<C-H>", "<BS>")
  vim.keymap.set("c", "<C-L>", "<Right>")

  -- Use ctrl-a to jump to start of command input.
  vim.keymap.set("c", "<C-A>", "<Home>")

  -- Use ctrl-k and ctrl-j to navigate command history.
  vim.keymap.set("c", "<C-K>", "<Up>")
  vim.keymap.set("c", "<C-J>", "<Down>")

  -- Provide alternate mapping for q since it is overridden above.
  vim.keymap.set("n", "<Tab>", "q")
  vim.keymap.set("n", "<Tab><Tab>", "qq<Esc>")
  vim.keymap.set("v", "<Tab>", "q")
  vim.keymap.set("v", "<Tab><Tab>", "qq")

  -- Provide alternate mapping for tab.
  vim.keymap.set("n", "<C-Tab>", "<Tab>")

  -- Add shortcut for @q.
  vim.keymap.set("n", "<C-Q>", "@q")
  vim.keymap.set("v", "<C-Q>", "@q")

  -- Add shortcut to toggle folds.
  vim.keymap.set("n", "<Leader><Leader>", "za")

  -- Add shortcuts to split the window.
  vim.keymap.set("n", "<Leader>h", ":<C-U>leftabove vsplit<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>l", ":<C-U>rightbelow vsplit<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>k", ":<C-U>leftabove split<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>j", ":<C-U>rightbelow split<CR>", { silent = true })

  -- Add shortcuts to split the frame.
  vim.keymap.set("n", "<Leader>H", ":<C-U>topleft vsplit<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>L", ":<C-U>botright vsplit<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>K", ":<C-U>topleft split<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>J", ":<C-U>botright split<CR>", { silent = true })

  -- Add shortcuts to open and close tabs.
  vim.keymap.set("n", "<Leader><Tab>", ":<C-U>tabnew<CR>", { silent = true })
  vim.keymap.set("n", "<Leader><S-Tab>", ":<C-U>tabclose<CR>", { silent = true })

  -- Add shortcuts to cycle through tabs.
  vim.keymap.set("n", "<C-,>", "gT")
  vim.keymap.set("n", "<C-.>", "gt")

  -- Add shortcuts to open command-line and search history windows.
  vim.keymap.set("n", "<Leader>:", "q:")
  vim.keymap.set("v", "<Leader>:", "q:")
  vim.keymap.set("n", "<Leader>/", "q/")
  vim.keymap.set("v", "<Leader>/", "q/")
  vim.keymap.set("n", "<Leader>?", "q?")
  vim.keymap.set("v", "<Leader>?", "q?")

  -- Add shortcut to close preview window.
  vim.keymap.set("n", "<Leader>xz", ":<C-U>pclose<CR>", { silent = true })

  -- Add shortcut to clear highlighting until next search.
  vim.keymap.set("n", "<Leader>o", ":<C-U>nohlsearch<CR>", { silent = true })

  -- Add shortcut for new.
  vim.keymap.set("n", "<Leader>n", ":<C-U>enew<CR>", { silent = true })

  -- Add shortcut to force reload file.
  vim.keymap.set("n", "<Leader>E", ":<C-U>edit!<CR>", { silent = true })

  -- Add shortcuts for update and force write.
  vim.keymap.set("n", "<Leader>s", ":<C-U>update<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>S", ":<C-U>write!<CR>", { silent = true })

  -- Add shortcuts for quit.
  vim.keymap.set("n", "<Leader><CR>", ":<C-U>quit<CR>", { silent = true })
  vim.keymap.set("v", "<Leader><CR>", ":<C-U>quit<CR>", { silent = true })

  -- Add shortcuts for force quit and quit all.
  vim.keymap.set("n", "<Leader>q", ":<C-U>quitall<CR>", { silent = true })
  vim.keymap.set("v", "<Leader>q", ":<C-U>quitall<CR>", { silent = true })
  vim.keymap.set("n", "<Leader>Q", ":<C-U>quitall!<CR>", { silent = true })
  vim.keymap.set("v", "<Leader>Q", ":<C-U>quitall!<CR>", { silent = true })

  -- Add shortcut to paste from the expression register.
  vim.keymap.set("n", "<Leader>=", ":<C-U>put =")

  -- Use <C-G> for M.
  vim.keymap.set("n", "<C-G>", "M")

  -- Create the system clipboard mappings using the + register.
  System_clipboard_mappings("+", true)

  -- Toggle system clipboard mappings between the + and * registers.
  vim.keymap.set("n", "yoP", function()
    local register = vim.g.mapped_system_clipboard == "+" and "*" or "+"
    System_clipboard_mappings(register, false)
  end, { silent = true })

  -- Toggle colored column.
  vim.keymap.set("n", "yom", function()
    if vim.wo.colorcolumn == "" then
      vim.opt.colorcolumn = "81"
    else
      vim.opt.colorcolumn = ""
    end
  end, { silent = true })
end

function System_clipboard_mappings(register, quiet)
  -- Copy to system clipboard.
  vim.keymap.set("n", "<Leader>c", '"' .. register .. "y")
  vim.keymap.set("v", "<Leader>c", '"' .. register .. "y")
  vim.keymap.set("n", "<Leader>C", '"' .. register .. "Y")
  vim.keymap.set("n", "<Leader>cc", '"' .. register .. "yy")

  -- Move to system clipboard.
  vim.keymap.set("n", "<Leader>m", '"' .. register .. "d")
  vim.keymap.set("v", "<Leader>m", '"' .. register .. "d")
  vim.keymap.set("n", "<Leader>M", '"' .. register .. "D")
  vim.keymap.set("n", "<Leader>mm", '"' .. register .. "dd")

  -- Paste from system clipboard.
  vim.keymap.set("n", "<Leader>p", '"' .. register .. "p")
  vim.keymap.set("n", "<Leader>P", '"' .. register .. "P")

  -- Substitute from the system clipboard easyclip.
  -- TODO: Depends on plugin.
  vim.keymap.set("v", "<C-;>", '"' .. register .. ":", { remap = true })
  vim.keymap.set("n", "<C-;>", '"' .. register .. ":", { remap = true })
  vim.keymap.set("n", "<C-;><C-;>", '"' .. register .. "::", { remap = true })

  vim.g.mapped_system_clipboard = register

  if not quiet then
    vim.notify("Setting system register to " .. register)
  end
end

return M
