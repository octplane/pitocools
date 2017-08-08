local os = require("os")
local MARKER = "__lua__"

function include(filename)
    local file = io.open(filename, 'r')
    local content = file:read("*a")
    preamble_position = string.find(content,MARKER,1,true)
    if preamble_position then
        return string.sub(content, preamble_position + #MARKER+1)
    end
    return(content)
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

function M.build(source, destination)
  local rendered = M.compile_file(source, env)
  local out = io.open(destination, "w+")

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


local function interpret(builder, text)
    local func
    local tag

    tag = text:sub(1, 7)
    local content = text:sub(#tag, #text)
    content = "include" .. content

    if tag == "dofile(" then
        func = function(code)
            return ('_ret[#_ret+1] = %s'):format(code)
        end
    end

    if func then
        appender(builder, nil, func(content))
    else
        appender(builder, text)
    end
end

--- Compile a Lua template into a string.
--
-- @param      tmpl The template.
-- @param[opt] env  Environment table to use for sandboxing.
--
-- return Compiled template.
function M.compile(tmpl, env)
    -- Turn the template into a string that can be run though
    -- Lua. Builder will be used to efficiently build the string
    -- we'll run. The string will use it's own builder (_ret). Each
    -- part that comprises _ret will be the various pieces of the
    -- template. Strings, variables that should be printed and
    -- functions that should be run.
    local builder = { "_ret = {}\n" }
    local pos     = 1
    local b
    local func
    local err

    if #tmpl == 0 then
        return ""
    end

    while pos < #tmpl do
        -- Look for start of a Lua block.
        b = tmpl:find("dofile(", pos, true)
        if not b then
            break
        end

          -- Add all text up until this block.
          appender(builder, tmpl:sub(pos, b-1))
          -- Find the end of the block.
          pos = tmpl:find(")", b)
          if not pos then
              appender(builder, "End dofile (')') missing")
              break
          end
          interpret(builder, tmpl:sub(b, pos+1))

          -- Skip back the }} (pos points to the start of }}).
          pos = pos+1
    end
    -- Add any text after the last block. Or all of it if there
    -- are no blocks.
    if pos then
        appender(builder, tmpl:sub(pos, #tmpl-1))
    end

    builder[#builder+1] = "return table.concat(_ret)"
    -- Run the Lua code we built though Lua and get the result.
    func, err = load(table.concat(builder, "\n"), "template", "t", env)
    if not func then
        return err
    end
    return func()
end

function M.compile_file(name, env)
    local f, err = io.open(name, "rb")
    if not f then
        return err
    end
    local t = f:read("*all")
    f:close()
    return M.compile(t, env)
end

return M
