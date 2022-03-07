local M = {}

local treesitter_utils = require('utils.treesitter')
local str_utils = require('utils.string')
local AbstractFunction = require('functions.generic').AbstractFunction

local api = vim.api

local JsFunction = {}
-- {{

  -- Get the root function node on the line the cursor is currently at
  --- @return any #The node
  JsFunction.get_func_node = AbstractFunction.get_func_node

  -- Extract the function name
  --- @param func_node any #The function node
  --- @param current_line string #The line under the cursor
  --- @return string #The function name
  JsFunction.get_func_name = AbstractFunction.get_func_name

  -- Extract the param names
  --- @todo Add types
  --- @param func_node any #The function node
  --- @return string[] #The parameters
  function JsFunction.get_params(func_node)
    local param_nodes = func_node:field('parameters')[1]
    local params = { }
    for param in param_nodes:iter_children() do
      if treesitter_utils.is_param(param:type()) then
        local row_start, col_start, _, col_end = param:field('pattern')[1]:range()
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
  JsFunction.get_return = AbstractFunction.get_return

  -- Generate the docstring (to be written)
  --- @param func_name string #The function name
  --- @param params string[] #The parameters
  --- @param return_type string | nil #The return  type
  --- @return string[] #The docstring contents
  function JsFunction.generate_docstring(func_name, params, return_type)
    local doc = {
    [1] = '/**',
    [2] = ' * ' .. func_name,
    [3] = ' *',
    }
    for _, param in ipairs(params) do
      table.insert(doc, ' * @param ' .. param)
    end
    if return_type and return_type ~= 'void' then
      table.insert(doc,' * @returns ')
    end
    table.insert(doc, ' */')
    return doc
  end

  -- Writes the docstring to the buffer
  --- @param func_node any #The function node
  --- @param doc string[] #The the docstring contents
  function JsFunction.write_docstring(func_node, doc)
    local cur_line = api.nvim_get_current_line()
    local whitespace = ''
    local i, j = cur_line:find('^%s*')
    if i then
      whitespace = cur_line:sub(i, j)
    end
    for idx, line in ipairs(doc) do
      doc[idx] = whitespace .. line
    end
    table.insert(doc, '')
    local row_start, _, _, _ = func_node:range()
    api.nvim_buf_set_text(0, row_start, 0, row_start, 0, doc)
    api.nvim_feedkeys(#doc - 2 .. 'k', 'n', false)
    api.nvim_feedkeys('A', 'n', false)
  end
-- }}

function M.generate_docstring()
  local builder = JsFunction

  local cur_line = api.nvim_get_current_line()
  local status, func_node = pcall(builder.get_func_node, cur_line)
  if not status then
    -- Ignore the path
    print('[NeovimAutoDocs]' .. str_utils.split(func_node, ':')[3])
    return
  end

  local func_name = builder.get_func_name(func_node, cur_line)
  local params = builder.get_params(func_node)
  local return_type = builder.get_return(func_node)
  local doc = builder.generate_docstring(func_name, params, return_type)
  builder.write_docstring(func_node, doc)
end
return M
