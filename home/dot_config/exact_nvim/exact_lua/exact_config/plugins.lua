return {
  { "nvim-mini/mini.nvim", version = "*" },
  { "mrjones2014/smart-splits.nvim", lazy = false },
  { "neovim/nvim-lspconfig" },
  { "gbprod/cutlass.nvim", opts = {
    cut_key = "m",
  } },
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = true,
    lazy = true,
    cmd = {
      "KittyScrollbackGenerateKittens",
      "KittyScrollbackCheckHealth",
      "KittyScrollbackGenerateCommandLineEditing",
    },
    event = { "User KittyScrollbackLaunch" },
    -- version = '*', -- latest stable version, may have breaking changes if major version changed
    -- version = '^6.0.0', -- pin major version, include fixes and features that do not have breaking changes
    config = function()
      require("kitty-scrollback").setup()
    end,
  },
}
