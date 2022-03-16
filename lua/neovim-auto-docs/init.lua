local M = {}
local str_utils = require("neovim-auto-docs.utils.string")

local api = vim.api

function M.generate_doc()
	local cur_file_name = api.nvim_buf_get_name(0)
	if str_utils.ends_with(cur_file_name, ".ts") then
		require("neovim-auto-docs.functions.js").generate_docstring()
	elseif str_utils.ends_with(cur_file_name, ".py") then
		require("neovim-auto-docs.functions.py").generate_docstring()
	end
end

local function setup_vim_commands()
	vim.cmd([[
    command! NvimAutoDoc lua require('neovim-auto-docs').generate_doc() 
  ]])
end

function M.setup(conf)
  setup_vim_commands()
end

setup_vim_commands()
return M
