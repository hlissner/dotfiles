-- config/hypr/lib/util.lua

local M = {}

-- Shallow copy of T with OVERRIDES on top.
function M.with(t, overrides)
  local out = {}
  for k, v in pairs(t) do out[k] = v end
  for k, v in pairs(overrides) do out[k] = v end
  return out
end

function M.clamp(x, lo, hi)
  return math.max(lo, math.min(hi, x))
end

-- The tiled layout on MON (the focused monitor if none): the scratchpad's if
-- one is up, else the workspace's. nil between workspaces.
function M.active_layout(mon)
  mon = mon or hl.get_active_monitor()
  local ws = mon and (mon.active_special_workspace or mon.active_workspace)
  return ws and ws.tiled_layout
end

return M
