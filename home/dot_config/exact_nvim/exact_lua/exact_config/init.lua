local bootstrap = require("config.bootstrap")
local dotfiles = require("config.dotfiles")
local mappings = require("config.mappings")
local options = require("config.options")

local M = {}

---@param plugin_import string | nil Module name to load plugins from
function M.setup(plugin_import)
  options.setup()
  mappings.setup()

  if plugin_import then
    bootstrap()
    require("lazy").setup({
      lockfile = dotfiles.source_dir .. "/.lazy-lock.json",
      import = "plugins",
    })
  end
end

return M
