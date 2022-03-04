local M = {}
local str_utils = require('utils.string')
local consts = require('utils.constants')

function M.is_param(type)
  return str_utils.ends_with(type, consts.PARAMETER)
end

function M.is_function(type)
    return string.find(type, consts.FUNCTION)
end

function M.is_identifier(type)
  return str_utils.ends_with(type, consts.IDENTIFIER)
end

function M.is_program(type)
    return (
        str_utils.ends_with(type, consts.PROGRAM) or
        str_utils.ends_with(type, consts.MODULE)
    )
end
return M
