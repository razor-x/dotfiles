local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("DotfilesSpelling", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "FileType" }, {
    group = group,
    callback = function()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function()
      vim.wo.spell = false
    end,
  })
  vim.api.nvim_create_user_command("Mklocalspell", function()
    M.create_local()
  end, {})
  for key, action in pairs({
    zg = { false, false, "Add word to global dictionary" },
    zl = { true, false, "Add word to local dictionary" },
    zug = { false, true, "Remove word from global dictionary" },
    zul = { true, true, "Remove word from local dictionary" },
  }) do
    vim.keymap.set("n", key, function()
      M.change(action[1], action[2])
    end, { desc = action[3] })
  end
  M.refresh()
end

function M.global_path()
  local ok, dotfiles = pcall(require, "dotfiles")
  return vim.fs.joinpath(ok and dotfiles.config_dir or vim.fn.stdpath("config"), "spell", "words.utf-8.add")
end

function M.local_path()
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= "" or name == "" or name:match("^%w+://") then
    return
  end
  local directory = vim.fs.dirname(name)
  local root = vim.fs.root(directory, ".git") or directory
  local current = directory
  while true do
    local path = vim.fs.joinpath(current, ".spellfile.utf-8.add")
    if vim.fn.filereadable(path) == 1 then
      return path
    end
    if current == root then
      break
    end
    current = vim.fs.dirname(current)
  end
  return vim.fs.joinpath(root, ".spellfile.utf-8.add")
end

function M.compile(path, force)
  if vim.fn.filereadable(path) == 1 and (force or vim.fn.getftime(path .. ".spl") < vim.fn.getftime(path)) then
    vim.cmd("silent mkspell! " .. vim.fn.fnameescape(path))
  end
end

function M.refresh()
  if vim.bo.buftype == "terminal" then
    vim.wo.spell = false
  end
  local path = M.local_path()
  if not path then
    return
  end
  local files = {}
  for _, file in ipairs({ path, M.global_path() }) do
    if vim.fn.filereadable(file) == 1 then
      M.compile(file)
      files[#files + 1] = file
    end
  end
  vim.opt_local.spellfile = files
end

function M.refresh_all()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer) then
      vim.api.nvim_buf_call(buffer, M.refresh)
    end
  end
end

function M.create_local()
  local path = M.local_path()
  if not path then
    error("Local spelling requires a named file buffer")
  end
  if vim.fn.filereadable(path) == 0 then
    assert(vim.fn.writefile({}, path) == 0, "Cannot create " .. path)
  end
  M.compile(path, true)
  M.refresh_all()
  vim.wo.spell = true
  vim.notify("Local spellfile: " .. path)
end

function M.change(local_dictionary, remove)
  local local_path = M.local_path()
  if not local_path then
    error("Spelling requires a named file buffer")
  end
  if vim.fn.expand("<cword>") == "" then
    return
  end
  local path = local_dictionary and local_path or M.global_path()
  if vim.fn.filereadable(path) == 0 then
    if remove then
      vim.notify("No spellfile: " .. path)
      return
    end
    if local_dictionary and vim.fn.confirm("Create " .. path .. "?", "&Yes\n&No", 2) ~= 1 then
      return
    end
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    assert(vim.fn.writefile({}, path) == 0, "Cannot create " .. path)
  end
  local previous = vim.bo.spellfile
  vim.opt_local.spellfile = { path }
  local ok, err = pcall(vim.cmd.normal, { args = { remove and "1zug" or "1zg" }, bang = true })
  vim.bo.spellfile = previous
  if not ok then
    error(err)
  end
  M.compile(path, true)
  if local_dictionary and remove and M.empty(path) then
    if vim.fn.confirm("Local spellfile is empty. Remove " .. path .. "?", "&Yes\n&No", 2) == 1 then
      assert(vim.fn.delete(path) == 0, "Cannot delete " .. path)
      if vim.fn.filereadable(path .. ".spl") == 1 then
        assert(vim.fn.delete(path .. ".spl") == 0, "Cannot delete " .. path .. ".spl")
      end
    end
  end
  M.refresh_all()
  vim.notify((remove and "Removed word from " or "Added word to ") .. path)
end

function M.empty(path)
  for _, line in ipairs(vim.fn.readfile(path)) do
    if line:match("%S") and not line:match("^%s*#") then
      return false
    end
  end
  return true
end

return M
