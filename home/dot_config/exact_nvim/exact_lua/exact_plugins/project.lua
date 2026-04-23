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
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
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
          require("snacks").picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<leader>b",
        function()
          require("snacks").picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>a",
        function()
          require("snacks").picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>f:",
        function()
          require("snacks").picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>fn",
        function()
          require("snacks").picker.notifications()
        end,
        desc = "Notification History",
      },
      {
        "<leader>i",
        function()
          local explorer = require("snacks").explorer.reveal()
          if explorer then
            explorer:focus()
          end
        end,
        desc = "Reveal In File Explorer",
      },
      {
        "<leader>I",
        function()
          for _, picker in ipairs(require("snacks").picker.get({ source = "explorer" })) do
            picker:close()
          end
        end,
        desc = "Close File Explorer",
      },
      -- find
      {
        "<leader>fb",
        function()
          require("snacks").picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fc",
        function()
          require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>ff",
        function()
          require("snacks").picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          require("snacks").picker.git_files()
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>fp",
        function()
          require("snacks").picker.projects()
        end,
        desc = "Projects",
      },
      {
        "<leader>fr",
        function()
          require("snacks").picker.recent()
        end,
        desc = "Recent",
      },
      -- git
      {
        "<leader>gb",
        function()
          require("snacks").picker.git_branches()
        end,
        desc = "Git Branches",
      },
      {
        "<leader>gl",
        function()
          require("snacks").picker.git_log()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gL",
        function()
          require("snacks").picker.git_log_line()
        end,
        desc = "Git Log Line",
      },
      {
        "<leader>gs",
        function()
          require("snacks").picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>gS",
        function()
          require("snacks").picker.git_stash()
        end,
        desc = "Git Stash",
      },
      {
        "<leader>gd",
        function()
          require("snacks").picker.git_diff()
        end,
        desc = "Git Diff (Hunks)",
      },
      {
        "<leader>gf",
        function()
          require("snacks").picker.git_log_file()
        end,
        desc = "Git Log File",
      },
      -- gh
      {
        "<leader>gi",
        function()
          require("snacks").picker.gh_issue()
        end,
        desc = "GitHub Issues (open)",
      },
      {
        "<leader>gI",
        function()
          require("snacks").picker.gh_issue({ state = "all" })
        end,
        desc = "GitHub Issues (all)",
      },
      {
        "<leader>gp",
        function()
          require("snacks").picker.gh_pr()
        end,
        desc = "GitHub Pull Requests (open)",
      },
      {
        "<leader>gP",
        function()
          require("snacks").picker.gh_pr({ state = "all" })
        end,
        desc = "GitHub Pull Requests (all)",
      },
      -- Grep
      {
        "<leader>sb",
        function()
          require("snacks").picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>sB",
        function()
          require("snacks").picker.grep_buffers()
        end,
        desc = "Grep Open Buffers",
      },
      {
        "<leader>sg",
        function()
          require("snacks").picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sw",
        function()
          require("snacks").picker.grep_word()
        end,
        desc = "Visual selection or word",
        mode = { "n", "x" },
      },
      -- search
      {
        '<leader>s"',
        function()
          require("snacks").picker.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>s/",
        function()
          require("snacks").picker.search_history()
        end,
        desc = "Search History",
      },
      {
        "<leader>sa",
        function()
          require("snacks").picker.autocmds()
        end,
        desc = "Autocmds",
      },
      {
        "<leader>sb",
        function()
          require("snacks").picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>sc",
        function()
          require("snacks").picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>sC",
        function()
          require("snacks").picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>sd",
        function()
          require("snacks").picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sD",
        function()
          require("snacks").picker.diagnostics_buffer()
        end,
        desc = "Buffer Diagnostics",
      },
      {
        "<leader>sh",
        function()
          require("snacks").picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sH",
        function()
          require("snacks").picker.highlights()
        end,
        desc = "Highlights",
      },
      {
        "<leader>si",
        function()
          require("snacks").picker.icons()
        end,
        desc = "Icons",
      },
      {
        "<leader>sj",
        function()
          require("snacks").picker.jumps()
        end,
        desc = "Jumps",
      },
      {
        "<leader>sk",
        function()
          require("snacks").picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sl",
        function()
          require("snacks").picker.loclist()
        end,
        desc = "Location List",
      },
      {
        "<leader>sm",
        function()
          require("snacks").picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sM",
        function()
          require("snacks").picker.man()
        end,
        desc = "Man Pages",
      },
      {
        "<leader>sp",
        function()
          require("snacks").picker.lazy()
        end,
        desc = "Search for Plugin Spec",
      },
      {
        "<leader>sq",
        function()
          require("snacks").picker.qflist()
        end,
        desc = "Quickfix List",
      },
      {
        "<leader>sR",
        function()
          require("snacks").picker.resume()
        end,
        desc = "Resume",
      },
      {
        "<leader>su",
        function()
          require("snacks").picker.undo()
        end,
        desc = "Undo History",
      },
      {
        "<leader>uC",
        function()
          require("snacks").picker.colorschemes()
        end,
        desc = "Colorschemes",
      },
      -- LSP
      {
        "gd",
        function()
          require("snacks").picker.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "gD",
        function()
          require("snacks").picker.lsp_declarations()
        end,
        desc = "Goto Declaration",
      },
      {
        "gr",
        function()
          require("snacks").picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
      },
      {
        "gI",
        function()
          require("snacks").picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
      },
      {
        "gy",
        function()
          require("snacks").picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "gai",
        function()
          require("snacks").picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
      },
      {
        "gao",
        function()
          require("snacks").picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
      },
      {
        "<leader>ss",
        function()
          require("snacks").picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>sS",
        function()
          require("snacks").picker.lsp_workspace_symbols()
        end,
        desc = "LSP Workspace Symbols",
      },
    },
  },
}

return M.spec
