--!nonstrict
-- config/noctalia/plugins/compass/service.luau
--
-- One answer for however many bars, published on the plugin's state channel
-- keyed by output name: "NAME HOPS NORTH SOUTH WEST EAST FOCUSED NORTH_NAMED
-- SOUTH_NAMED", a line per output, and only when it changed. niri has no
-- scripting to ask, so the line is derived here from its event stream. The
-- last two columns say whether the workspace next door that way has a name
-- (one `hey wm launch -n` made), which the widget paints in the special
-- palette.

local function parse(text)
  local out = {}
  for line in string.gmatch(text, "[^\n]+") do
    local f = string.split(line, " ")
    if #f >= 9 then
      out[f[1]] = {
        hops = tonumber(f[2]) or 0,
        north = f[3] == "1",
        south = f[4] == "1",
        west = f[5] == "1",
        east = f[6] == "1",
        focused = f[7] == "1",
        north_named = f[8] == "1",
        south_named = f[9] == "1",
      }
    end
  end
  return out
end

local last
local function publish(text)
  if text ~= last then
    last = text
    noctalia.state.set("compass", parse(text))
  end
end

local function bit(b)
  return b and 1 or 0
end


-- * niri

-- Returns the poll function and a refresh for onOutputsChanged. The event
-- stream opens with the full state (workspaces, then windows) and follows with
-- deltas, applied here the way niri-ipc's EventStreamState does. What the IPC
-- doesn't carry: the view's scroll offset (tile_pos_in_workspace_view is null
-- for every tiled window, and scrolling emits nothing), and a fullscreen flag.
-- So west/east are a lower bound -- lit only when the columns up to and
-- including the active one, or from it on, can't all fit the output -- and
-- fullscreen is a tile the size of the output. No special workspaces here:
-- a launched-into workspace is one like any other, just named.
local function niri()
  local ws, win = {}, {}
  local synced = false
  local streams = 0

  -- `home` is a name only so Mod+1 has somewhere to go, and so the empty
  -- workspace above it stays put; it isn't what the special palette is for.
  local function named(w)
    return w ~= nil and w.name ~= nil and w.name ~= "home"
  end

  local function compass()
    local geo, byOutput, occupied, cols = {}, {}, {}, {}
    for _, o in ipairs(noctalia.outputs()) do
      geo[o.name] = o
    end
    for _, w in pairs(ws) do
      if w.output then
        byOutput[w.output] = byOutput[w.output] or {}
        table.insert(byOutput[w.output], w)
      end
    end
    for _, w in pairs(win) do
      local id = w.workspace_id
      if id then
        occupied[id] = true
        local pos = not w.is_floating and w.layout and w.layout.pos_in_scrolling_layout
        if pos then
          cols[id] = cols[id] or {}
          cols[id][pos[1]] = w.layout.tile_size[1]
        end
      end
    end

    local names = {}
    for name in pairs(byOutput) do
      table.insert(names, name)
    end
    table.sort(names)

    local out = {}
    for _, name in ipairs(names) do
      local tape = byOutput[name]
      table.sort(tape, function(a, b)
        return a.idx < b.idx
      end)
      -- A reload reorders the named workspaces, so home is found by name; an
      -- output without one calls its top workspace home.
      local at, home = nil, 1
      for i, w in ipairs(tape) do
        if w.is_active then
          at = i
        end
        if w.name == "home" then
          home = i
        end
      end
      if at then
        local active = tape[at]
        local north, south = false, false
        for i, w in ipairs(tape) do
          if occupied[w.id] then
            if i < at then
              north = true
            elseif i > at then
              south = true
            end
          end
        end

        -- A floating active window says nothing about where the view is.
        -- Gaps and struts only add width, so ignoring them keeps this certain.
        local west, east = false, false
        local g, c = geo[name], cols[active.id]
        local aw = active.active_window_id and win[active.active_window_id]
        local pos = aw and not aw.is_floating and aw.layout.pos_in_scrolling_layout
        if g and c and pos then
          local full = aw.layout.tile_size[1] >= g.width and aw.layout.tile_size[2] >= g.height
          local before, after = 0, 0
          for i, width in pairs(c) do
            if i <= pos[1] then
              before += width
            end
            if i >= pos[1] then
              after += width
            end
          end
          west = not full and before > g.width
          east = not full and after > g.width
        end

        table.insert(out, string.format("%s %d %d %d %d %d %d %d %d", name, at - home,
          bit(north), bit(south), bit(west), bit(east), bit(active.is_focused),
          bit(named(tape[at - 1])), bit(named(tape[at + 1]))))
      end
    end
    return table.concat(out, "\n")
  end

  -- True if the event could have changed the answer. Unknown ids are tolerated:
  -- niri documents WorkspaceActiveWindowChanged arriving before the window's
  -- own WindowOpenedOrChanged, and the next event recomputes anyway.
  local function apply(ev)
    local name, p = next(ev)
    if name == "WorkspacesChanged" then
      ws = {}
      for _, w in ipairs(p.workspaces) do
        ws[w.id] = w
      end
    elseif name == "WorkspaceActivated" then
      local output = ws[p.id] and ws[p.id].output
      for _, w in pairs(ws) do
        if w.output == output then
          w.is_active = w.id == p.id
        end
        if p.focused then
          w.is_focused = w.id == p.id
        end
      end
    elseif name == "WorkspaceActiveWindowChanged" then
      if ws[p.workspace_id] then
        ws[p.workspace_id].active_window_id = p.active_window_id
      end
    elseif name == "WindowsChanged" then
      win = {}
      for _, w in ipairs(p.windows) do
        win[w.id] = w
      end
      synced = true
    elseif name == "WindowOpenedOrChanged" then
      win[p.window.id] = p.window
    elseif name == "WindowClosed" then
      win[p.id] = nil
    elseif name == "WindowLayoutsChanged" then
      for _, c in ipairs(p.changes) do
        if win[c[1]] then
          win[c[1]].layout = c[2]
        end
      end
    else
      return false
    end
    return true
  end

  -- Publishing waits for the windows dump: the workspaces alone would paint an
  -- all-dark dial for a frame, and that frame is a file on disk (widget.luau).
  local function take(ev)
    if apply(ev) and synced then
      publish(compass())
    end
  end

  -- `niri msg` is Rust and line-buffers a pipe on its own; no stdbuf. There's
  -- no exit callback and no handle, so a stream that never synced is simply
  -- opened again -- at most four, which is the host's cap per runtime. The
  -- first tick lands before a single line can have, hence `fresh`.
  local fresh = false
  local function stream()
    streams += 1
    fresh = true
    noctalia.runStream("niri msg -j event-stream", function(line)
      local ev = noctalia.json.decode(line)
      if type(ev) == "table" then
        take(ev)
      end
    end)
  end

  -- The poll is only insurance against a stream that died, which in practice
  -- means niri did; a bare view scroll changes nothing the IPC exposes.
  local function dump(what, event)
    noctalia.runAsync({ "niri", "msg", "-j", what }, function(result)
      local v = result.exitCode == 0 and noctalia.json.decode(result.stdout)
      if type(v) == "table" then
        take({ [event] = { [what] = v } })
      end
    end)
  end

  stream()
  return function()
    if synced then
      dump("workspaces", "WorkspacesChanged")
      dump("windows", "WindowsChanged")
    elseif fresh then
      fresh = false
    elseif streams < 4 then
      stream()
    end
    return not synced and streams < 4
  end, function()
    if synced then
      publish(compass())
    end
  end
end


-- * Entry

local poll, refresh
if noctalia.getenv("NIRI_SOCKET") ~= nil then
  poll, refresh = niri()
else
  noctalia.log("compass: not under niri; idling")
end

function update()
  local ms = noctalia.getConfig("poll_ms") or 1000
  -- There's no switching the tick off; 0 just means "only ever on events" --
  -- unless the backend is still waiting on its stream, which retries from here.
  local waiting = poll ~= nil and poll()
  noctalia.setUpdateInterval(waiting and 2000 or ms <= 0 and 3600000 or math.max(250, ms))
end

function onOutputsChanged()
  if refresh then
    refresh()
  end
end

-- A service without this gets completely restarted on any settings edit, which
-- takes the stream down with it.
function onConfigChanged()
end
