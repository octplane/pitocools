local os = require("os")

markers = {
  "__lua",
  "__gfx",
  "__gff",
  "__map",
  "__sfx",
  "__music"
}


function include(root_folder, filename, section)
  print("including " .. filename)
  local file = io.open(root_folder .. "/" .. filename, 'r')
  local content = file:read("*a")
  local marker = section .. "__\n"
  preamble_position = string.find(content, marker, 1,true)
  if preamble_position then
    end_section = string.find(content, "__[^_]+__\n", preamble_position)
    if end_section ~= nil then
      content = string.sub(content, preamble_position + #marker+1)
    else
      print("No end for " .. filename)
      content = string.sub(content, preamble_position + #marker+1, end_section)
    end
  end

  preamble = "-- content of " .. filename .. "\n"
  if section ~= "__lua" then
    preamble = section .. "__\n" .. preamble
  end
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
  -- builder is the template builder
  -- text is the content of the function call
  -- tag is the function we are calling
  local content = text:sub(#tag + 1, #text - 1)
  content = "include(root_folder, " .. content .. ", \"" .. tag .. "\")"

  local func = function(code)
    return ('_ret[#_ret+1] = %s'):format(code)
  end
  appender(builder, nil, func(content))
end
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
    if c_pos ~= #tmpl then
      print("Found ".. marker .. " at #" .. c_pos)
      -- Add all text up until this block.
      appender(builder, tmpl:sub(pos, c_pos-1))
      -- Find the end of the block.
      pos = tmpl:find(")", c_pos)
      -- print("...  end of " .. marker .. " at #" ..pos)
      if not pos then
        appender(builder, "End of " .. marker .. "(')') missing")
        break
      end
      interpret(builder, tmpl:sub(c_pos+1, pos), marker)
      pos = pos+1
    end
    if c_pos == #tmpl then
      break
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
