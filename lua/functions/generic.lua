local M = {}

local ts_utils = require('nvim-treesitter.ts_utils')
local consts = require('utils.constants')

local api = vim.api

local AbstractFunction = {}
-- {{
    -- Get the root function node on the line the cursor is currently at
    --- @return any #The node
    function AbstractFunction.get_func_node()
      api.nvim_feedkeys("$", "n", false)
      local node = ts_utils.get_node_at_cursor()
      if node == nil then
        error('No Treesitter installed.')
      end

      -- Make sure we are at a function declaration
      local start_row = node:start()
      local parent = node:parent()

      while (parent ~= nil and parent:start() == start_row and node:type() ~= consts.FUNCTION) do
        node = parent
        parent = node:parent()
      end
      return node
    end

    -- Extract the function name
    --- @param func_node any #The function node
    --- @param current_line string #The line under the cursor
    --- @return string #The function name
    function AbstractFunction.get_func_name(func_node, current_line)
      local id_node = func_node:field('name')[1]
      local _, col_start, _, col_end = id_node:range()
      return current_line:sub(col_start + 1, col_end)
    end

    -- Get the return (if any)
    --- @param func_node any #The function node
    --- @return string | nil #The return type, nil if non-existent or void
    function AbstractFunction.get_return(func_node)
      local return_node = func_node:field('return_type')[1]
      if return_node then
          local row_start, col_start, _, col_end = return_node:named_child(0):range()
          local line = api.nvim_buf_get_lines(0, row_start, row_start + 1, true)[1]
          return line:sub(col_start + 1, col_end)
      end
      return return_node
    end

-- }}
M.AbstractFunction = AbstractFunction
return M