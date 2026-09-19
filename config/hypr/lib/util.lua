-- config/hypr/lib/util.lua

hey.dsp = {}

function hey.dsp.zoomIn(ratio)
  return function()
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if ratio == 0.0 then
      hl.config({ cursor = { zoom_factor = 1.0 } })
    elseif (zoomvalue + ratio) > 3.0 then
      hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + ratio) < 1.0 then
      hl.config({ cursor = { zoom_factor = 1.0 } })
    else
      hl.config({ cursor = { zoom_factor = zoomvalue + ratio } })
    end
  end
end

-- Upstream warning: "It is NOT recommended to set DPMS or forceidle with a
-- keybind directly, as it might cause undefined behavior. Instead, consider
-- something like..."
function hey.dsp.dpms(state)
  return function()
    hl.timer(function()
               hl.dispatch(hl.dsp.dpms({ action = state and "enable" or "disable" }))
             end, { timeout = 500, type = "oneshot"})
  end
end

-- Clamp audio increment/decrement to the nearest multiple of STEP in the
-- direction it's being adjusted. OCD-maxxing.
local function snap_volume(dir, step, read, set)
  return hl.dsp.exec_cmd(
    -- Do arithmetic in the shell to spare us the IPC cost of reading the
    -- current volume first. Terrible if you hold down the key.
    "v=$(" .. read .. "); [ -n \"$v\" ] || exit 0; s=" .. (step or 10) .. "; " ..
    "if [ " .. dir .. " = up ]; then n=$((v - v % s + s)); " ..
    "else r=$((v % s)); [ \"$r\" -eq 0 ] && r=$s; n=$((v - r)); fi; " ..
    "[ \"$n\" -lt 0 ] && n=0; [ \"$n\" -gt 100 ] && n=100; " ..
    set .. " \"$n\"")
end

function hey.dsp.volume(dir, step)
  return snap_volume(dir, step,
    [[dms ipc audio status | sed -n 's/^Output: \([0-9]*\)%.*/\1/p']],
    "dms ipc audio setvolume")
end

-- Requires playerctl
function hey.dsp.player_volume(dir, step)
  return snap_volume(dir, step,
    [[playerctl volume | awk '{printf "%d", $1 * 100}']],
    "dms ipc mpris setvolume")
end

function hey.dsp.layout(bind_table)
  return function()
    local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not ws then return end
    local layout = ws.tiled_layout
    if bind_table[layout] then
      hl.dispatch(bind_table[layout])
    else
      hl.exec_cmd([[dsp ipc toast error "No keybind for ]] .. layout .. [[ layout"]])
    end
  end
end

function hey.dsp.resize_width_to(spec)
  return function()
    local w = hl.get_active_window()
    if not w then return end
    local m = w.monitor
    if m then
      local usable = m.width / m.scale - m.reserved.left - m.reserved.right
      local frac = math.max(0.1, math.min(1.0, spec > 1 and spec / usable or spec))
      local px = spec > 1 and spec or math.floor(usable * frac)
      local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
      local layout = not w.floating and ws and ws.tiled_layout
      if layout == "scrolling" then
        hl.dispatch(hl.dsp.layout("colresize " .. frac))
      elseif layout == "master" then
        hl.dispatch(hl.dsp.layout("mfact exact " .. (w.layout.is_master and frac or 1 - frac)))
      else
        hl.dispatch(hl.dsp.window.resize({ x = px, y = w.size.y }))
      end
    end
  end
end
