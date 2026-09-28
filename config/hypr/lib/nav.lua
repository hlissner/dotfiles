-- config/hypr/lib/nav.lua

local util      = require("lib/util")
local workspace = require("lib/workspace")

local M = {}

local FORWARD = workspace.FORWARD
local ALONG   = { left = "x", right = "x", up = "y", down = "y" }
local ACROSS  = { x = "y", y = "x" }
local SPAN    = { x = "w", y = "h" }

local function step(dir)
  return FORWARD[dir] and 1 or -1
end

-- MON in layout coordinates, which is where windows live. Its mode is in
-- pixels, and from before it was rotated.
local function box(mon)
  local w, h = mon.width / mon.scale, mon.height / mon.scale
  if mon.transform % 2 == 1 then w, h = h, w end
  return { x = mon.x, y = mon.y, w = w, h = h }
end

-- The monitor DIR of MON. hl.get_monitor(dir) would do if it didn't count from
-- the focused monitor, which under follow_mouse = 2 is wherever the cursor
-- wandered off to, not where the window is.
local function monitor_toward(mon, dir)
  local a, along = box(mon), ALONG[dir]
  local across = ACROSS[along]
  local best, gap
  for _, m in ipairs(hl.get_monitors() or {}) do
    local b = box(m)
    local d = FORWARD[dir] and b[along] - (a[along] + a[SPAN[along]])
                            or a[along] - (b[along] + b[SPAN[along]])
    if m.id ~= mon.id and d > -1
       and b[across] < a[across] + a[SPAN[across]]
       and a[across] < b[across] + b[SPAN[across]]
       and (not gap or d < gap) then
      best, gap = m, d
    end
  end
  return best
end

-- W's column, if it's tiled on a scrolling tape. Floats have no layout, and
-- the other layouts have no columns.
local function column(w)
  return w and not w.floating and w.layout and w.layout.column or nil
end

-- WS's tape: its columns in order, each one's windows top to bottom.
local function columns(ws)
  local cols = {}
  for _, w in ipairs(hl.get_workspace_windows(ws) or {}) do
    local col = not w.hidden and column(w)
    if col then
      cols[col.index + 1] = cols[col.index + 1] or {}
      table.insert(cols[col.index + 1], w)
    end
  end
  for _, c in ipairs(cols) do
    table.sort(c, function(a, b) return a.layout.index_in_column < b.layout.index_in_column end)
  end
  return cols
end

-- Whichever of WINDOWS shares the most of W's span across DIR, or failing
-- that, sits nearest it. Hyprland's findBestNeighbor, minus its memory of
-- which one had focus last, which Lua can't see.
local function facing(windows, w, dir)
  if not w then return windows[1] end
  local ax = ACROSS[ALONG[dir]]
  local best, most
  for _, o in ipairs(windows) do
    local shared = math.min(o.at[ax] + o.size[ax], w.at[ax] + w.size[ax])
                 - math.max(o.at[ax], w.at[ax])
    if not most or shared > most then best, most = o, shared end
  end
  return best
end

-- What's showing nearest the edge of MON we come in by, heading DIR. A column
-- scrolled off past that edge doesn't count: it's further away than the one on
-- screen, whatever the tape says.
local function entry(mon, dir, w)
  local ws = util.active_workspace(mon)
  local b, along = box(mon), ALONG[dir]
  local edge = FORWARD[dir] and b[along] or b[along] + b[SPAN[along]]
  local near, dist = {}, nil
  for _, o in ipairs(ws and hl.get_workspace_windows(ws) or {}) do
    if not o.hidden
       and o.at.x < b.x + b.w and b.x < o.at.x + o.size.x
       and o.at.y < b.y + b.h and b.y < o.at.y + o.size.y then
      local lead = FORWARD[dir] and o.at[along] or o.at[along] + o.size[along]
      local d = math.max(0, step(dir) * (lead - edge))
      if not dist or d < dist - 1 then
        near, dist = { o }, d
      elseif d <= dist + 1 then
        near[#near + 1] = o
      end
    end
  end
  return facing(near, w, dir)
end

local function elsewhere(w)
  local mon = hl.get_active_monitor()
  return w.monitor and not (mon and mon.id == w.monitor.id)
end

-- Focusing a window switches to its workspace first, unless the focused
-- monitor's already showing it. A regular workspace is switched on the
-- monitor that owns it; a scratchpad gets dragged over to this one instead.
-- So go to its monitor before the window.
local function focus(target)
  if elsewhere(target) then
    hl.dispatch(hl.dsp.focus({ monitor = target.monitor }))
  end
  hl.dispatch(hl.dsp.focus({ window = target }))
  return true
end

-- r±1 counts from the focused monitor, and layout messages go to its
-- workspace. Under follow_mouse = 2 that's the cursor's, not the window's.
local function claim(w)
  if w and elsewhere(w) then focus(w) end
end

-- Walk W's column to index TO, clamped to the tape. swapcol only ever trades
-- places with a neighbour, so count the steps out rather than looping until
-- nothing changes -- scrolling:wrap_swapcol sends column 0 to the far end
-- instead of refusing, and that loop never ends.
local function slide(w, to)
  local col = column(w)
  if not col then return false end
  local from = col.index
  to = util.clamp(to, 0, #columns(w.workspace) - 1)
  claim(w)
  for _ = 1, math.abs(to - from) do
    hl.dispatch(hl.dsp.layout(to > from and "swapcol r" or "swapcol l"))
  end
  return to ~= from
end

-- Settle W, just carried in heading DIR, on the near side of ANCHOR: before it
-- coming in from the left, after it from the right. Hyprland parks it after
-- whatever the cursor was over, or at the end of the tape.
local function beside(w, anchor, dir)
  local a, c = column(anchor), column(w)
  if not (a and c) or anchor.workspace.name ~= w.workspace.name then return end
  -- Where ANCHOR sits once W's out of the way.
  local at = a.index - (c.index < a.index and 1 or 0)
  slide(w, FORWARD[dir] and at or at + 1)
end

-- Off the side of MON, onto whatever's nearest on the other one.
local function focus_monitor(w, mon, dir)
  local to = mon and monitor_toward(mon, dir)
  if not to then return false end
  local target = entry(to, dir, w)
  if target then return focus(target) end
  hl.dispatch(hl.dsp.focus({ monitor = to.name }))
  return true
end

-- CROSSING, if given, is told just before W leaves MON for good.
local function move_monitor(w, mon, dir, crossing)
  local to = mon and monitor_toward(mon, dir)
  if not (w and to) then return false end
  local anchor = entry(to, dir, w)
  if crossing then crossing(mon, to) end
  hl.dispatch(hl.dsp.window.move({ monitor = to.name }))
  if anchor then beside(w, anchor, dir) end
  return true
end

-- Coming into WS heading DIR from column IDX: the same column, or the last one
-- if its tape is shorter, at the end of it we came in by.
local function arrival(ws, idx, dir)
  local cols = columns(ws)
  local col = idx and cols[math.min(idx + 1, #cols)]
  return col and (FORWARD[dir] and col[1] or col[#col])
end

local function hop(w, ws, dir)
  local col = column(w)
  local target = arrival(ws, col and col.index, dir)
  if target then return focus(target) end
  hl.dispatch(hl.dsp.focus({ workspace = ws }))
  return true
end

-- Into WS, keeping W's place: a column of its own, at the index it had.
local function send(w, ws)
  local col = column(w)
  local idx = col and col.index
  hl.dispatch(hl.dsp.window.move({ workspace = ws, window = w }))
  if idx then slide(w, idx) end
  return true
end

-- The furthest workspace DIR of WS on MON's tape with anything on it.
local function furthest(mon, ws, dir)
  local t, at = workspace.tape(mon), nil
  for i, o in ipairs(t) do
    -- By name: named workspaces have no id to compare.
    if o.name == ws.name then at = i end
  end
  if not at then return nil end
  local from, to, by = #t, at + 1, -1
  if not FORWARD[dir] then from, to, by = 1, at - 1, 1 end
  for i = from, to, by do
    if t[i].windows > 0 then return t[i] end
  end
end

-- Is there anywhere on the tape for W to go DIR, or is this the edge where it's
-- handed to the next monitor instead? Up/down stop at the ends of the stack,
-- left/right at the ends of the tape, unless W's stacked: then it has a column
-- of its own to step out into first. Assumes the default scrolling:direction.
local function stays(w, col, dir)
  if dir == "up"   then return w.layout.index_in_column > 0 end
  if dir == "down" then return w.layout.index_in_column < #col.windows - 1 end
  if #col.windows > 1 then return true end
  if dir == "left" then return col.index > 0 end
  return col.index < #columns(w.workspace) - 1
end

-- Out of W's stack into a column of its own on the DIR side of it, or if it's
-- alone, into the neighbour's stack. Without a neighbour, Hyprland refuses.
local function shuffle(w, dir)
  claim(w)
  hl.dispatch(hl.dsp.layout("consume_or_expel " .. (FORWARD[dir] and "next" or "prev")))
end

-- The window at the DIR end of W's tape; nil if W's already in that column.
local function far_end(w, ws, dir)
  local col = column(w)
  if not col then return nil end
  local cols = columns(ws)
  local last = FORWARD[dir] and #cols or 1
  if col.index + 1 == last then return nil end
  return facing(cols[last] or {}, w, dir)
end

-- The window to act on and where it is. Without one, the focused monitor,
-- which is where the next one would go anyway.
local function here()
  local w = hl.get_active_window()
  local mon = w and w.monitor or hl.get_active_monitor()
  return w, mon, w and w.workspace or util.active_workspace(mon)
end

-- Each of these returns whether it did anything, for the overview's sake.

-- hjkl: the window DIR of this one. Off the side of the tape, the next monitor
-- over; off the end of a column, the next workspace along the tape, or one
-- fresh one past its end. Only one: an empty workspace is already the void,
-- and it'll die on its own once we look away from it. Scratchpads aren't on
-- the tape.
function M.focus(dir)
  return function()
    local w, mon, ws = here()
    local col = column(w)
    if col then
      local cols = columns(ws)
      local target
      if ALONG[dir] == "x" then
        target = facing(cols[col.index + 1 + step(dir)] or {}, w, dir)
      else
        target = cols[col.index + 1][w.layout.index_in_column + 1 + step(dir)]
      end
      if target then return focus(target) end
    elseif w and util.window_toward(w, dir) then
      -- Floats and the other layouts can have Hyprland's opinion, once I know
      -- there's something to find; without one it wanders off to the next
      -- monitor on its own.
      hl.dispatch(hl.dsp.focus({ direction = dir }))
      return true
    end
    if ALONG[dir] == "x" then return focus_monitor(w, mon, dir) end
    if not (mon and ws) or ws.special then return false end
    local to = workspace.neighbour(mon, dir)
    if to then return hop(w, to, dir) end
    if ws.windows == 0 then return false end
    claim(w)
    hl.dispatch(hl.dsp.focus({ workspace = workspace.slot(dir) }))
    -- r±1 clamps rather than failing, so ask whether it went anywhere.
    local now = util.active_workspace(mon)
    return now ~= nil and now.name ~= ws.name
  end
end

-- SHIFT+hjkl: the same ladder with the window in tow. Sideways, a stacked
-- window steps out of its stack first, then trades places with whole columns;
-- it never joins one, that's TAB's job. The void has one more rule: a window
-- alone on a workspace that dies without it would only trade it for a fresh
-- one, over and over.
function M.move(dir, crossing)
  return function()
    local w, mon, ws = here()
    if not w then return false end
    local col = column(w)
    local within
    if col then within = stays(w, col, dir) else within = util.window_toward(w, dir) ~= nil end
    if within then
      if col and ALONG[dir] == "x" then
        if #col.windows > 1 then shuffle(w, dir) else slide(w, col.index + step(dir)) end
      else
        hl.dispatch(hl.dsp.window.move({ direction = dir }))
      end
      return true
    end
    if ALONG[dir] == "x" then return move_monitor(w, mon, dir, crossing) end
    if ws.special then return false end
    local to = workspace.neighbour(mon, dir)
    if to then return send(w, to) end
    if ws.windows <= 1 and not ws.is_persistent then return false end
    claim(w)
    return workspace.grow(w, dir)
  end
end

-- CTRL+h/l: the far end of the tape, and once there, the next monitor. j/k:
-- the last workspace that way with anything on it.
function M.focus_end(dir)
  return function()
    local w, mon, ws = here()
    if ALONG[dir] == "y" then
      local to = mon and ws and not ws.special and furthest(mon, ws, dir)
      return to and hop(w, to, dir) or false
    end
    local target = far_end(w, ws, dir)
    if target then return focus(target) end
    return focus_monitor(w, mon, dir)
  end
end

-- CTRL+SHIFT+hjkl: the same, with the window in tow. Anything stacked is
-- promoted out first, so what lands at the edge is the window and not the pile
-- it was sitting in.
function M.move_end(dir, crossing)
  return function()
    local w, mon, ws = here()
    if not w then return false end
    if ALONG[dir] == "y" then
      local to = not ws.special and furthest(mon, ws, dir)
      return to and send(w, to) or false
    end
    local col = column(w)
    if col then
      local promoted = #col.windows > 1
      if promoted then
        claim(w)
        hl.dispatch(hl.dsp.layout("promote"))
      end
      if slide(w, FORWARD[dir] and math.huge or 0) or promoted then return true end
    end
    return move_monitor(w, mon, dir, crossing)
  end
end

-- TAB: the window alone, left or right, into, out of, and through the stacks
-- beside it, one step at a time. Stops at the ends of the tape.
function M.shuffle(dir)
  return function()
    local w = hl.get_active_window()
    local col = column(w)
    if not col then return false end
    local last = #columns(w.workspace) - 1
    if #col.windows == 1 and col.index == (FORWARD[dir] and last or 0) then
      return false
    end
    shuffle(w, dir)
    return true
  end
end

return M
