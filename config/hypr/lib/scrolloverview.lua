-- config/hypr/lib/scrolloverview.lua

local so = hl.plugin.scrolloverview

local M = {}

local FORWARD = { right = true, down = true }
local AXIS    = { left = "x", right = "x", up = "y", down = "y" }

-- The overview is a modal thing with no status line; a keypress that did
-- nothing looks exactly like one that worked.
local function fail()
  hl.dispatch(hl.dsp.exec_cmd("hey .play-sound error"))
end

-- Whether the overview's selection moved. It publishes nothing -- its
-- navigate dispatcher drops the bool moveSelection() hands back -- but
-- selecting means focusing: it ends in a fullWindowFocus() and swaps the
-- monitor's active workspace under it. So ask Hyprland instead.
local function selection()
  local m, ws, w = hl.get_active_monitor(), hl.get_active_workspace(), hl.get_active_window()
  return table.concat({ m and m.id or "", ws and ws.name or "", w and tostring(w.address) or "" }, "\0")
end

-- Which way the overview stacks workspaces. "auto" is the monitor's own
-- orientation, off the logical box -- so a monitor rotated into portrait
-- counts as one even though its mode is still landscape.
local function workspace_axis(mon)
  local layout = hl.get_config("plugin:scrolloverview:layout")
  if layout == "auto" then
    local w, h = mon.width, mon.height
    if mon.transform % 2 == 1 then w, h = h, w end
    layout = h > w and "horizontal" or "vertical"
  end
  return layout == "horizontal" and "x" or "y"
end

-- MON's workspaces in the order the overview tapes them together: no
-- scratchpads, named ones first (by name, since they have no id), then the
-- numbered ones numerically. Worth copying exactly -- "the last one down" has
-- to mean the same thing to both of us.
local function tape(mon)
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

-- The workspace one step DIR of the focused one, nil at the end of the tape.
local function neighbour(mon, dir)
  local cur = hl.get_active_workspace()
  if not cur then return nil end
  local t = tape(mon)
  for i, ws in ipairs(t) do
    -- By name: named workspaces have no id to compare.
    if ws.name == cur.name then return t[FORWARD[dir] and i + 1 or i - 1] end
  end
end

-- The scrolling layout won't say how many columns it has, so count the
-- indices its windows report. Floats aren't in one and have no layout.
local function column_count(ws)
  local n = 0
  for _, w in ipairs(hl.get_workspace_windows(ws) or {}) do
    local col = w.layout and w.layout.column
    if col and col.index >= n then n = col.index + 1 end
  end
  return n
end

-- Would the scrolling layout move W one step DIR itself, or is this the edge
-- where it hands the window to the next monitor instead? Mirrors
-- CScrollingAlgorithm::moveTargetTo: left/right only refuse for a window
-- alone at the end of the tape (a stacked one always gets a column of its
-- own), up/down stop at the ends of the stack. Assumes the default
-- scrolling:direction; set it to "left" or "up" and these swap meanings.
local function moves_in_layout(w, dir)
  local col = w.layout and w.layout.column
  if not col then return false end
  if dir == "up"   then return w.layout.index_in_column > 0 end
  if dir == "down" then return w.layout.index_in_column < #col.windows - 1 end
  if #col.windows > 1 then return true end
  if dir == "left" then return col.index > 0 end
  return col.index < column_count(w.workspace) - 1
end

-- Walk W's column to the DIR end of the tape. swapcol only ever trades places
-- with its neighbour, so count the steps out rather than looping until
-- nothing changes -- scrolling:wrap_swapcol sends column 0 to the far end
-- instead of refusing, and that loop never ends. Anything stacked is promoted
-- out first, so what lands at the edge is the window and not the pile it was
-- sitting in.
local function slide_to_end(w, dir)
  local col = w.layout and w.layout.column
  if not col then return false end
  local moved = false
  if #col.windows > 1 then
    hl.dispatch(hl.dsp.layout("promote"))
    moved = true
    w = hl.get_active_window()
    col = w and w.layout and w.layout.column
    if not col then return moved end
  end
  local steps = FORWARD[dir] and column_count(w.workspace) - 1 - col.index or col.index
  for _ = 1, steps do
    hl.dispatch(hl.dsp.layout(FORWARD[dir] and "swapcol r" or "swapcol l"))
  end
  return moved or steps > 0
end

-- Past the end of the tape, let Hyprland pick the slot: r±1 is "the next
-- workspace on this monitor, counting the ids nothing has claimed yet", and
-- it's the only thing in reach that knows which of those ids a workspace rule
-- has already promised to a different monitor (Lua can't enumerate the rules).
-- It clamps instead of wrapping at the ends -- nothing lives below id 1, which
-- is why the main monitor starts at 100 -- so ask afterwards whether the
-- window actually went anywhere.
local function slot(dir)
  return FORWARD[dir] and "r+1" or "r-1"
end

local function grow(w, dir)
  local before = w.workspace and w.workspace.name
  hl.dispatch(hl.dsp.window.move({ workspace = slot(dir), window = w }))
  return w.workspace ~= nil and w.workspace.name ~= before
end

-- hjkl: let the plugin have the key first, and if the selection didn't budge
-- we were against an edge -- go looking for a monitor that way, else step off
-- the end of the tape into a fresh workspace. Only one: an empty workspace is
-- already the void, and it'll die on its own once we look away from it.
function M.navigate(dir)
  return function()
    local before = selection()
    -- so.navigate() hands back a closure unless something is already inside a
    -- bind, where it runs instead. _dispatch is the half that always means now.
    so._dispatch("navigate", dir)
    if selection() ~= before then return end
    local mon, ws = hl.get_active_monitor(), hl.get_active_workspace()
    if hl.get_monitor(dir) then
      hl.dispatch(hl.dsp.focus({ monitor = dir }))
    elseif mon and ws and ws.windows > 0
        and AXIS[dir] == workspace_axis(mon)
        and not neighbour(mon, dir) then
      hl.dispatch(hl.dsp.focus({ workspace = slot(dir) }))
    end
  end
end

-- SHIFT+hjkl: the ladder navigate climbs, with the window in tow -- one step
-- in the layout, else one workspace, else one monitor, else a workspace that
-- didn't exist a moment ago. Growing goes last so that a monitor below still
-- wins the way it does for plain j/k; it only ever replaces the dead end.
-- Nothing tidies up the workspace left behind, because nothing has to: an
-- empty one dies as soon as it stops being visible, and a persistent one
-- holds a reference to itself so it can't.
function M.move(dir)
  return function()
    local w, mon = hl.get_active_window(), hl.get_active_monitor()
    if not w or not mon then fail() return end
    if moves_in_layout(w, dir) then
      hl.dispatch(hl.dsp.window.move({ direction = dir }))
      return
    end
    local axis = AXIS[dir] == workspace_axis(mon)
    local ws = axis and neighbour(mon, dir)
    if ws then
      hl.dispatch(hl.dsp.window.move({ workspace = ws }))
    elseif hl.get_monitor(dir) then
      hl.dispatch(hl.dsp.window.move({ monitor = dir }))
    elseif not (axis and grow(w, dir)) then
      fail()
    end
  end
end

-- CTRL+SHIFT+hjkl: throw the window at the far end of this monitor -- the
-- head or tail of the column tape, the first or last workspace -- and once
-- it's already sitting there, at the next monitor.
function M.move_to_edge(dir)
  return function()
    local w, mon = hl.get_active_window(), hl.get_active_monitor()
    if not w or not mon then fail() return end
    local moved
    if AXIS[dir] == workspace_axis(mon) then
      local t = tape(mon)
      local ws = FORWARD[dir] and t[#t] or t[1]
      moved = ws and w.workspace and ws.name ~= w.workspace.name
      if moved then hl.dispatch(hl.dsp.window.move({ workspace = ws })) end
    else
      moved = slide_to_end(w, dir)
    end
    if moved then return end
    if hl.get_monitor(dir) then
      hl.dispatch(hl.dsp.window.move({ monitor = dir }))
    else
      fail()
    end
  end
end

return M
