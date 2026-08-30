local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "chrisgrieser/nvim-origami",
    event = "VeryLazy",
    init = function()
      vim.keymap.set("n", "<C-G>", "za", { desc = "Toggle fold under cursor" })
      for suffix, desc in pairs({
        A = "Toggle all folds under cursor",
        C = "Close all folds under cursor",
        M = "Close all folds",
        N = "Enable folding",
        O = "Open all folds under cursor",
        R = "Open all folds",
        X = "Reset folds",
        c = "Close fold under cursor",
        i = "Toggle folding",
        j = "Next fold",
        k = "Previous fold",
        m = "Fold more",
        n = "Disable folding",
        o = "Open fold under cursor",
        r = "Fold less",
        v = "Show cursor line",
        x = "Update folds",
      }) do
        vim.keymap.set("n", "<C-F>" .. suffix, "z" .. suffix, { desc = desc })
      end
    end,
    ---@module "origami"
    ---@type Origami.config
    opts = {
      foldKeymaps = { setup = true },
    },
  },
  {
    "dimtion/guttermarks.nvim",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "FileType" },
    init = function()
      vim.keymap.set("n", "<C-R>", "m", { desc = "Set mark" })
      vim.keymap.set("n", "<C-E>j", "`", { desc = "Jump to mark position" })
      vim.keymap.set("n", "<C-E>l", "'", { desc = "Jump to mark line" })
      vim.keymap.set("n", "<C-E>d", ":delmarks ", { desc = "Delete marks" })
      vim.keymap.set("n", "<C-E>D", "<Cmd>delmarks!<CR>", { desc = "Delete all local marks" })
    end,
    ---@module "guttermarks"
    ---@type guttermarks.Config
    opts = {
      local_mark = { highlight_group = "DiagnosticInfo" },
      global_mark = { highlight_group = "DiagnosticWarn" },
      excluded_filetypes = {},
    },
    keys = {
      {
        "<C-r>r",
        function()
          M.toggle_mark()
        end,
        desc = "Toggle local mark on current line",
      },
      {
        "<C-r><C-r>",
        function()
          M.toggle_mark()
        end,
        desc = "Toggle local mark on current line",
      },
      {
        "<C-r>R",
        function()
          M.toggle_mark(true)
        end,
        desc = "Toggle global mark on current line",
      },
      {
        "<C-e>q",
        function()
          require("guttermarks.actions").marks_to_quickfix()
          vim.cmd.copen()
        end,
        desc = "Send marks to quickfix",
      },
      {
        "<C-e>Q",
        function()
          require("guttermarks.actions").marks_to_quickfix({ special_mark = true })
          vim.cmd.copen()
        end,
        desc = "Send marks to quickfix including special marks",
      },
      {
        "<C-e>n",
        function()
          require("guttermarks.actions").next_buf_mark()
        end,
        desc = "Next mark in current buffer",
      },
      {
        "<C-e>p",
        function()
          require("guttermarks.actions").prev_buf_mark()
        end,
        desc = "Previous mark in current buffer",
      },
      {
        "]m",
        function()
          require("guttermarks.actions").next_buf_mark()
        end,
        desc = "Next mark in current buffer",
      },
      {
        "[m",
        function()
          require("guttermarks.actions").prev_buf_mark()
        end,
        desc = "Previous mark in current buffer",
      },
    },
  },
}

function M.toggle_mark(is_global)
  local bufnr = vim.api.nvim_get_current_buf()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  local used = {}

  for _, mark in ipairs(vim.fn.getmarklist(bufnr)) do
    local name = mark.mark:sub(2)
    if name:match("^[a-z]$") then
      if not is_global then
        used[name] = true
      end
      if mark.pos[2] == line then
        require("guttermarks.actions").delete_mark()
        return
      end
    end
  end

  for _, mark in ipairs(vim.fn.getmarklist()) do
    local name = mark.mark:sub(2)
    if name:match("^[A-Z]$") then
      if is_global then
        used[name] = true
      end
      if mark.pos[1] == bufnr and mark.pos[2] == line then
        require("guttermarks.actions").delete_mark()
        return
      end
    end
  end

  local first, last = is_global and "A" or "a", is_global and "Z" or "z"
  for byte = string.byte(first), string.byte(last) do
    local name = string.char(byte)
    if not used[name] then
      vim.api.nvim_buf_set_mark(bufnr, name, line, col, {})
      require("guttermarks").refresh()
      return
    end
  end

  vim.notify("No free " .. (is_global and "global" or "local") .. " marks", vim.log.levels.WARN)
end

return M.spec
