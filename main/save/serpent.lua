-- serpent.lua (精简版)
local serpent = {}

local function s(t, opts)
  local name = opts and opts.name or 'do local _'
  local sparse = opts and opts.sparse
  local space = opts and opts.indent or ''
  local maxlevel = opts and opts.maxlevel or math.huge
  local iname = not opts and name or space..name
  local comma = space == '' and ',' or ';'
  local numformat = opts and opts.numformat or "%.17g"
  
  local function s_helper(t, indent, level)
    if level > maxlevel then return '{}' end
    local lines = {}
    local con = #t == 0 and not next(t) and '{}' or '{\n'
    local i = 1
    
    for k, v in pairs(t) do
      local key
      if type(k) == "number" and k == i then
        i = i + 1
        key = ''
      else
        if type(k) == "number" then
          key = '['..k..'] = '
        elseif type(k) == "string" and k:match("^[%a_][%w_]*$") then
          key = k..' = '
        else
          key = '['..s(k)..'] = '
        end
      end
      
      local value
      if type(v) == "table" then
        value = s_helper(v, indent..'  ', level+1)
      elseif type(v) == "string" then
        value = string.format('%q', v)
      elseif type(v) == "number" then
        value = string.format(numformat, v)
      else
        value = tostring(v)
      end
      
      lines[#lines+1] = indent..'  '..key..value..comma
    end
    
    return con..table.concat(lines, '\n')..'\n'..indent..'}'
  end
  
  return name..' = '..s_helper(t, space, 1)
end

serpent.block = function(t, opts)
  return s(t, opts)
end

return serpent