local os = require("os")
local MARKER = "__lua__"

function include(root_folder, filename)
  print("including " .. filename)
  local file = io.open(root_folder .. "/" .. filename, 'r')
  local content = file:read("*a")
  preamble_position = string.find(content,MARKER,1,true)
  if preamble_position then
    content = string.sub(content, preamble_position + #MARKER+1)
  end

  preamble = "-- content of " .. filename .. "\n"

  return(preamble .. content)
end

local env = {
  pairs  = pairs,
  ipairs = ipairs,
  type   = type,
  table  = table,
  string = string,
  date   = os.date,
  math   = math,
  adder  = adder,
  count  = count,
  include = include
}

local M = {}

function M.build(chdir, source, destination)
  env['root_folder'] = chdir
  local rendered = M.compile_file(chdir, source, env)
  local out = io.open(chdir .. "/" .. destination, "w+")

  print("Rendering to " .. destination)
  out:write(rendered)
end


-- Append text or code to the builder.
local function appender(builder, text, code)
  if code then
    builder[#builder+1] = code
  else
    -- [[ has a \n immediately after it. Lua will strip
    -- the first \n so we add one knowing it will be
    -- removed to ensure that if text starts with a \n
    -- it won't be lost.
    builder[#builder+1] = "_ret[#_ret+1] = [[\n" .. text .. "]]"
  end
end


local function interpret(builder, text, tag)
  local func

  if tag == "dofile" or tag == "_gfx" then
    local content = text:sub(#tag + 2, #text - 2)
    content = "include(root_folder, " .. content .. ")"

    func = function(code)
      return ('_ret[#_ret+1] = %s'):format(code)
    end
    appender(builder, nil, func(content))
    return
  end
    
  appender(builder, text)
end

markers = {
  "dofile",
  "_gfx"
}

function M.compile(tmpl, env)
  local builder = { "local _ret = {}\n" }
  local pos     = 1
  local b
  local func
  local err

  if #tmpl == 0 then
    return ""
  end

  while pos < #tmpl do
    local c_pos = #tmpl
    local marker = nil
    for ix = 1,#markers do
      local current_marker = markers[ix]
      local cm_pos = tmpl:find(current_marker .. "(", pos, true)
      if cm_pos and cm_pos < c_pos then
        c_pos = cm_pos
        marker = current_marker
      end
    end
    -- print("Found ".. marker .. " at #" .. c_pos)
  
    if c_pos ~= #tmpl then
      -- Add all text up until this block.
      appender(builder, tmpl:sub(pos, c_pos-1))
      -- Find the end of the block.
      pos = tmpl:find(")", c_pos)
      -- print("...  end of " .. marker .. " at #" ..pos)
      if not pos then
        appender(builder, "End of " .. marker .. "(')') missing")
        break
      end
      interpret(builder, tmpl:sub(c_pos, pos+1), marker)
      pos = pos+1
    end
  end
  -- Add any text after the last block. Or all of it if there
  -- are no blocks.
  if pos then
    appender(builder, tmpl:sub(pos, #tmpl-1))
  end

  builder[#builder+1] = "return table.concat(_ret)"
  print(env["root_folder"])
  -- Run the Lua code we built though Lua and get the result.
  func, err = load(table.concat(builder, "\n"), "template", "t", env)
  if not func then
    return err
  end
  return func()
end

function M.compile_file(root_folder, name, env)
  print("Loading source template: " .. name)
  local f, err = io.open(root_folder .. "/" .. name, "rb")
  if not f then
    print("Oups " .. err)
    return err
  end
  local t = f:read("*all")
  f:close()
  return M.compile(t, env)
end

return M
