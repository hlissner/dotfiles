-- config/hypr/lib/dsp.lua

local util = require("lib/util")

local M = {}

-- Nudge cursor zoom by RATIO, within 1x-3x. 0 resets.
function M.zoom(ratio)
  return function()
    local zoom = ratio == 0 and 1 or util.clamp(hl.get_config("cursor:zoom_factor") + ratio, 1, 3)
    hl.config({ cursor = { zoom_factor = zoom } })
  end
end

-- Upstream warning: "It is NOT recommended to set DPMS or forceidle with a
-- keybind directly, as it might cause undefined behavior. Instead, consider
-- something like..."
function M.dpms(state)
  return function()
    hl.timer(function()
      hl.dispatch(hl.dsp.dpms({ action = state and "enable" or "disable" }))
    end, { timeout = 500, type = "oneshot" })
  end
end

-- Clamp audio increment/decrement to the nearest multiple of STEP in the
-- direction it's being adjusted. OCD-maxxing.
local function snap_volume(dir, step, read, set)
  return hl.dsp.exec_cmd(
    -- Do arithmetic in the shell to spare us the IPC cost of reading the volume
    -- first (hurts if you hold down the key).
    "v=$(" .. read .. "); [ -n \"$v\" ] || exit 0; s=" .. (step or 10) .. "; " ..
    "if [ " .. dir .. " = up ]; then n=$((v - v % s + s)); " ..
    "else r=$((v % s)); [ \"$r\" -eq 0 ] && r=$s; n=$((v - r)); fi; " ..
    "[ \"$n\" -lt 0 ] && n=0; [ \"$n\" -gt 100 ] && n=100; " ..
    set .. " \"$n\"")
end

function M.volume(dir, step)
  return snap_volume(dir, step,
    [[dms ipc audio status | sed -n 's/^Output: \([0-9]*\)%.*/\1/p']],
    "dms ipc audio setvolume")
end

-- Requires playerctl
function M.player_volume(dir, step)
  return snap_volume(dir, step,
    [[playerctl volume | awk '{printf "%d", $1 * 100}']],
    "dms ipc mpris setvolume")
end

-- One bind, a dispatcher per layout.
function M.layout(by_layout)
  return function()
    local layout = util.active_layout()
    if not layout then return end
    if by_layout[layout] then
      hl.dispatch(by_layout[layout])
    else
      hl.exec_cmd([[dms ipc toast error "No keybind for ]] .. layout .. [[ layout"]])
    end
  end
end

-- toggle_special on scratchpads that's already on another monitor drags it over
-- to this one. I'd rather we go to it, instead! Only if it's focused does it
-- dismiss it.
function M.scratchpad(name)
  local special = "special:" .. name
  return function()
    -- Which monitor is actually showing it. ws.monitor is deceptive; a hidden
    -- scratchpad still names the monitor it was last shown on.
    local host, ws
    for _, m in ipairs(hl.get_monitors() or {}) do
      ws = m.active_special_workspace
      if ws and ws.name == special then host = m break end
    end

    -- By name: named workspaces have no id to compare.
    local win = host and hl.get_active_window()
    local inside = win and win.workspace and win.workspace.name == special
    if not win or inside then
      hl.dispatch(hl.dsp.workspace.toggle_special(name))
      return
    end

    local go = host.focused and hl.dsp.focus({ window = ws.last_window })
    hl.dispatch(go or hl.dsp.focus({ monitor = host }))
  end
end

-- Resize the active window to SPEC: a fraction of the monitor's usable width,
-- or pixels if > 1. Each layout has its own idea of width.
function M.resize_width_to(spec)
  return function()
    local w = hl.get_active_window()
    local m = w and w.monitor
    if not m then return end
    local usable = m.width / m.scale - m.reserved.left - m.reserved.right
    local px = spec > 1 and spec or usable * spec
    local frac = util.clamp(px / usable, 0.1, 1)
    local layout = not w.floating and util.active_layout()
    if layout == "scrolling" then
      hl.dispatch(hl.dsp.layout("colresize " .. frac))
    elseif layout == "master" then
      hl.dispatch(hl.dsp.layout("mfact exact " .. (w.layout.is_master and frac or 1 - frac)))
    else
      hl.dispatch(hl.dsp.window.resize({ x = math.floor(px), y = w.size.y }))
    end
  end
end

return M
