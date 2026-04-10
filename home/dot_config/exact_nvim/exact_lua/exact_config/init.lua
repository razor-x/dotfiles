local bootstrap = require("config.bootstrap")
local dotfiles = require("config.dotfiles")
local options = require("config.options")

local M = {}

---@param plugin_import string | nil Module name to load plugins from
M.setup = function(plugin_import)
  options.setup()

  vim.cmd("source " .. vim.fn.stdpath("config") .. "/legacy.vim")

  if plugin_import then
    bootstrap()
    require("lazy").setup({
      lockfile = dotfiles.source_dir .. "/.lazy-lock.json",
      import = "plugins",
    })
  end
end

return M
