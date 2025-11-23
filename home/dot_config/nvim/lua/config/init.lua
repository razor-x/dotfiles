local dotfiles = require("config.dotfiles")
local plugins = require("config.plugins")

local Config = {}

Config.setup = function()
  require("config.lazy").bootstrap()

  vim.cmd("source " .. vim.fn.stdpath("config") .. "/legacy.vim")

  require("lazy").setup({
    lockfile = dotfiles.source_dir .. "/.lazy-lock.json",
    spec = plugins,
  })
end

return Config
