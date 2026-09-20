-- config/hypr/lib/gesture.lua
--
-- Trackpad actions, in the shapes hl.gesture takes. hyprland.lua mounts this
-- as hey.gesture.

local util = require("lib/util")

local M = {}

function M.per_layout(spec, actions)
  local current, fields
  local function sync(mon)
    local layout = util.active_layout(mon)
    if layout == current then return end
    -- unset only matches a gesture registered with the very same fields.
    if fields then hl.gesture(util.with(fields, { action = "unset" })) end
    current, fields = layout, nil
    local entry = actions[layout]
    if entry == nil then return end
    local wrapped = type(entry) == "table" and entry.action ~= nil
    fields = util.with(spec, wrapped and entry or { action = entry })
    hl.gesture(fields)
  end
  hl.on("monitor.focused", sync)
  local function if_focused(ws, mon)
    mon = mon or (ws and ws.monitor)
    local focused = hl.get_active_monitor()
    if mon and focused and mon.id == focused.id then sync(mon) end
  end
  hl.on("workspace.active", if_focused)
  hl.on("workspace.special_active", if_focused)
  sync()
end

-- A swipe that hops to the nearest workspace on this monitor in the direction
-- of travel, stopping at the ends (no wrapping). natural_scroll will flip the
-- direction. Uses Hyprland's swiping animation to make it look convincing.
function M.workspace_hop(opts)
  local grip = opts.natural_scroll and -1 or 1
  local threshold = opts.threshold or 100 -- px of swipe before a hop commits
  local anim = opts.animation
  local travel

  -- Nearest workspace in DIR on the same monitor, or nil at the end of the
  -- line. Named workspaces (special:term and friends) have no numeric id and
  -- should not be considered.
  local function neighbour(cur, dir)
    local best, best_gap
    for _, ws in ipairs(hl.get_workspaces() or {}) do
      local gap = ws.id and (ws.id - cur.id) * dir
      if gap and gap > 0 and (not best_gap or gap < best_gap)
         and not ws.special and ws.monitor and ws.monitor.id == cur.monitor.id then
        best, best_gap = ws, gap
      end
    end
    return best
  end

  return {
    -- start gets the same event update does a moment later, so don't count it.
    start = function() travel = 0 end,
    update = function(e) travel = travel + e.delta.x end,
    finish = function(e)
      -- Not from inside a scratchpad: it would switch the workspace underneath.
      if e.cancelled or hl.get_active_special_workspace() or math.abs(travel) < threshold then
        return
      end
      local cur = hl.get_active_workspace()
      local ws = cur and cur.id and cur.monitor and neighbour(cur, travel * grip > 0 and 1 or -1)
      if not ws then return end
      if anim then hl.animation(util.with(anim, { style = opts.hop_style or "slide" })) end
      hl.dispatch(hl.dsp.focus({ workspace = ws }))
      if anim then hl.animation(anim) end
    end,
  }
end

return M
