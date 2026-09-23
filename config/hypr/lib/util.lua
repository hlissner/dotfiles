-- config/hypr/lib/util.lua

local M = {}

function M.clamp(x, lo, hi)
  return math.max(lo, math.min(hi, x))
end

-- The window under POS (the cursor if none)
function M.window_at(pos)
  pos = pos or hl.get_cursor_pos()
  if not pos then return nil end
  local found, rank = nil, 0
  for _, w in ipairs(hl.get_windows() or {}) do
    local at, size = w.at, w.size
    if w.visible and w.accepts_input and not w.hidden
       and pos.x >= at.x and pos.x < at.x + size.x
       and pos.y >= at.y and pos.y < at.y + size.y then
      local r = w.pinned and 3 or w.floating and 2 or 1
      if r >= rank then found, rank = w, r end
    end
  end
  return found
end

-- The tiled layout on MON (the focused monitor if none): the scratchpad's if
-- one is up, else the workspace's. nil between workspaces.
function M.active_layout(mon)
  mon = mon or hl.get_active_monitor()
  local ws = mon and (mon.active_special_workspace or mon.active_workspace)
  return ws and ws.tiled_layout
end

return M
