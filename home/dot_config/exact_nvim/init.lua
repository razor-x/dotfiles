local config = require("config")

---@type string | nil
local plugin_import = "plugins"

if os.getenv("NVIM_DISABLE_PLUGINS") then
  plugin_import = nil
end

config.setup(plugin_import)
