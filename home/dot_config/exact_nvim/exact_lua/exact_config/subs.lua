local M = {}

local replacements

local function parse(arguments)
  local delimiter = arguments:sub(1, 1)
  if delimiter == "" or delimiter:match("[%w%s\\]") then
    error("S requires a non-alphanumeric delimiter")
  end

  local function part(start)
    local value = {}
    local index = start
    while index <= #arguments do
      local character = arguments:sub(index, index)
      if character == delimiter then
        return table.concat(value), index + 1, true
      end
      if character == "\\" then
        local next_character = arguments:sub(index + 1, index + 1)
        if next_character == delimiter or next_character == "\\" then
          value[#value + 1] = next_character
          index = index + 2
        else
          value[#value + 1] = character
          index = index + 1
        end
      else
        value[#value + 1] = character
        index = index + 1
      end
    end
    return table.concat(value), index, false
  end

  local source, index, found = part(2)
  if not found then
    error("S requires a source and replacement")
  end
  if source == "" then
    source = vim.fn.getreg("/"):match([[^\<([%w_]+)\>$]])
    if not source then
      error("S with an empty source requires a search created by *")
    end
  end

  local replacement, flags_index, has_flags = part(index)
  local flags = has_flags and arguments:sub(flags_index) or ""
  if replacement == "" or not flags:match("^[gc]*$") then
    error("S supports only the g and c flags")
  end

  return source, replacement, flags
end

local function variants(cases, source, replacement)
  local result = { [source] = replacement }
  for _, case in ipairs(cases) do
    local convert = case.case or case
    result[convert(source)] = convert(replacement)
  end
  return result
end

local function project_files(patterns, fixed_strings)
  local command = { "rg", "--files-with-matches", "--hidden", "--glob", "!.git/**", "--null" }
  if fixed_strings then
    command[#command + 1] = "--fixed-strings"
  end
  for _, pattern in ipairs(patterns) do
    vim.list_extend(command, { "-e", pattern })
  end

  local result = vim.system(command, { text = false }):wait()
  if result.code > 1 then
    error(vim.trim(result.stderr or "rg failed"))
  end
  return vim.split(result.stdout or "", "\0", { plain = true, trimempty = true })
end

local function project_substitute(arguments, files, command)
  for _, file in ipairs(files) do
    vim.cmd.edit(vim.fn.fnameescape(file))
    vim.cmd("%" .. command .. arguments)
    vim.cmd("silent update")
  end
end

local function literal_pattern(value)
  return [[\V]] .. value:gsub("\\", "\\\\") .. [[\m]]
end

---@param cases table[] Coerce-compatible case descriptors
function M.setup(cases)
  vim.api.nvim_create_user_command("S", function(options)
    local source, replacement, flags = parse(options.args)
    local replacements_by_source = variants(cases, source, replacement)
    local sources = vim.tbl_keys(replacements_by_source)
    table.sort(sources, function(left, right)
      return #left > #right
    end)

    local pattern_parts = vim.tbl_map(literal_pattern, sources)
    local pattern = ([[\C\%%(%s\)]]):format(table.concat(pattern_parts, [[\|]])):gsub("/", [[\/]])
    local command = ([[%d,%dsubstitute/%s/\=v:lua.require("config.subs").replace(submatch(0))/%s]]):format(
      options.line1,
      options.line2,
      pattern,
      flags
    )

    replacements = replacements_by_source
    local ok, err = pcall(vim.cmd, command)
    replacements = nil
    if not ok then
      error(err)
    end
  end, {
    desc = "Case-preserving literal substitution",
    nargs = 1,
    range = true,
    force = true,
  })

  vim.api.nvim_create_user_command("Gs", function(options)
    local source = parse(options.args)
    project_substitute(options.args, project_files({ source }, false), "substitute")
  end, {
    desc = "Project-wide substitution",
    nargs = 1,
    force = true,
  })

  vim.api.nvim_create_user_command("GS", function(options)
    local source, replacement = parse(options.args)
    project_substitute(options.args, project_files(vim.tbl_keys(variants(cases, source, replacement)), true), "S")
  end, {
    desc = "Project-wide case-preserving substitution",
    nargs = 1,
    force = true,
  })
end

function M.replace(value)
  return replacements[value] or value
end

return M
