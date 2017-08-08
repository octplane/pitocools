#! /usr/bin/env lua

-- local cli = require("pitools/cli")
local build = require("pitocools/build")
local os = require("os")

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function usage()
  print([[usage:
  build [path_to_template]
  extract [gfx|gff|map|sfx|music] [cart] [destination]
]])
  os.exit(1)
end


if #arg < 2 and #arg > 4 then
  usage()
end

if arg[1] == "build" then
  if #arg ~= 2 then usage() end
  source = arg[2]
  dest = basename(source)
  build.build(source, dest)
  function oa_key(k)
    return string.format(" key code %d \n", k)
  end

  function oa_command(cmd)
    return string.format(" keystroke \"%s\"\nkeystroke return\ndelay .1 \n", cmd)
  end

  commands = { "load " .. dest }

  function commands_to_oa(commands)
    local o = ""
    for k,t in pairs(commands) do
      o = o .. oa_command(t)
    end
    return o
  end

  local preamble = "osascript -e 'tell application \"PICO-8\" to activate' -e 'tell application \"System Events\" \n delay .1\n"
  local postamble = " key code 15 using control down \n end tell'"
  local whole = preamble .. commands_to_oa(commands) .. postamble
  os.execute(whole)
else
  if #arg ~= 3 and #arg ~=4 then usage() end
  target = arg[2]
  source = arg[3]
  if #arg == 4 then
    dest = arg[4]
  else
    dest = "includes/" .. target .. "-" .. basename(source)
  end
  print("Extracting " ..target .. " from " .. source .. " to " .. dest)
  section = "__" .. target .. "__"
  local file = io.open(source, 'r')
  local content = file:read("*a")
  section_start = string.find(content,section,1,true)
  section_end = string.find(content,"\n__%w+__\n", section_start + #section)
  data = content:sub(section_start, section_end)
  local out = io.open(dest, "w+")
  out:write("__lua__\n")
  out:write(data)
  out:close()


end
