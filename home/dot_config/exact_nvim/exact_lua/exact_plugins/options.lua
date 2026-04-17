---@module "lazy.types"
---@type LazySpec
return {
  {
    "nvim-mini/mini.basics",
    priority = 1000,
    init = function()
      -- Hide buffers instead of closing them.
      vim.opt.hidden = true

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
}
