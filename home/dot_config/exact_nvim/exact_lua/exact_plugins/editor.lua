local M = {}
local toggles = require("config.toggles")

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

      -- Highlight misspelled words using Neovim's built-in spell checker.
      vim.opt.spell = true

      -- Set nonzero scrolloff.
      vim.opt.scrolloff = 5

      -- Set indentation preferences.
      vim.opt.tabstop = 2
      vim.opt.softtabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.autoindent = true

      -- Use Tree-sitter folds, but start with all folds open.
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
      vim.opt.foldenable = true

      -- Enable EditorConfig.
      vim.g.editorconfig = true

      vim.api.nvim_create_user_command("CopyMessages", function()
        vim.fn.setreg("+", vim.fn.execute("messages"))
        vim.notify("Copied message history to clipboard")
      end, { desc = "Copy message history to clipboard" })

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

        -- Toggle mappings are defined below to provide matching global and local forms.
        option_toggle_prefix = "",

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

      vim.keymap.set({ "n", "x", "o" }, "<F7>", "[", { desc = "Bracket previous prefix", remap = true })
      vim.keymap.set({ "n", "x", "o" }, "<F8>", "]", { desc = "Bracket next prefix", remap = true })

      vim.keymap.set("i", "<CR>", "<Esc>", { desc = "Exit Insert mode" })

      vim.keymap.set("n", "<CR>", ":", { desc = "Enter Command-line mode" })
      vim.keymap.set("v", "<CR>", ":", { desc = "Enter Command-line mode" })

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
      vim.keymap.set("n", "<C-B>", "<C-E>", { desc = "Scroll window down" })

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
      vim.keymap.set("n", "<Leader>z", function()
        require("which-key").show({ keys = "z=" })
      end, { desc = "Suggest spelling corrections" })

      M.system_clipboard_mappings("+", true)

      toggles.map_toggle("b", {
        desc = "background",
        global = function()
          vim.o.background = vim.o.background == "dark" and "light" or "dark"
        end,
      })
      toggles.map_toggle("c", toggles.window_option_toggle("cursorline"))
      toggles.map_toggle("C", toggles.window_option_toggle("cursorcolumn"))
      toggles.map_toggle("d", {
        desc = "diagnostics",
        global = function()
          vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        end,
        local_scope = "buffer",
        local_toggle = function()
          local filter = { bufnr = 0 }
          vim.diagnostic.enable(not vim.diagnostic.is_enabled(filter), filter)
        end,
      })
      toggles.map_toggle("h", {
        desc = "search highlighting",
        global = function()
          vim.v.hlsearch = vim.v.hlsearch == 0 and 1 or 0
        end,
      })
      toggles.map_toggle("I", {
        desc = "ignore case",
        global = function()
          vim.o.ignorecase = not vim.o.ignorecase
        end,
      })
      toggles.map_toggle("l", toggles.window_option_toggle("list"))
      toggles.map_toggle("n", toggles.window_option_toggle("number"))
      toggles.map_toggle("r", toggles.window_option_toggle("relativenumber"))
      toggles.map_toggle("s", toggles.window_option_toggle("spell"))
      toggles.map_toggle("w", toggles.window_option_toggle("wrap"))

      toggles.map_toggle("P", {
        desc = "system clipboard register",
        global = function()
          local register = vim.g.mapped_system_clipboard == "+" and "*" or "+"
          M.system_clipboard_mappings(register, false)
        end,
      })

      toggles.map_toggle("m", toggles.window_option_toggle("colorcolumn", "81", ""))
    end,
    opts = {},
    config = function(_, opts)
      require("mini.keymap").setup(opts)

      MiniKeymap.map_multistep("i", "<C-H>", { "minipairs_bs", M.multistep_fallback("<BS>") }, {
        desc = "Delete character before cursor",
      })

      MiniKeymap.map_multistep("i", "<C-J>", { "pmenu_next", "minisnippets_next" }, {
        desc = "Select next completion item, jump to next snippet tabstop, or split line",
      })

      MiniKeymap.map_multistep("i", "<C-N>", { "pmenu_next" }, {
        desc = "Select next completion item or split line",
      })

      MiniKeymap.map_multistep("i", "<C-P>", { "pmenu_prev" }, {
        desc = "Select next completion item or split line",
      })

      vim.keymap.set("i", "<C-F>", "<C-X><C-F>", { desc = "Complete file path" })

      MiniKeymap.map_multistep(
        "i",
        "<C-K>",
        { "pmenu_prev", "minisnippets_prev", M.multistep_fallback("<CR><Up><C-O>$") },
        {
          desc = "Select previous completion item, jump to previous tabstop, or split line in place",
        }
      )
      MiniKeymap.map_multistep("i", "<C-L>", {
        "pmenu_accept",
        M.multistep_pmenu_accept_first,
        "minisnippets_next",
        M.multistep_fallback("<Right>"),
      }, {
        desc = "Accept completion item, jump to next tabstop, or move cursor right",
      })
      MiniKeymap.map_multistep("i", "<Esc>", { M.multiste_pmenu_cancel }, {
        desc = "Cancel completion and exit Insert mode",
      })
    end,
  },
  {
    "nvim-mini/mini.cmdline",
    init = function()
      local MiniKeymap = require("mini.keymap")
      local function map_command_line_window(lhs, open_keys, desc)
        local command_line_type = open_keys:sub(2)
        local close_command_line_window = {
          condition = function()
            return vim.fn.getcmdwintype() == command_line_type
          end,
          action = function()
            return M.cmd("q")
          end,
        }
        local switch_command_line_window = {
          condition = function()
            return vim.fn.getcmdwintype() ~= ""
          end,
          action = function()
            return "<Cmd>q<CR>" .. open_keys
          end,
        }
        MiniKeymap.map_multistep(
          { "n", "v" },
          lhs,
          { close_command_line_window, switch_command_line_window, M.multistep_fallback(open_keys) },
          {
            desc = desc,
            silent = true,
          }
        )
      end

      -- TODO: Consider better bind for S-Esc.
      map_command_line_window("<S-Esc>", "q:", "Toggle command-line window")
      map_command_line_window("<Leader>:", "q:", "Toggle command-line window")
      map_command_line_window("<Leader><Leader>;", "q:", "Toggle command-line window")
      map_command_line_window("<Leader>/", "q/", "Toggle search command-line window")
      map_command_line_window("<Leader>?", "q?", "Toggle backward search command-line window")
      map_command_line_window("<Leader><Leader>/", "q?", "Toggle backward search command-line window")
    end,
    opts = {
      autocomplete = {
        enable = false,
      },
    },
  },
  {
    "nvim-mini/mini.snippets",
    dependencies = { "rafamadriz/friendly-snippets", "folke/snacks.nvim" },
    ---@module "mini.snippets"
    opts = function()
      local MiniSnippets = require("mini.snippets")
      return {
        snippets = { MiniSnippets.gen_loader.from_lang() },
        mappings = {
          expand = "",
          jump_next = "",
          jump_prev = "",
        },
      }
    end,
    config = function(_, opts)
      local MiniSnippets = require("mini.snippets")
      local Snacks = require("snacks")
      MiniSnippets.setup(opts)
      MiniSnippets.start_lsp_server()
      vim.keymap.set("i", "<C-Space>", function()
        MiniSnippets.expand({
          match = false,
          select = function(snippets, insert)
            Snacks.picker({
              title = "Snippets",
              layout = "vertical",
              format = "text",
              preview = "preview",
              items = vim.tbl_map(function(snippet)
                local body = type(snippet.body) == "string" and snippet.body or table.concat(snippet.body, "\n")
                return {
                  text = string.format(
                    "%s │ %s",
                    snippet.prefix or "<No prefix>",
                    snippet.desc or "<No description>"
                  ),
                  snippet = snippet,
                  preview = { text = body, ft = vim.bo.filetype },
                }
              end, snippets),
              confirm = function(picker, item)
                picker:close()
                vim.schedule(function()
                  insert(item.snippet)
                end)
              end,
            })
          end,
        })
      end, { desc = "Select snippet" })
    end,
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
    opts = {
      mappings = {
        force_twostep = "<C-E>",
        scroll_down = "<C-d>",
        scroll_up = "<C-u>",
      },
    },
  },
  {
    "mbbill/undotree",
    keys = {
      { "<Leader>u", "<Cmd>UndotreeShow<Bar>UndotreeFocus<CR>", desc = "Open or focus undo tree" },
      { "<Leader>U", "<Cmd>UndotreeToggle<CR>", desc = "Toggle undo tree" },
    },
  },
}

---@param register string The register to bind the mappings to
---@param quiet boolean Whether to show a notification
function M.system_clipboard_mappings(register, quiet)
  vim.keymap.set("n", "<leader>y", '"' .. register .. "y", { desc = "Yank to system clipboard" })
  vim.keymap.set("v", "<leader>y", '"' .. register .. "y", { desc = "Yank to system clipboard" })
  vim.keymap.set("n", "<leader>Y", '"' .. register .. "Y", { desc = "Yank to end of line to system clipboard" })
  vim.keymap.set("n", "<leader>yy", '"' .. register .. "yy", { desc = "Yank line to system clipboard" })

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
