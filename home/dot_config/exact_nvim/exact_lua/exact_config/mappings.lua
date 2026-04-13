local M = {}

function M.setup()
  -- Map leader to space and local leader to \.
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"

  -- Use F5 to restart server and reload configuration.
  vim.keymap.set("n", "<F5>", M.cmd("restart"), { silent = true })

  -- Use enter to leave insert mode.
  vim.keymap.set("i", "<CR>", "<Esc>")

  -- Use enter to open command-line mode.
  vim.keymap.set("n", "<CR>", ":")
  vim.keymap.set("v", "<CR>", ":")

  -- Use enter normally in command-line and quickfix buffers instead of the remapping to escape.
  local cr_local_mappings = vim.api.nvim_create_augroup("cr-local-mappings", { clear = true })
  vim.api.nvim_create_autocmd("CmdwinEnter", {
    group = cr_local_mappings,
    pattern = "*",
    callback = function(event)
      vim.keymap.set("n", "<CR>", "<CR>", { buffer = event.buf })
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = cr_local_mappings,
    pattern = "qf",
    callback = function(event)
      vim.keymap.set("n", "<CR>", "<CR>", { buffer = event.buf })
    end,
  })

  -- Use shift-enter to split line and insert from normal mode.
  vim.keymap.set("n", "<S-CR>", "i<C-CR>", { remap = true })

  -- Use backspace as left in insert mode.
  vim.keymap.set("i", "<BS>", "<Left>")

  -- Use ctrl-k as split line in-place in insert mode.
  vim.keymap.set("i", "<C-K>", "<CR><Up><C-O>$")

  -- Use ctrl-l as right in insert mode.
  vim.keymap.set("i", "<C-L>", "<Right>")

  -- Use ctrl-h as backspace in insert mode.
  vim.keymap.set("i", "<C-H>", "<BS>")

  -- Use backspace, ctrl-h, and ctrl-l to navigate command input.
  vim.keymap.set("c", "<BS>", "<Left>")
  vim.keymap.set("c", "<C-H>", "<BS>")
  vim.keymap.set("c", "<C-L>", "<Right>")

  -- Use ctrl-a to jump to start of command input.
  vim.keymap.set("c", "<C-A>", "<Home>")

  -- Use ctrl-k and ctrl-j to navigate command history.
  vim.keymap.set("c", "<C-K>", "<Up>")
  vim.keymap.set("c", "<C-J>", "<Down>")

  -- Use q and Q to move backward by word end.
  vim.keymap.set("n", "q", "ge", { remap = true })
  vim.keymap.set("v", "q", "ge", { remap = true })
  vim.keymap.set("o", "q", "ge", { remap = true })
  vim.keymap.set("n", "Q", "gE", { remap = true })
  vim.keymap.set("v", "Q", "gE", { remap = true })
  vim.keymap.set("o", "Q", "gE", { remap = true })

  -- Use tab to access macro recording.
  vim.keymap.set("n", "<Tab>", "q")
  vim.keymap.set("n", "<Tab><Tab>", "qq")
  vim.keymap.set("v", "<Tab>", "q")
  vim.keymap.set("v", "<Tab><Tab>", "qq")

  -- Use ctrl-q to replay the q register.
  vim.keymap.set("n", "<C-Q>", "@q")
  vim.keymap.set("v", "<C-Q>", "@q")

  -- Use U to redo and ctrl-r to restore the current line.
  vim.keymap.set("n", "U", "<C-R>")
  vim.keymap.set("n", "<C-R>", "U")

  -- Use & to repeat the last substitution with its flags.
  vim.keymap.set("n", "&", M.cmd("&&"), { silent = true })
  vim.keymap.set("x", "&", M.cmd("&&"), { silent = true })

  -- Use shift-escape to toggle the command-line window from normal mode.
  vim.keymap.set("n", "<S-Esc>", "q:")
  local command_line_local_mappings = vim.api.nvim_create_augroup("command-line-local-mappings", { clear = true })
  vim.api.nvim_create_autocmd("CmdwinEnter", {
    group = command_line_local_mappings,
    pattern = "*",
    callback = function()
      vim.keymap.set("n", "<S-Esc>", M.cmd("q"), { silent = true })
      vim.keymap.set("v", "<S-Esc>", M.cmd("q"), { silent = true })
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

  -- Use leader-{hjkl} to split the current window.
  vim.keymap.set("n", "<Leader>h", M.cmd("leftabove vsplit"), { silent = true })
  vim.keymap.set("n", "<Leader>l", M.cmd("rightbelow vsplit"), { silent = true })
  vim.keymap.set("n", "<Leader>k", M.cmd("leftabove split"), { silent = true })
  vim.keymap.set("n", "<Leader>j", M.cmd("rightbelow split"), { silent = true })

  -- Use leader-{HJKL} to split the frame edges.
  vim.keymap.set("n", "<Leader>H", M.cmd("topleft vsplit"), { silent = true })
  vim.keymap.set("n", "<Leader>L", M.cmd("botright vsplit"), { silent = true })
  vim.keymap.set("n", "<Leader>K", M.cmd("topleft split"), { silent = true })
  vim.keymap.set("n", "<Leader>J", M.cmd("botright split"), { silent = true })

  -- Add shortcuts to open and close tabs.
  vim.keymap.set("n", "<Leader><Tab>", M.cmd("tabnew"), { silent = true })
  vim.keymap.set("n", "<Leader><S-Tab>", M.cmd("tabclose"), { silent = true })

  -- Use ctrl-, and ctrl-. to cycle through tabs.
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
  -- TODO: Does this still make sense?
  vim.keymap.set("n", "<Leader>xz", M.cmd("pclose"), { silent = true })

  -- Add shortcut to clear highlighting until next search.
  vim.keymap.set("n", "<Leader>o", M.cmd("nohlsearch"), { silent = true })

  -- Use leader-n to open a new empty buffer.
  vim.keymap.set("n", "<Leader>n", M.cmd("enew"), { silent = true })

  -- Add shortcut to force reload file.
  vim.keymap.set("n", "<Leader>E", M.cmd("edit!"), { silent = true })

  -- Add shortcuts for update and force write.
  vim.keymap.set("n", "<Leader>s", M.cmd("update"), { silent = true })
  vim.keymap.set("n", "<Leader>S", M.cmd("write!"), { silent = true })

  -- Add shortcuts for quit.
  vim.keymap.set("n", "<Leader><CR>", M.cmd("quit"), { silent = true })
  vim.keymap.set("v", "<Leader><CR>", M.cmd("quit"), { silent = true })

  -- Add shortcuts for force quit and quit all.
  vim.keymap.set("n", "<Leader>q", M.cmd("quitall"), { silent = true })
  vim.keymap.set("v", "<Leader>q", M.cmd("quitall"), { silent = true })
  vim.keymap.set("n", "<Leader>Q", M.cmd("quitall!"), { silent = true })
  vim.keymap.set("v", "<Leader>Q", M.cmd("quitall!"), { silent = true })

  -- Use leader-= to paste from the expression register.
  vim.keymap.set("n", "<Leader>=", ":<C-U>put =")

  -- Use ctrl-g to jump to the middle of the screen.
  -- TODO: This is only mapped since M is needed for a plugin.
  vim.keymap.set("n", "<C-G>", "M")

  -- Use the + register for system clipboard mappings.
  M.system_clipboard_mappings("+", true)

  -- Use yoP to switch system clipboard mappings between + and *.
  vim.keymap.set("n", "yoP", function()
    local register = vim.g.mapped_system_clipboard == "+" and "*" or "+"
    M.system_clipboard_mappings(register, false)
  end, { silent = true })

  -- Use yom to toggle the color column.
  vim.keymap.set("n", "yom", function()
    if vim.opt.colorcolumn == "" then
      vim.opt.colorcolumn = "81"
    else
      vim.opt.colorcolumn = ""
    end
  end, { silent = true })
end

function M.system_clipboard_mappings(register, quiet)
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

  -- Use easyclip substitution with the system clipboard.
  -- TODO: Depends on the easyclip plugin.
  vim.keymap.set("v", "<C-;>", '"' .. register .. ":", { remap = true })
  vim.keymap.set("n", "<C-;>", '"' .. register .. ":", { remap = true })
  vim.keymap.set("n", "<C-;><C-;>", '"' .. register .. "::", { remap = true })

  vim.g.mapped_system_clipboard = register

  if not quiet then
    vim.notify("Setting system register to " .. register)
  end
end

function M.cmd(command)
  return function()
    vim.cmd(command)
  end
end

return M
