local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "mrjones2014/smart-splits.nvim",
    ---@module "smart-splits"
    ---@type SmartSplitsConfig
    opts = { ---@diagnostic disable-line:missing-fields
    },
    init = function()
      vim.keymap.set("n", "<Leader>h", M.cmd("leftabove vsplit"), { desc = "Split current window left", silent = true })
      vim.keymap.set(
        "n",
        "<Leader>l",
        M.cmd("rightbelow vsplit"),
        { desc = "Split current window right", silent = true }
      )
      vim.keymap.set("n", "<Leader>k", M.cmd("leftabove split"), { desc = "Split current window above", silent = true })
      vim.keymap.set(
        "n",
        "<Leader>j",
        M.cmd("rightbelow split"),
        { desc = "Split current window below", silent = true }
      )

      vim.keymap.set("n", "<Leader>H", M.cmd("topleft vsplit"), { desc = "Split at left edge", silent = true })
      vim.keymap.set("n", "<Leader><Leader>h", M.cmd("topleft vsplit"), { desc = "Split at left edge", silent = true })
      vim.keymap.set("n", "<Leader>L", M.cmd("botright vsplit"), { desc = "Split at right edge", silent = true })
      vim.keymap.set(
        "n",
        "<Leader><Leader>l",
        M.cmd("botright vsplit"),
        { desc = "Split at right edge", silent = true }
      )
      vim.keymap.set("n", "<Leader>K", M.cmd("topleft split"), { desc = "Split at top edge", silent = true })
      vim.keymap.set("n", "<Leader><Leader>k", M.cmd("topleft split"), { desc = "Split at top edge", silent = true })
      vim.keymap.set("n", "<Leader>J", M.cmd("botright split"), { desc = "Split at bottom edge", silent = true })
      vim.keymap.set(
        "n",
        "<Leader><Leader>j",
        M.cmd("botright split"),
        { desc = "Split at bottom edge", silent = true }
      )

      vim.keymap.set("n", "<Leader><Tab>", M.cmd("tabnew"), { desc = "Open a new tab page", silent = true })
      vim.keymap.set("n", "<Leader><S-Tab>", M.cmd("tabclose"), { desc = "Close the current tab page", silent = true })
      vim.keymap.set(
        "n",
        "<Leader><Leader><Tab>",
        M.cmd("tabclose"),
        { desc = "Close the current tab page", silent = true }
      )

      vim.keymap.set("n", "<C-,>", "gT", { desc = "Go to the previous tab page" })
      vim.keymap.set("n", "<C-.>", "gt", { desc = "Go to the next tab page" })

      vim.keymap.set("n", "<Leader>n", M.cmd("enew"), { desc = "Edit a new, unnamed buffer", silent = true })

      vim.keymap.set("n", "<Leader><CR>", M.cmd("quit"), { desc = "Quit the current window", silent = true })
      vim.keymap.set("v", "<Leader><CR>", M.cmd("quit"), { desc = "Quit the current window", silent = true })

      vim.keymap.set("n", "<Leader>q", M.cmd("quitall"), { desc = "Exit Vim", silent = true })
      vim.keymap.set("v", "<Leader>q", M.cmd("quitall"), { desc = "Exit Vim", silent = true })
      vim.keymap.set("n", "<Leader>Q", M.cmd("quitall!"), { desc = "Exit Vim without saving changes", silent = true })
      vim.keymap.set("v", "<Leader>Q", M.cmd("quitall!"), { desc = "Exit Vim without saving changes", silent = true })
      vim.keymap.set(
        "n",
        "<Leader><Leader>q",
        M.cmd("quitall!"),
        { desc = "Exit Vim without saving changes", silent = true }
      )
      vim.keymap.set(
        "v",
        "<Leader><Leader>q",
        M.cmd("quitall!"),
        { desc = "Exit Vim without saving changes", silent = true }
      )

      -- TODO: Does this still make sense?
      vim.keymap.set(
        "n",
        "<Leader>xz",
        M.cmd("pclose"),
        { desc = "Close any Preview window currently open", silent = true }
      )
    end,
    config = function(_, opts)
      local SmartSplits = require("smart-splits")
      SmartSplits.setup(opts)

      -- resize splits
      vim.keymap.set("n", "<A-h>", SmartSplits.resize_left)
      vim.keymap.set("n", "<A-j>", SmartSplits.resize_down)
      vim.keymap.set("n", "<A-k>", SmartSplits.resize_up)
      vim.keymap.set("n", "<A-l>", SmartSplits.resize_right)
      -- swapping splits
      vim.keymap.set("n", "<A-H>", SmartSplits.swap_buf_left)
      vim.keymap.set("n", "<A-J>", SmartSplits.swap_buf_down)
      vim.keymap.set("n", "<A-K>", SmartSplits.swap_buf_up)
      vim.keymap.set("n", "<A-L>", SmartSplits.swap_buf_right)
      -- moving between splits
      vim.keymap.set("n", "<C-h>", SmartSplits.move_cursor_left)
      vim.keymap.set("n", "<C-j>", SmartSplits.move_cursor_down)
      vim.keymap.set("n", "<C-k>", SmartSplits.move_cursor_up)
      vim.keymap.set("n", "<C-l>", SmartSplits.move_cursor_right)
    end,
  },
  {
    "nvim-mini/mini.bufremove",
    opts = {},
    keys = {
      {
        "<leader>w",
        function()
          require("mini.bufremove").delete(0, false)
        end,
        desc = "Delete Buffer",
      },
      {
        "<leader>W",
        function()
          require("mini.bufremove").delete(0, true)
        end,
        desc = "Force Delete Buffer",
      },
    },
  },
  {
    "mikesmithgh/kitty-scrollback.nvim",
    ---@module "kitty-scrollback"
    ---@type KsbOpts
    opts = {},
    cmd = {
      "KittyScrollbackGenerateKittens",
      "KittyScrollbackCheckHealth",
      "KittyScrollbackGenerateCommandLineEditing",
    },
    event = { "User KittyScrollbackLaunch" },
  },
}

---@param command string Command to run with vim.cmd
function M.cmd(command)
  return function()
    vim.cmd(command)
  end
end

return M.spec
