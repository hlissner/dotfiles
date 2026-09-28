-- config/hypr/lib/util.lua

local M = {}

function M.clamp(x, lo, hi)
  return math.max(lo, math.min(hi, x))
end

-- Fill T's holes from D, recursively, without touching anything T already has.
function M.defaults(t, d)
  for k, v in pairs(d) do
    if t[k] == nil then
      t[k] = v
    elseif type(t[k]) == "table" and type(v) == "table" then
      M.defaults(t[k], v)
    end
  end
  return t
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

-- Some window DIR of W on its workspace. Hyprland only answers that by moving
-- focus there, so judge it by eye: overlapping W across the axis, centred past
-- it along it. Floats and tiles only look for their own kind.
function M.window_toward(w, dir)
  local along  = (dir == "up" or dir == "down") and "y" or "x"
  local across = along == "y" and "x" or "y"
  local sign   = (dir == "down" or dir == "right") and 1 or -1
  local function mid(v) return v.at[along] + v.size[along] / 2 end
  for _, o in ipairs(hl.get_workspace_windows(w.workspace) or {}) do
    if o.address ~= w.address and o.floating == w.floating and not o.hidden
       and o.at[across] < w.at[across] + w.size[across]
       and w.at[across] < o.at[across] + o.size[across]
       and sign * (mid(o) - mid(w)) > 0 then
      return o
    end
  end
end

-- What MON (the focused monitor if none) is showing: the scratchpad if one is
-- up, else the workspace. nil between workspaces.
function M.active_workspace(mon)
  mon = mon or hl.get_active_monitor()
  return mon and (mon.active_special_workspace or mon.active_workspace)
end

return M
