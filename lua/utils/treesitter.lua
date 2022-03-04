local M = {}
local str_utils = require('utils.string')
function M.is_param(type)
  return str_utils.ends_with(type, 'parameter')
end
function M.is_identifier(type)
  return str_utils.ends_with(type, 'identifier')
end
return M
