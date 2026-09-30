--!nonstrict
-- config/noctalia/plugins/compass/service.luau
--
-- One question to Hyprland for however many bars, published on the plugin's
-- state channel keyed by monitor name. The answer is computed inside the
-- compositor (hey.ws.compass, config/hypr/lib/workspace.lua), because it's the
-- one that knows the tape order and where home is; this only asks and parses.

-- Anything on socket2 that could have moved a window, a workspace, or focus.
-- Not the tape itself: rolling it (the 4-finger swipe, `scroll_move`) says
-- nothing on the socket, which is what the poll below is for.
local EVENTS = {}
for _, name in ipairs({
  "workspace", "focusedmon", "activewindow", "openwindow", "closewindow",
  "movewindow", "changefloatingmode", "createworkspace", "destroyworkspace",
  "moveworkspace", "fullscreen", "monitoradded", "monitorremoved",
  "configreloaded",
}) do
  EVENTS[name] = true
  EVENTS[name .. "v2"] = true
end

local function socketPath()
  local sig = noctalia.getenv("HYPRLAND_INSTANCE_SIGNATURE")
  local runtimeDir = noctalia.getenv("XDG_RUNTIME_DIR")
  if sig == nil or runtimeDir == nil then
    return nil
  end
  return `{runtimeDir}/hypr/{sig}/.socket2.sock`
end

-- "NAME HOPS NORTH SOUTH WEST EAST SPECIAL FOCUSED", one monitor per line.
local function parse(text)
  local out = {}
  for name, hops, n, s, w, e, sp, f in string.gmatch(text, "(%S+) (%-?%d+) (%d) (%d) (%d) (%d) (%d) (%d)") do
    out[name] = {
      hops = tonumber(hops),
      north = n == "1",
      south = s == "1",
      west = w == "1",
      east = e == "1",
      special = sp == "1",
      focused = f == "1",
    }
  end
  return out
end

-- One in flight, one queued: a workspace switch is a burst of events, not one.
local last, asking, queued = nil, false, false
local ask

ask = function()
  if asking then
    queued = true
    return
  end
  asking = true

  local function done(text)
    -- A compositor whose config hasn't been reloaded since this function was
    -- born answers with an error; publish nothing rather than a stale reading.
    if text ~= last then
      last = text
      noctalia.state.set("compass", parse(text))
    end
    asking = false
    if queued then
      queued = false
      ask()
    end
  end

  local started = noctalia.runAsync({ "hyprctl", "repl", "return hey.ws.compass()" }, function(result)
    done(result.exitCode == 0 and noctalia.string.trim(result.stdout) or "")
  end)
  if not started then
    done("")
  end
end

local sock = socketPath()
if sock ~= nil then
  noctalia.runStream(`stdbuf -oL -eL socat -u UNIX-CONNECT:{sock} -`, function(line)
    local event = string.match(line, "^(%w+)>>")
    if event ~= nil and EVENTS[event] then
      ask()
    end
  end)
end

function update()
  local ms = noctalia.getConfig("poll_ms") or 1000
  -- There's no switching the tick off; 0 just means "only ever on events".
  if ms <= 0 then
    noctalia.setUpdateInterval(3600000)
    return
  end
  noctalia.setUpdateInterval(math.max(250, ms))
  ask()
end

-- A service without this gets completely restarted on any settings edit, which
-- takes the socket stream down with it.
function onConfigChanged()
end
