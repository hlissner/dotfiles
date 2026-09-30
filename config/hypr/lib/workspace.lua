-- config/hypr/lib/workspace.lua

local M = {}

local FORWARD = { right = true, down = true }
M.FORWARD = FORWARD

-- Which workspace each monitor calls home, by monitor name. Lua can't
-- enumerate workspace rules, so eavesdrop on them instead. Only hears rules
-- made after this file loads, which is why it's the first thing hyprland.lua
-- requires.
M.homes = {}
local workspace_rule = hl.workspace_rule
function hl.workspace_rule(spec)
  local id = tonumber(spec.workspace)
  if spec.default and spec.monitor and id and not M.homes[spec.monitor] then
    M.homes[spec.monitor] = id
  end
  return workspace_rule(spec)
end

-- MON's workspaces in the order the overview tapes them together: no
-- scratchpads, named ones first (by name, since they have no id), then the
-- numbered ones numerically. Worth copying exactly -- "the last one down" has
-- to mean the same thing to both of us.
function M.tape(mon)
  local out = {}
  for _, ws in ipairs(hl.get_workspaces() or {}) do
    if not ws.special and ws.monitor and ws.monitor.id == mon.id then
      out[#out + 1] = ws
    end
  end
  table.sort(out, function(a, b)
    if a.id and b.id then return a.id < b.id end
    if (a.id == nil) ~= (b.id == nil) then return a.id == nil end
    return a.name < b.name
  end)
  return out
end

-- The workspace one step DIR of MON's, nil at the end of the tape.
function M.neighbour(mon, dir)
  local cur = hl.get_active_workspace(mon)
  if not cur then return nil end
  local t = M.tape(mon)
  for i, ws in ipairs(t) do
    -- By name: named workspaces have no id to compare.
    if ws.name == cur.name then return t[FORWARD[dir] and i + 1 or i - 1] end
  end
end

-- Past the end of the tape, let Hyprland pick the slot: r±1 is "the next
-- workspace on this monitor, counting the ids nothing has claimed yet", and
-- it's the only thing in reach that knows which of those ids a workspace rule
-- has already promised to a different monitor (Lua can't enumerate the rules).
-- It clamps instead of wrapping at the ends -- nothing lives below id 1, which
-- is why the main monitor starts at 100 -- so ask afterwards whether the
-- window actually went anywhere.
function M.slot(dir)
  return FORWARD[dir] and "r+1" or "r-1"
end

function M.grow(w, dir)
  local before = w.workspace and w.workspace.name
  hl.dispatch(hl.dsp.window.move({ workspace = M.slot(dir), window = w }))
  return w.workspace ~= nil and w.workspace.name ~= before
end

-- For my Noctalia compass plugin. Emits:
--
--   NAME HOPS NORTH SOUTH WEST EAST SPECIAL FOCUSED
--
-- HOPS is how far the active workspace sits from home, in *tape* steps rather
-- than ids (positive = home is north). NORTH/SOUTH (bool): does an occupied
-- workspace exist that way? WEST/EAST (bool): are there tiled windows beyond
-- the edge of the screen?  SPECIAL (bool): Is the special workspace active?
-- FOCUSED (bool): is this the focused monitor?
--
-- Read via `hyprctl repl` (by config/noctalia/plugins/compass/service.luau), so
-- everything is treated as a string.
function M.compass()
  local out = {}
  for _, mon in ipairs(hl.get_monitors() or {}) do
    local cur = mon.enabled ~= false and hl.get_active_workspace(mon)
    if cur then
      local t, at, home = M.tape(mon), nil, nil
      for i, ws in ipairs(t) do
        if ws.name == cur.name then at = i end
        if ws.id and ws.id == M.homes[mon.name] then home = i end
      end
      local hops, north, south = 0, false, false
      if at then
        if home then hops = at - home end
        for i, ws in ipairs(t) do
          if ws.windows > 0 then
            if i < at then north = true elseif i > at then south = true end
          end
        end
      end

      local special = hl.get_active_special_workspace(mon)
      local shown = special or cur
      local west, east = false, false
      if not shown.has_fullscreen then
        -- x/width are logical; `at` sits a border's width inside the monitor.
        local left = mon.x
        local right = left + (mon.transform % 2 == 1 and mon.height or mon.width) / mon.scale
        for _, w in ipairs(hl.get_workspace_windows(shown) or {}) do
          if w.mapped and not w.floating then
            if w.at.x < left - 4 then west = true end
            if w.at.x + w.size.x > right + 4 then east = true end
          end
        end
      end

      out[#out + 1] = string.format("%s %d %d %d %d %d %d %d", mon.name, hops,
        north and 1 or 0, south and 1 or 0, west and 1 or 0, east and 1 or 0,
        special and 1 or 0, mon.focused and 1 or 0)
    end
  end
  return table.concat(out, "\n")
end

-- Recover Hyprland in the case a monitor has ended up showing a workspace it
-- doesn't own.
function M.rehome()
  local win, mon = hl.get_active_window(), hl.get_active_monitor()
  local touched = false
  for _, m in ipairs(hl.get_monitors() or {}) do
    local ws = hl.get_active_workspace(m)
    if ws and not (ws.monitor and ws.monitor.id == m.id) then
      local t, home = M.tape(m), nil
      for _, o in ipairs(t) do
        if o.id and o.id == M.homes[m.name] then home = o end
      end
      home = home or t[1]
      -- Nothing of its own to go back to, and nowhere safe to make one: a
      -- fresh workspace lands on the focused monitor, which this might not be.
      if home then
        hl.dispatch(hl.dsp.focus({ workspace = home.name }))
        touched = true
      end
    end
  end
  for _, m in ipairs(hl.get_monitors() or {}) do
    local ws = hl.get_active_workspace(m)
    if ws and not ws.special and not ws.visible then
      hl.dispatch(hl.dsp.focus({ monitor = m.name }))
      hl.dispatch(hl.dsp.focus({ workspace = M.slot("down") }))
      hl.dispatch(hl.dsp.focus({ workspace = ws.name }))
      touched = true
    end
  end
  if not touched then return end
  if win then
    hl.dispatch(hl.dsp.focus({ window = win }))
  elseif mon then
    hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
  end
end

-- Close the gaps a day of growing and emptying workspaces leaves in each
-- monitor's tape, back towards its home: 204, 206, 211 and 241 become 200-203,
-- and anything north of home packs up against it. Left alone, a long session
-- only drifts further out, until it runs into another monitor's tape or into
-- 1, north of which nothing can grow. Persistent workspaces stay put -- their
-- rule would only make a fresh one -- and named ones have no id to change.
function M.compact()
  for _, mon in ipairs(hl.get_monitors() or {}) do
    -- Everything another monitor has, or will have once it's plugged in.
    local taken, mine, lowest = {}, {}, nil
    for name, id in pairs(M.homes) do
      if name ~= mon.name then taken[id] = true end
    end
    -- Refetched per monitor, since the last one just moved things around.
    for _, ws in ipairs(hl.get_workspaces() or {}) do
      if ws.id and not ws.special then
        if ws.monitor and ws.monitor.id == mon.id then
          lowest = math.min(lowest or ws.id, ws.id)
          if ws.is_persistent then taken[ws.id] = true else mine[#mine + 1] = ws end
        else
          taken[ws.id] = true
        end
      end
    end
    table.sort(mine, function(a, b) return a.id < b.id end)
    -- A monitor no rule sent home collapses towards wherever it's got to.
    local anchor = M.homes[mon.name] or lowest

    -- Home and south pack down towards home, north packs up towards it. Each
    -- target is at or between a workspace and home, and everything already
    -- there has moved out of the way, so change_id never finds it taken.
    local south, north = {}, {}
    for _, ws in ipairs(mine) do
      if ws.id >= anchor then south[#south + 1] = ws else table.insert(north, 1, ws) end
    end
    local function pack(tape, id, step)
      for _, ws in ipairs(tape) do
        while taken[id] do id = id + step end
        if ws.id ~= id then
          hl.dispatch(hl.dsp.workspace.change_id({ workspace = tostring(ws.id), id = id }))
        end
        id = id + step
      end
    end
    if anchor then
      pack(south, anchor, 1)
      pack(north, anchor - 1, -1)
    end
  end
end

return M
