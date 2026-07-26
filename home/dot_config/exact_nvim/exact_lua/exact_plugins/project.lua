local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "nvim-mini/mini.files",
    opts = {},
  },
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-mini/mini.icons" },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        win = {
          input = {
            keys = {
              -- UPSTREAM: The default bind for C-c only closes from insert mode.
              ["<C-c>"] = { "close", mode = { "n", "i" } },
              ["<C-CR>"] = { "qflist", mode = { "i", "n" } },
              ["<c-p>"] = { "history_back", mode = { "i", "n" } },
              ["<c-n>"] = { "history_forward", mode = { "i", "n" } },
              ["<c-g>"] = false,
              ["<c-g>g"] = { "toggle_live", mode = { "i", "n" }, desc = "Toggle Live" },
              ["<a-d>"] = false,
              ["<a-f>"] = false,
              ["<a-h>"] = false,
              ["<a-i>"] = false,
              ["<a-r>"] = false,
              ["<a-m>"] = false,
              ["<a-p>"] = false,
              ["<a-w>"] = false,
              ["<c-g>d"] = { "inspect", mode = { "n", "i" }, desc = "Inspect" },
              ["<c-g>f"] = { "toggle_follow", mode = { "i", "n" }, desc = "Toggle Follow" },
              ["<c-g>h"] = { "toggle_hidden", mode = { "i", "n" }, desc = "Toggle Hidden" },
              ["<c-g>i"] = { "toggle_ignored", mode = { "i", "n" }, desc = "Toggle Ignored" },
              ["<c-g>r"] = { "toggle_regex", mode = { "i", "n" }, desc = "Toggle Regex" },
              ["<c-g>m"] = { "toggle_maximize", mode = { "i", "n" }, desc = "Toggle Maximize" },
              ["<c-g>p"] = { "toggle_preview", mode = { "i", "n" }, desc = "Toggle Preview" },
              ["<c-g>w"] = { "cycle_win", mode = { "i", "n" }, desc = "Cycle Window" },
            },
          },
          list = {
            keys = {
              ["<C-CR>"] = "qflist",
              ["<c-p>"] = "history_back",
              ["<c-n>"] = "history_forward",
              ["<c-g>"] = false,
              ["<c-g>g"] = { "print_path", desc = "Print Path" },
              ["<a-d>"] = false,
              ["<a-f>"] = false,
              ["<a-h>"] = false,
              ["<a-i>"] = false,
              ["<a-m>"] = false,
              ["<a-p>"] = false,
              ["<a-w>"] = false,
              ["<c-g>d"] = { "inspect", desc = "Inspect" },
              ["<c-g>f"] = { "toggle_follow", desc = "Toggle Follow" },
              ["<c-g>h"] = { "toggle_hidden", desc = "Toggle Hidden" },
              ["<c-g>i"] = { "toggle_ignored", desc = "Toggle Ignored" },
              ["<c-g>m"] = { "toggle_maximize", desc = "Toggle Maximize" },
              ["<c-g>p"] = { "toggle_preview", desc = "Toggle Preview" },
              ["<c-g>w"] = { "cycle_win", desc = "Cycle Window" },
            },
          },
          preview = {
            keys = {
              ["<a-w>"] = false,
              ["<c-g>w"] = { "cycle_win", desc = "Cycle Window" },
            },
          },
        },
        sources = {
          explorer = {
            win = {
              input = {
                keys = {
                  ["<Esc>"] = false,
                },
              },
              list = {
                keys = {
                  ["<Esc>"] = false,
                },
              },
            },
          },
        },
      },
      explorer = {},
    },
    keys = {
      -- Top Pickers & Explorer
      {
        "<leader>e",
        function()
          -- TODO: Search hidden files?
          Snacks.picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<leader>b",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>a",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>f:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>fn",
        function()
          Snacks.picker.notifications()
        end,
        desc = "Notification History",
      },
      {
        "<leader>i",
        function()
          local explorer = Snacks.explorer.reveal()
          if explorer then
            explorer:focus()
          end
        end,
        desc = "Reveal In File Explorer",
      },
      {
        "<leader>I",
        function()
          for _, picker in ipairs(Snacks.picker.get({ source = "explorer" })) do
            picker:close()
          end
        end,
        desc = "Close File Explorer",
      },
      -- find
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Projects",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent",
      },
      -- git
      {
        "<leader>gb",
        function()
          Snacks.picker.git_branches()
        end,
        desc = "Git Branches",
      },
      {
        "<leader>gl",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gL",
        function()
          Snacks.picker.git_log_line()
        end,
        desc = "Git Log Line",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>gS",
        function()
          Snacks.picker.git_stash()
        end,
        desc = "Git Stash",
      },
      {
        "<leader>gd",
        function()
          Snacks.picker.git_diff()
        end,
        desc = "Git Diff (Hunks)",
      },
      {
        "<leader>gf",
        function()
          Snacks.picker.git_log_file()
        end,
        desc = "Git Log File",
      },
      -- gh
      {
        "<leader>gi",
        function()
          Snacks.picker.gh_issue()
        end,
        desc = "GitHub Issues (open)",
      },
      {
        "<leader>gI",
        function()
          Snacks.picker.gh_issue({ state = "all" })
        end,
        desc = "GitHub Issues (all)",
      },
      {
        "<leader>gp",
        function()
          Snacks.picker.gh_pr()
        end,
        desc = "GitHub Pull Requests (open)",
      },
      {
        "<leader>gP",
        function()
          Snacks.picker.gh_pr({ state = "all" })
        end,
        desc = "GitHub Pull Requests (all)",
      },
      -- Grep
      {
        "<leader>yb",
        function()
          Snacks.picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>yB",
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = "Grep Open Buffers",
      },
      {
        "<leader>yg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>yw",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Visual selection or word",
        mode = { "n", "x" },
      },
      -- search
      {
        '<leader>y"',
        function()
          Snacks.picker.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>y/",
        function()
          Snacks.picker.search_history()
        end,
        desc = "Search History",
      },
      {
        "<leader>ya",
        function()
          Snacks.picker.autocmds()
        end,
        desc = "Autocmds",
      },
      {
        "<leader>yb",
        function()
          Snacks.picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>yc",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>yC",
        function()
          Snacks.picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>yd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>yD",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Buffer Diagnostics",
      },
      {
        "<leader>yh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>yH",
        function()
          Snacks.picker.highlights()
        end,
        desc = "Highlights",
      },
      {
        "<leader>yi",
        function()
          Snacks.picker.icons()
        end,
        desc = "Icons",
      },
      {
        "<leader>yj",
        function()
          Snacks.picker.jumps()
        end,
        desc = "Jumps",
      },
      {
        "<leader>yk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>yl",
        function()
          Snacks.picker.loclist()
        end,
        desc = "Location List",
      },
      {
        "<leader>ym",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>yM",
        function()
          Snacks.picker.man()
        end,
        desc = "Man Pages",
      },
      {
        "<leader>yp",
        function()
          Snacks.picker.lazy()
        end,
        desc = "Search for Plugin Spec",
      },
      {
        "<leader>yq",
        function()
          Snacks.picker.qflist()
        end,
        desc = "Quickfix List",
      },
      {
        "<leader>yR",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume",
      },
      {
        "<leader>yu",
        function()
          Snacks.picker.undo()
        end,
        desc = "Undo History",
      },
      {
        "<leader>uC",
        function()
          Snacks.picker.colorschemes()
        end,
        desc = "Colorschemes",
      },
      -- LSP
      {
        "gd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "gD",
        function()
          Snacks.picker.lsp_declarations()
        end,
        desc = "Goto Declaration",
      },
      {
        "gr",
        function()
          Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
      },
      {
        "gI",
        function()
          Snacks.picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
      },
      {
        "gy",
        function()
          Snacks.picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "gai",
        function()
          Snacks.picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
      },
      {
        "gao",
        function()
          Snacks.picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
      },
      {
        "<leader>ys",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>yS",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "LSP Workspace Symbols",
      },
    },
  },
}

return M.spec
