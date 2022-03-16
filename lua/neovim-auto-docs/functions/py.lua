local M = {}

local treesitter_utils = require("neovim-auto-docs.utils.treesitter")
local AbstractFunction = require("neovim-auto-docs.functions.generic").AbstractFunction
local str_utils = require("neovim-auto-docs.utils.string")

local api = vim.api

local PythonFunction = {}
-- {{
-- Get the root function node on the line the cursor is currently at
--- @return any #The node
PythonFunction.get_func_node = AbstractFunction.get_func_node

-- Extract the function name
--- @param func_node any #The function node
--- @param current_line string #The line under the cursor
--- @return string #The function name
PythonFunction.get_func_name = AbstractFunction.get_func_name

-- Extract the param names
--- @param func_node any #The function node
--- @return string[] #The parameters
function PythonFunction.get_params(func_node)
	local param_nodes = func_node:field("parameters")[1]
	local params = {}
	for param in param_nodes:iter_children() do
		-- The variable is untyped
		if treesitter_utils.is_identifier(param:type()) then
			local row_start, col_start, _, col_end = param:range()
			local line = api.nvim_buf_get_lines(0, row_start, row_start + 1, true)[1]
			local param_name = line:sub(col_start + 1, col_end)
			-- Ignore self parameters
			if param_name ~= "self" then
				table.insert(params, param_name)
			end
			-- The variable is typed
		elseif treesitter_utils.is_param(param:type()) then
			local row_start, col_start, _, col_end = param:named_child(0):range()
			local line = api.nvim_buf_get_lines(0, row_start, row_start + 1, true)[1]
			local param_name = line:sub(col_start + 1, col_end)
			table.insert(params, param_name)
		end
	end
	return params
end

-- Get the return (if any)
--- @param func_node any #The function node
--- @return string | nil #The return type, nil if non-existent or void
PythonFunction.get_return = AbstractFunction.get_return

-- Generate the docstring (to be written)
--- @param func_name string #The function name
--- @param params string[] #The parameters
--- @param return_type string | nil #The return  type
--- @return string[] #The docstring contents
function PythonFunction.generate_docstring(func_name, params, return_type)
	local doc = {
		[1] = '"""',
		[2] = func_name,
		[3] = "",
	}
	for _, param in ipairs(params) do
		table.insert(doc, ":param " .. param .. ": ")
	end
	if return_type and return_type ~= "None" then
		table.insert(doc, ":return: ")
	end
	table.insert(doc, '"""')
	return doc
end

-- Writes the docstring to the buffer
--- @param func_node any #The function node
--- @param doc string[] #The docstring contents
function PythonFunction.write_docstring(func_node, doc)
	local whitespace = ""

	local tab = ""
	if api.nvim_get_option("expandtab") then
		tab = string.rep(" ", api.nvim_get_option("shiftwidth"))
	else
		tab = "\t"
	end

	for idx, line in ipairs(doc) do
		if line ~= "" then
			doc[idx] = whitespace .. tab .. line
		else
			doc[idx] = line
		end
	end
	table.insert(doc, "")
	local row_start, _, _, _ = func_node:field("body")[1]:range()
	api.nvim_buf_set_text(0, row_start, 0, row_start, 0, doc)
	api.nvim_feedkeys(":" .. (row_start + 2) .. "\r", "n", false)
	api.nvim_feedkeys("A", "n", false)
end
-- }}

function M.generate_docstring()
	local builder = PythonFunction

	local cur_line = api.nvim_get_current_line()
	local status, func_node = pcall(builder.get_func_node, cur_line)
	if not status then
		-- Ignore the path
		print("[NeovimAutoDocs]" .. str_utils.split(func_node, ":")[3])
		return
	end

	local func_name = builder.get_func_name(func_node, api.nvim_get_current_line())
	local params = builder.get_params(func_node)
	local return_type = builder.get_return(func_node)
	local doc = builder.generate_docstring(func_name, params, return_type)
	builder.write_docstring(func_node, doc)
end
return M
