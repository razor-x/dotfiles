local bootstrap = require("config.bootstrap")
local dotfiles = require("config.dotfiles")
local options = require("config.options")

local Config = {}

Config.setup = function()
  bootstrap()

  options.setup()

  vim.cmd("source " .. vim.fn.stdpath("config") .. "/legacy.vim")

  require("lazy").setup({
    lockfile = dotfiles.source_dir .. "/.lazy-lock.json",
    import = "plugins",
  })
end

return Config
