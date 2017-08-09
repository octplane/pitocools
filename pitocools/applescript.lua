
M={}


function oa_key(k)
    return string.format(" key code %d \n", k)
  end

  function oa_command(cmd)
    return string.format(" keystroke \"%s\"\nkeystroke return\ndelay .1 \n", cmd)
  end


  function commands_to_oa(commands)
    local o = ""
    for k,t in pairs(commands) do
      o = o .. oa_command(t)
    end
    return o
  end

function M.load_and_run(dest)
  local commands = { "load " .. dest }

  local preamble = "osascript -e 'tell application \"PICO-8\" to activate' -e 'tell application \"System Events\" \n delay .1\n"
  local postamble = " key code 15 using control down \n end tell'"
  local whole = preamble .. commands_to_oa(commands) .. postamble
  os.execute(whole)
end

return M
