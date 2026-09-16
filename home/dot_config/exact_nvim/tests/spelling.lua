local spelling = dofile("home/dot_config/exact_nvim/exact_lua/exact_config/spelling.lua")
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/project/.git", "p")
vim.fn.mkdir(root .. "/project/sub", "p")
package.loaded.dotfiles = { config_dir = root .. "/global" }
vim.cmd.edit(root .. "/project/sub/file.txt")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "quuxspellingtest" })
vim.wo.spell = true
vim.o.hidden = true
local language = vim.bo.spelllang
local confirm = vim.fn.confirm
local answer = 2
vim.fn.confirm = function()
  return answer
end
local function run()
  spelling.setup()
  local path = root .. "/project/.spellfile.utf-8.add"
  assert(spelling.local_path() == path)
  spelling.change(true, false)
  assert(vim.fn.filereadable(path) == 0)
  answer = 1
  spelling.change(true, false)
  assert(vim.fn.filereadable(path .. ".spl") == 1)
  assert(vim.fn.spellbadword("quuxspellingtest")[1] == "")
  answer = 2
  spelling.change(true, true)
  assert(spelling.empty(path))
  assert(vim.fn.spellbadword("quuxspellingtest")[1] ~= "")
  spelling.change(true, false)
  answer = 1
  spelling.change(true, true)
  assert(vim.fn.filereadable(path) == 0)
  assert(vim.fn.filereadable(path .. ".spl") == 0)
  spelling.change(false, false)
  assert(vim.fn.filereadable(spelling.global_path()) == 1)
  spelling.change(false, true)
  assert(spelling.empty(spelling.global_path()))
  spelling.create_local()
  local nested = root .. "/project/sub/.spellfile.utf-8.add"
  vim.fn.writefile({ "nestedword" }, nested)
  assert(spelling.local_path() == nested)
  spelling.refresh()
  assert(vim.bo.spellfile:find(nested, 1, true))
  vim.fn.delete(nested)
  vim.fn.delete(path)
  vim.fn.writefile({ "outsideword" }, root .. "/.spellfile.utf-8.add")
  spelling.refresh()
  assert(not vim.bo.spellfile:find(".spellfile", 1, true))
  vim.fn.delete(spelling.global_path() .. ".spl")
  spelling.refresh()
  assert(vim.fn.filereadable(spelling.global_path() .. ".spl") == 1)
  assert(vim.bo.spelllang == language)
  vim.cmd.edit(root .. "/outside.txt")
  assert(spelling.local_path() == root .. "/.spellfile.utf-8.add")
  vim.fn.mkdir(root .. "/outside-sub", "p")
  vim.cmd.edit(root .. "/outside-sub/file.txt")
  assert(spelling.local_path() == root .. "/outside-sub/.spellfile.utf-8.add")
  vim.cmd.enew()
  vim.bo.buftype = "nofile"
  assert(spelling.local_path() == nil)
  vim.cmd.enew()
  vim.wo.spell = true
  vim.api.nvim_open_term(0, {})
  assert(not vim.wo.spell)
  spelling.refresh()
  assert(not vim.wo.spell)
end
local ok, err = pcall(run)
vim.fn.confirm = confirm
vim.fn.delete(root, "rf")
assert(ok, err)
