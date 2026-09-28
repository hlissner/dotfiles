-- config/hypr/lib/media.lua

local M = {}

-- Clamp audio increment/decrement to the nearest multiple of STEP in the
-- direction it's being adjusted. OCD-maxxing. Do the arithmetic in the shell to
-- spare us IPC overhead (hurts especially bad if you hold the key down).
local function snap_volume(dir, step, read, set)
  local n = dir == "up" and "$((v - v % s + s))"
                         or "$((v - (v % s == 0 ? s : v % s)))"
  return hl.dsp.exec_cmd((
    [[v=$(%s); [ -n "$v" ] || exit 0; s=%d; n=%s; ]] ..
    [[[ "$n" -lt 0 ] && n=0; [ "$n" -gt 100 ] && n=100; %s]]
  ):format(read, step or 10, n, set:format("$n")))
end

function M.volume(dir, step)
  return snap_volume(dir, step,
    -- Noctalia has no volume getter, but its OSD tracks PipeWire, so it still
    -- shows for a change made behind its back.
    [[wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2 * 100}']],
    "noctalia msg volume-set %s")
end

-- Requires playerctl
function M.player_volume(dir, step)
  return snap_volume(dir, step,
    [[playerctl volume | awk '{printf "%d", $1 * 100}']],
    -- playerctl wants 0..1; snap_volume hands over 0..100.
    [[playerctl volume $(awk "BEGIN { print %s / 100 }")]])
end

return M
