package.preload["config.subs"] = function()
  return dofile("home/dot_config/exact_nvim/exact_lua/exact_config/subs.lua")
end

local function words(value)
  local separated = value:gsub("([a-z0-9])([A-Z])", "%1_%2")
  local result = {}
  for word in separated:gmatch("[^_.%-%s/]+") do
    result[#result + 1] = word:lower()
  end
  return result
end

local function join(separator, capitalize)
  return function(value)
    local parts = words(value)
    if capitalize then
      for index, part in ipairs(parts) do
        parts[index] = part:sub(1, 1):upper() .. part:sub(2)
      end
    end
    return table.concat(parts, separator)
  end
end

local cases = {
  { case = join("_", false) },
  { case = join("", true) },
  { case = join("-", false) },
  { case = join(".", false) },
  { case = join("/", false) },
  {
    case = function(value)
      return join("_", false)(value):upper()
    end,
  },
}

require("config.subs").setup(cases)

vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "foo_bar FooBar foo-bar foo.bar foo/bar FOO_BAR unrelated",
  "FooBar foo_bar",
})
vim.cmd("1S/foo_bar/bar_bar/g")
vim.fn.setreg("/", [[\<foo_bar\>]])
vim.cmd("2S##baz_qux")

assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), {
  "bar_bar BarBar bar-bar bar.bar bar/bar BAR_BAR unrelated",
  "BazQux foo_bar",
}))

local ok = pcall(vim.cmd, "S/foo_bar")
assert(not ok)
