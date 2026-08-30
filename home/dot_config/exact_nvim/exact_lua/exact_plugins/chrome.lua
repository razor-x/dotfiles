local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    ---@module "catppuccin"
    ---@type CatppuccinOptions
    opts = {
      auto_integrations = true,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "nvim-mini/mini.icons",
    opts = {},
    config = function(_, opts)
      require("mini.icons").setup(opts)
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
  {
    "nvim-mini/mini.statuscolumn",
    opts = {},
  },
  {
    "dimtion/guttermarks.nvim",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "FileType" },
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
  {
    "catgoose/nvim-colorizer.lua",
    ---@module "colorizer.config"
    ---@type colorizer.SetupOptions
    opts = { ---@diagnostic disable-line:missing-fields
    },
    event = "BufReadPre",
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    opts = {
      options = {
        theme = "catppuccin-nvim",
        component_separators = "",
        section_separators = { left = "", right = "" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    event = "VeryLazy",
    ---@module "which-key"
    ---@type wk.Opts
    opts = {
      delay = function(ctx)
        if ctx.keys == "z=" then
          return 0
        end
        return ctx.plugin and 0 or 500
      end,
      spec = {
        { "<c-e>", group = "mark" },
        { "<c-f>", group = "fold" },
        { "<c-g>", group = "picker", mode = "i" },
        { "zA", hidden = true },
        { "zC", hidden = true },
        { "zD", hidden = true },
        { "zE", hidden = true },
        { "zF", hidden = true },
        { "zM", hidden = true },
        { "zN", hidden = true },
        { "zO", hidden = true },
        { "zR", hidden = true },
        { "zX", hidden = true },
        { "za", hidden = true },
        { "zc", hidden = true },
        { "zd", hidden = true },
        { "zf", hidden = true },
        { "zi", hidden = true },
        { "zj", hidden = true },
        { "zk", hidden = true },
        { "zm", hidden = true },
        { "zn", hidden = true },
        { "zo", hidden = true },
        { "zr", hidden = true },
        { "zv", hidden = true },
        { "zx", hidden = true },
      },
      triggers = {
        { "<auto>", mode = "nixsotc" },
        { "<c-e>", mode = "n" },
        { "<c-f>", mode = "n" },
        { "<c-g>", mode = "i" },
      },
    },
    config = function(_, opts)
      WhichKey = require("which-key")
      WhichKey.setup(opts)
    end,
    keys = {
      {
        "<leader>?",
        function()
          WhichKey.show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
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
