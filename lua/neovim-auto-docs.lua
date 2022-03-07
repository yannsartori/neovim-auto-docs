local str_utils = require('utils.string')
local M = {}

local api = vim.api
local function setup_vim_commands()
  vim.cmd [[
    command! NvimAutoDoc lua require('neovim-auto-docs').docs() 
  ]]
end

function M.docs()
  local cur_file_name = api.nvim_buf_get_name(0)
  if str_utils.ends_with(cur_file_name, '.ts') then
    require('functions.js').generate_docstring()
  elseif str_utils.ends_with(cur_file_name, '.py') then
    require('functions.py').generate_docstring()
  end
end
setup_vim_commands()
return M
