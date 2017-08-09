#! /usr/bin/env lua

function basename(str)
  local name = string.gsub(str, "(.*/)(.*)", "%2")
  return name
end

-- local cli = require("pitools/cli")
local build = require("pitocools.build")
local os = require("os")
local as = require("pitocools.applescript")

function usage()
  print([[usage:
  [-c| change_to_directory] build [path_to_template]
  [-c| change_to_directory] extract [gfx|gff|map|sfx|music] [cart] [destination]
  ]])
  os.exit(1)
end

local chdir_folder = "."
local arg_offset = 0
if arg[1] == "-c" then
  chdir_folder = arg[2]
  print("Will use " .. chdir_folder .. " as destination folder")
  arg_offset = 2
  table.remove(arg,1)
  table.remove(arg,1)
end

if #arg < 2 or  #arg > 4 then
  usage()
end


if arg[1] == "build" then
  source = arg[2]
  dest = basename(source)
  build.build(chdir_folder, source, dest)
  as.load_and_run(dest)
elseif arg[2] == "extract" then
  target = arg[2]
  source = arg[3]
  if #arg == 4 then
    dest = arg[4]
  else
    -- implicit
    dest = "includes/" .. target .. "-" .. basename(source)
  end

  dest = chdir_folder .. "/" .. dest

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
