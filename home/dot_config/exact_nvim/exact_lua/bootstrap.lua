---@param lazy_repo string Git repo URL to the lazy plugin manager
---@param lazy_version string Git tag to clone
return function(lazy_repo, lazy_version)
  local lazy_path = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim")
  if not (vim.uv or vim.loop).fs_stat(lazy_path) then
    local out = vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=v" .. lazy_version,
      lazy_repo,
      lazy_path,
    })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out, "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  vim.opt.rtp:prepend(lazy_path)
end
