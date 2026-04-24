local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "nvim-mini/mini.basics",
    priority = 1000,
    init = function()
      -- Hide buffers instead of closing them.
      vim.opt.hidden = true

      -- Wrap long lines.
      vim.opt.wrap = true

      -- Set nonzero scrolloff.
      vim.opt.scrolloff = 5

      -- Set indentation preferences.
      vim.opt.tabstop = 2
      vim.opt.softtabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.autoindent = true

      -- Set folding preferences.
      vim.opt.foldmethod = "syntax"
      vim.opt.foldenable = false

      -- Enable EditorConfig.
      vim.g.editorconfig = true

      -- Set default tex flavor.
      vim.g.tex_flavor = "latex"

      -- Set WildMenu preferences.
      vim.opt.wildmode = "longest:full,full"
    end,
    opts = {
      options = {
        -- Basic options ('number', 'ignorecase', and many more)
        basic = true,

        -- Extra UI features ('winblend', 'listchars', 'pumheight', ...)
        extra_ui = true,

        -- Presets for window borders ('single', 'double', ...)
        -- Default 'auto' infers from 'winborder' option
        win_borders = "auto",
      },

      -- Mappings. Set field to `false` to disable.
      mappings = {
        -- Basic mappings (better 'jk', save with Ctrl+S, ...)
        basic = false,

        -- Prefix for mappings that toggle common options ('wrap', 'spell', ...).
        -- Supply empty string to not create these mappings.
        option_toggle_prefix = [[\]],

        -- Window navigation with <C-hjkl>, resize with <C-arrow>
        windows = false,

        -- Move cursor in Insert, Command, and Terminal mode with <M-hjkl>
        move_with_alt = false,
      },

      -- Autocommands. Set field to `false` to disable
      autocommands = {
        -- Basic autocommands (highlight on yank, start Insert in terminal, ...)
        basic = true,

        -- Set 'relativenumber' only in linewise and blockwise Visual mode
        relnum_in_visual_mode = true,
      },

      -- Whether to disable showing non-error feedback
      silent = false,
    },
  },
  {
    "nvim-mini/mini.keymap",
    priority = 900,
    init = function()
      vim.keymap.set("n", "<F5>", M.cmd("restart"), {
        desc = "Restarts Nvim",
        silent = true,
      })

      vim.keymap.set("i", "<CR>", "<Esc>", { desc = "Exit Insert mode" })

      vim.keymap.set("n", "<C-CR>", ":", { desc = "Enter Command-line mode" })
      vim.keymap.set("v", "<C-CR>", ":", { desc = "Enter Command-line mode" })

      -- Use enter normally in command-line and quickfix buffers instead of the remapping to escape.
      local cr_local_mappings = vim.api.nvim_create_augroup("cr-local-mappings", { clear = true })
      vim.api.nvim_create_autocmd("CmdwinEnter", {
        group = cr_local_mappings,
        pattern = "*",
        callback = function(event)
          vim.keymap.set("n", "<CR>", "<CR>", { buffer = event.buf, desc = "Execute command line" })
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = cr_local_mappings,
        pattern = "qf",
        callback = function(event)
          vim.keymap.set("n", "<CR>", "<CR>", { buffer = event.buf, desc = "Jump to current quickfix entry" })
        end,
      })

      vim.keymap.set("n", "<S-CR>", "i<C-CR>", { desc = "Split line and enter Insert mode", remap = true })

      vim.keymap.set("i", "<BS>", "<Left>", { desc = "Cursor left" })

      vim.keymap.set("c", "<BS>", "<Left>", { desc = "Cursor left" })
      vim.keymap.set("c", "<C-H>", "<BS>", { desc = "Delete character before cursor" })
      vim.keymap.set("c", "<C-L>", "<Right>", { desc = "Cursor right" })

      vim.keymap.set("c", "<C-A>", "<Home>", { desc = "Cursor to start of command line" })

      vim.keymap.set("c", "<C-K>", "<Up>", { desc = "Previous command-line history entry" })
      vim.keymap.set("c", "<C-J>", "<Down>", { desc = "Next command-line history entry" })

      vim.keymap.set("n", "q", "ge", { desc = "Backward to end of word", remap = true })
      vim.keymap.set("v", "q", "ge", { desc = "Backward to end of word", remap = true })
      vim.keymap.set("o", "q", "ge", { desc = "Backward to end of word", remap = true })
      vim.keymap.set("n", "Q", "gE", { desc = "Backward to end of WORD", remap = true })
      vim.keymap.set("v", "Q", "gE", { desc = "Backward to end of WORD", remap = true })
      vim.keymap.set("o", "Q", "gE", { desc = "Backward to end of WORD", remap = true })

      vim.keymap.set("n", "<Tab>", "q", { desc = "Start or stop recording" })
      vim.keymap.set("n", "<Tab><Tab>", "qq", { desc = "Record into register q" })
      vim.keymap.set("v", "<Tab>", "q", { desc = "Start or stop recording" })
      vim.keymap.set("v", "<Tab><Tab>", "qq", { desc = "Record into register q" })

      vim.keymap.set("n", "<C-Q>", "@q", { desc = "Execute register q" })
      vim.keymap.set("v", "<C-Q>", "@q", { desc = "Execute register q" })

      vim.keymap.set("n", "U", "<C-R>", { desc = "Redo" })
      vim.keymap.set("n", "<C-R>", "U", { desc = "Undo all latest changes on one line" })

      vim.keymap.set("n", "&", M.cmd("&&"), { desc = "Repeat last substitute with same flags", silent = true })
      vim.keymap.set("x", "&", M.cmd("&&"), { desc = "Repeat last substitute with same flags", silent = true })

      vim.keymap.set("n", "<Leader>o", M.cmd("nohlsearch"), { desc = "Stop search highlighting", silent = true })

      vim.keymap.set(
        "n",
        "<Leader>E",
        M.cmd("edit!"),
        { desc = "Edit the current file, discarding changes", silent = true }
      )
      vim.keymap.set(
        "n",
        "<Leader><Leader>e",
        M.cmd("edit!"),
        { desc = "Edit the current file, discarding changes", silent = true }
      )

      vim.keymap.set("n", "<Leader>s", M.cmd("update"), { desc = "Write only if modified", silent = true })
      vim.keymap.set("n", "<Leader>S", M.cmd("write!"), { desc = "Write current file", silent = true })
      vim.keymap.set("n", "<Leader><Leader>s", M.cmd("write!"), { desc = "Write current file", silent = true })

      vim.keymap.set("n", "<Leader>=", ":<C-U>put =", { desc = "Put from expression register" })

      -- TODO: This is only mapped since M is needed for a plugin.
      vim.keymap.set("n", "<C-G>", "M", { desc = "To Middle line of window" })

      M.system_clipboard_mappings("+", true)

      vim.keymap.set("n", "yoP", function()
        local register = vim.g.mapped_system_clipboard == "+" and "*" or "+"
        M.system_clipboard_mappings(register, false)
      end, { desc = "Toggle system clipboard register", silent = true })

      vim.keymap.set("n", "yom", function()
        if vim.opt.colorcolumn == "" then
          vim.opt.colorcolumn = "81"
        else
          vim.opt.colorcolumn = ""
        end
      end, { desc = "Toggle colorcolumn", silent = true })
    end,
    opts = {},
    config = function(_, opts)
      local MiniKeymap = require("mini.keymap")
      MiniKeymap.setup(opts)

      MiniKeymap.map_multistep("i", "<C-H>", { "minipairs_bs", M.multistep_fallback("<BS>") }, {
        desc = "Delete character before cursor",
      })

      MiniKeymap.map_multistep("i", "<C-J>", { "pmenu_next" }, {
        desc = "Select next completion item or split line",
      })

      MiniKeymap.map_multistep("i", "<C-N>", { "pmenu_next" }, {
        desc = "Select next completion item or split line",
      })

      MiniKeymap.map_multistep("i", "<C-P>", { "pmenu_prev" }, {
        desc = "Select next completion item or split line",
      })

      MiniKeymap.map_multistep("i", "<C-K>", { "pmenu_prev", M.multistep_fallback("<CR><Up><C-O>$") }, {
        desc = "Select previous completion item or split line in place",
      })
      MiniKeymap.map_multistep("i", "<C-L>", {
        "pmenu_accept",
        M.multistep_pmenu_accept_first,
        M.multistep_fallback("<Right>"),
      }, {
        desc = "Accept completion item or move cursor right",
      })
      MiniKeymap.map_multistep("i", "<Esc>", { M.multiste_pmenu_cancel }, {
        desc = "Cancel completion and exit Insert mode",
      })
    end,
  },
  {
    "nvim-mini/mini.ai",
    opts = {},
  },
  {
    "nvim-mini/mini.pairs",
    opts = {},
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      modes = {
        char = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "R",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },
  {
    "nvim-mini/mini.cmdline",
    init = function()
      -- TODO: Consider better bind for S-Esc.
      vim.keymap.set("n", "<S-Esc>", "q:", { desc = "Open command-line window" })
      local command_line_local_mappings = vim.api.nvim_create_augroup("command-line-local-mappings", { clear = true })
      vim.api.nvim_create_autocmd("CmdwinEnter", {
        group = command_line_local_mappings,
        pattern = "*",
        callback = function()
          vim.keymap.set("n", "<S-Esc>", M.cmd("q"), { desc = "Quit the current window", silent = true })
          vim.keymap.set("v", "<S-Esc>", M.cmd("q"), { desc = "Quit the current window", silent = true })
        end,
      })
      vim.api.nvim_create_autocmd("CmdwinLeave", {
        group = command_line_local_mappings,
        pattern = "*",
        callback = function()
          vim.keymap.set("n", "<S-Esc>", "q:", { desc = "Open command-line window" })
          vim.keymap.set("v", "<S-Esc>", "q:", { desc = "Open command-line window" })
        end,
      })

      vim.keymap.set("n", "<Leader>:", "q:", { desc = "Open command-line window" })
      vim.keymap.set("v", "<Leader>:", "q:", { desc = "Open command-line window" })
      vim.keymap.set("n", "<Leader><Leader>;", "q:", { desc = "Open command-line window" })
      vim.keymap.set("v", "<Leader><Leader>;", "q:", { desc = "Open command-line window" })
      vim.keymap.set("n", "<Leader>/", "q/", { desc = "Open search command-line window" })
      vim.keymap.set("v", "<Leader>/", "q/", { desc = "Open search command-line window" })
      vim.keymap.set("n", "<Leader>?", "q?", { desc = "Open backward search command-line window" })
      vim.keymap.set("v", "<Leader>?", "q?", { desc = "Open backward search command-line window" })
      vim.keymap.set("n", "<Leader><Leader>/", "q?", { desc = "Open backward search command-line window" })
      vim.keymap.set("v", "<Leader><Leader>/", "q?", { desc = "Open backward search command-line window" })
    end,
    opts = {
      autocomplete = {
        enable = false,
      },
    },
  },
  {
    "nvim-mini/mini.surround",
    opts = {},
  },
  {
    "nvim-mini/mini.completion",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "snacks_picker_input",
        callback = function()
          vim.b.minicompletion_disable = true
        end,
      })
    end,
    opts = {},
  },
  {
    "gbprod/cutlass.nvim",
    opts = {
      cut_key = "m",
    },
  },
  {
    "gbprod/substitute.nvim",
    opts = {},
    keys = {
      {
        ":",
        function()
          require("substitute").operator()
        end,
      },
      {
        "::",
        function()
          require("substitute").line()
        end,
      },
    },
  },
}

---@param register string The register to bind the mappings to
---@param quiet boolean Whether to show a notification
function M.system_clipboard_mappings(register, quiet)
  vim.keymap.set("n", "<Leader>c", '"' .. register .. "y", { desc = "Yank to system clipboard" })
  vim.keymap.set("v", "<Leader>c", '"' .. register .. "y", { desc = "Yank to system clipboard" })
  vim.keymap.set("n", "<Leader>C", '"' .. register .. "Y", { desc = "Yank to end of line to system clipboard" })
  vim.keymap.set("n", "<Leader><Leader>c", '"' .. register .. "Y", { desc = "Yank to end of line to system clipboard" })
  vim.keymap.set("n", "<Leader>cc", '"' .. register .. "yy", { desc = "Yank line to system clipboard" })

  vim.keymap.set("n", "<Leader>m", '"' .. register .. "d", { desc = "Delete to system clipboard" })
  vim.keymap.set("v", "<Leader>m", '"' .. register .. "d", { desc = "Delete to system clipboard" })
  vim.keymap.set("n", "<Leader>M", '"' .. register .. "D", { desc = "Delete to end of line to system clipboard" })
  vim.keymap.set(
    "n",
    "<Leader><Leader>m",
    '"' .. register .. "D",
    { desc = "Delete to end of line to system clipboard" }
  )
  vim.keymap.set("n", "<Leader>mm", '"' .. register .. "dd", { desc = "Delete line to system clipboard" })

  vim.keymap.set("n", "<Leader>p", '"' .. register .. "p", { desc = "Put after from system clipboard" })
  vim.keymap.set("n", "<Leader>P", '"' .. register .. "P", { desc = "Put before from system clipboard" })
  vim.keymap.set("n", "<Leader><Leader>p", '"' .. register .. "P", { desc = "Put before from system clipboard" })

  -- Use easyclip substitution with the system clipboard.
  -- TODO: Depends on the easyclip plugin.
  vim.keymap.set("v", "<C-;>", '"' .. register .. ":", { desc = "Substitute with system clipboard", remap = true })
  vim.keymap.set("n", "<C-;>", '"' .. register .. ":", { desc = "Substitute with system clipboard", remap = true })
  vim.keymap.set(
    "n",
    "<C-;><C-;>",
    '"' .. register .. "::",
    { desc = "Substitute line with system clipboard", remap = true }
  )

  vim.g.mapped_system_clipboard = register

  if not quiet then
    vim.notify("Setting system register to " .. register)
  end
end

---@param command string Command to run with vim.cmd
function M.cmd(command)
  return function()
    vim.cmd(command)
  end
end

function M.multistep_fallback(keys)
  return {
    condition = function()
      return true
    end,
    action = function()
      return keys
    end,
  }
end

M.multiste_pmenu_cancel = {
  condition = function()
    return vim.fn.pumvisible() == 1
  end,
  action = function()
    return "<C-e><Esc>"
  end,
}

M.multistep_pmenu_accept_first = {
  condition = function()
    return vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected == -1
  end,
  action = function()
    return "<C-n><C-y>"
  end,
}

return M.spec
