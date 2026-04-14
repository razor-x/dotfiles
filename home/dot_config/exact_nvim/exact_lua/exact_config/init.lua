local dotfiles = require("dotfiles")

local bootstrap = require("config.bootstrap")
local mappings = require("config.mappings")
local options = require("config.options")

local M = {}

---@param plugin_import string | nil Module name to load plugins from
function M.setup(plugin_import)
  options.setup()
  mappings.setup()

  if plugin_import ~= nil then
    bootstrap("https://github.com/folke/lazy.nvim.git", "11.17.5")
    require("lazy").setup({
      lockfile = vim.fs.joinpath(dotfiles.config_dir, ".lazy-lock.json"),
      import = plugin_import,
    })
  end
end

return M
