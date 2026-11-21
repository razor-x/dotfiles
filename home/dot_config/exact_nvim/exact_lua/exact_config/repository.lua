local M = {}

function M.github_paths()
  local config_home = vim.env.XDG_CONFIG_HOME
  local dir =
    vim.fs.joinpath(config_home and config_home ~= "" and config_home or vim.fn.expand("~/.config"), "repository.d")
  local files = {}
  for name, kind in vim.fs.dir(dir) do
    if (kind == "file" or kind == "link") and vim.endswith(name, ".json") then
      files[#files + 1] = name
    end
  end
  table.sort(files)

  local paths = {}
  for _, name in ipairs(files) do
    local ok, result = pcall(M.read_github_paths, vim.fs.joinpath(dir, name))
    if ok then
      for repo, path in pairs(result) do
        paths[repo] = path
      end
    else
      vim.notify(("Ignoring repository.d/%s: %s"):format(name, result), vim.log.levels.WARN)
    end
  end
  return paths
end

function M.read_github_paths(file)
  local data = vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
  assert(type(data) == "table" and vim.islist(data.repos), "expected a repos array")
  assert(type(data.repoRoot) == "string", "expected a repoRoot string")
  local root = vim.startswith(data.repoRoot, "/") and data.repoRoot
    or vim.fs.joinpath(vim.fn.expand("~"), data.repoRoot)
  local paths = {}
  for _, repo in ipairs(data.repos) do
    assert(
      type(repo) == "table" and type(repo.url) == "string" and type(repo.path) == "string",
      "expected repo url and path strings"
    )
    local slug = repo.url:match("^git@github%.com:([%w_.-]+/[%w_.-]+)$")
      or repo.url:match("^https://github%.com/([%w_.-]+/[%w_.-]+)$")
      or repo.url:match("^ssh://git@github%.com/([%w_.-]+/[%w_.-]+)$")
    if slug then
      local path = vim.fs.joinpath(root, repo.path)
      assert(
        repo.path ~= "" and not vim.startswith(repo.path, "/") and not path:find("[%c`*]"),
        "invalid repository path"
      )
      paths[(slug:gsub("%.git$", ""))] = vim.fs.normalize(path, { expand_env = false })
    end
  end
  return paths
end

return M
