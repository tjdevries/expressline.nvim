local luvjob = require('luvjob')

local modes = require('el.data').modes

local extensions = {}

local git_changed = vim.regex([[\(\d\+\)\( file changed\)\@=]])
local git_insertions = vim.regex([[\(\d\+\)\( insertions\)\@=]])
local git_deletions = vim.regex([[\(\d\+\)\( deletions\)\@=]])

local parse_shortstat_output = function(s)
  local result = {}

  local changed = {git_changed:match_str(s)}
  if not vim.tbl_isempty(changed) then
    table.insert(result, string.format('+%s', string.sub(s, changed[1] + 1, changed[2])))
  end

  local insert = {git_insertions:match_str(s)}
  if not vim.tbl_isempty(insert) then
    table.insert(result, string.format('~%s', string.sub(s, insert[1] + 1, insert[2])))
  end

  local delete = {git_deletions:match_str(s)}
  if not vim.tbl_isempty(delete) then
    table.insert(result, string.format('-%s', string.sub(s, delete[1] + 1, delete[2])))
  end

  if vim.tbl_isempty(result) then
    return nil
  end

  return string.format("[%s]", table.concat(result, ", "))
end

extensions.git_checker = function(_, buffer)
  local filetype = buffer.filetype

  if filetype ~= 'lua' and filetype ~= 'python' then
    return
  end

  if vim.api.nvim_buf_get_option(buffer.bufnr, 'bufhidden')
      or vim.api.nvim_buf_get_option(buffer.bufnr, 'buftype') == 'nofile' then
    return
  end

  local j = luvjob:new({
    command = "git",
    args = {"diff", "--shortstat"},
    cwd = vim.fn.fnamemodify(buffer.name, ":h"),
  })

  local ok, result = pcall(function()
    return parse_shortstat_output(vim.trim(j:start():wait()._raw_output))
  end)

  if ok then
    return result
  end

  return ''
end

ExpressLineExtensionsMode = function()
  local mode = vim.fn.mode()

  local display_name = modes[mode][1]

  return string.format(' [ %s ] ', display_name)
end

extensions.mode = function(_, buffer)
  local filetype = buffer.filetype

  return string.format('%%{v:lua.ExpressLineExtensionsMode()}')
end

return extensions
