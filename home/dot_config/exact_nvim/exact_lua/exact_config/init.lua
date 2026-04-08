local bootstrap = require("config.bootstrap")
local dotfiles = require("config.dotfiles")
local editor = require("config.editor")
local plugins = require("config.plugins")

local Config = {}

Config.setup = function()
  bootstrap()

  -- editor.setup()

  vim.cmd("source " .. vim.fn.stdpath("config") .. "/legacy.vim")

  require("lazy").setup({
    lockfile = dotfiles.source_dir .. "/.lazy-lock.json",
    spec = plugins,
  })
end

return Config
