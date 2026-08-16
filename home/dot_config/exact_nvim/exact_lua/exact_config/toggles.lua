local M = {}

---@class ToggleMapping
---@field desc string
---@field global function
---@field local_scope? "buffer"|"window"
---@field local_toggle? function

---@param key string
---@param toggle ToggleMapping
function M.map_toggle(key, toggle)
  vim.keymap.set("n", "yo" .. key, toggle.global, {
    desc = "Toggle " .. toggle.desc .. " globally",
    silent = true,
  })

  if toggle.local_toggle then
    vim.keymap.set("n", [[\o]] .. key, toggle.local_toggle, {
      desc = "Toggle " .. toggle.desc .. " for current " .. toggle.local_scope,
      silent = true,
    })
  end
end

---@param option string
---@param enabled_value? any
---@param disabled_value? any
---@return ToggleMapping
function M.window_option_toggle(option, enabled_value, disabled_value)
  if enabled_value == nil then
    enabled_value = true
  end
  if disabled_value == nil then
    disabled_value = false
  end

  local function toggled_value(window)
    local value = vim.api.nvim_get_option_value(option, { scope = "local", win = window })
    if value == enabled_value then
      return disabled_value
    end
    return enabled_value
  end

  return {
    desc = option,
    global = function()
      local value = toggled_value(0)
      vim.api.nvim_set_option_value(option, value, { scope = "global" })
      for _, window in ipairs(vim.api.nvim_list_wins()) do
        vim.api.nvim_set_option_value(option, value, { scope = "local", win = window })
      end
    end,
    local_scope = "window",
    local_toggle = function()
      vim.api.nvim_set_option_value(option, toggled_value(0), { scope = "local", win = 0 })
    end,
  }
end

return M
