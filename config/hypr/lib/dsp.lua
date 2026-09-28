-- config/hypr/lib/dsp.lua

local util      = require("lib/util")
local match     = require("lib/match")

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

-- A case statement for dispatcher, basically. Go down MATCHERS and run the
-- action of the first matcher that applies. A matcher is hl.window_rule's
-- `match` table plus an `action`; anything that isn't one is an action with no
-- conditions, which is how a fallback is specified (put it last). No-op's
-- otherwise.
local function selector(name)
  local over = name == "over"
  return function(...)
    local rules = {}
    for i = 1, select("#", ...) do
      local arg, spec = select(i, ...), nil
      -- A dispatcher is a table too, but a marked one -- its metatable's
      -- __call is the "use hl.dispatch(dispatcher)" scold -- so a matcher is
      -- the bare literal.
      if type(arg) == "table" and getmetatable(arg) == nil then
        spec, arg = arg, arg.action
      end
      if arg == nil then
        error(("hey.dsp.%s: matcher %d has no action"):format(name, i), 0)
      end
      rules[#rules + 1] = { action = arg, tests = spec and match.compile(spec) }
    end

    return function()
      -- Pointing at nothing is an answer, so no falling back to focus here.
      local win
      if over then win = util.window_at() else win = hl.get_active_window() end
      -- The cursor can be parked over a monitor running a different layout.
      -- Not the window's monitor, either: a column parked off the edge of the
      -- tape belongs to the one next door. Nor the window's own workspace: an
      -- empty scratchpad has no window to ask.
      local ws = util.active_workspace(over and hl.get_monitor_at_cursor() or nil)
      local ctx = { workspace = ws, layout = ws and ws.tiled_layout }
      for _, r in ipairs(rules) do
        if not r.tests or match.ok(r.tests, win, ctx) then
          -- If it doesn't quack like a function...
          if type(r.action) == "function" then r.action(win) else hl.dispatch(r.action) end
          return
        end
      end
    end
  end
end

M.on   = selector("on")    -- tests against the currently focused app
M.over = selector("over")  -- tests against the app under the cursor

-- toggle_special on a scratchpad that's already on another monitor drags it
-- over to this one. I'd rather we go to it! Only dismiss it if it's already
-- focused.
function M.scratchpad(name)
  local special = "special:" .. name
  return function()
    -- Which monitor is actually showing it. ws.monitor is deceptive; a hidden
    -- scratchpad still names the monitor it was last shown on.
    local host, ws
    for _, m in ipairs(hl.get_monitors() or {}) do
      local w = m.active_special_workspace
      if w and w.name == special then host, ws = m, w break end
    end

    -- By name: named workspaces have no id to compare.
    local win = host and hl.get_active_window()
    if not win or (win.workspace and win.workspace.name == special) then
      hl.dispatch(hl.dsp.workspace.toggle_special(name))
    else
      -- last_window is nil for a pad that's up but empty; go to the monitor.
      local go = host.focused and ws.last_window
      hl.dispatch(hl.dsp.focus(go and { window = go } or { monitor = host }))
    end
  end
end

-- One NAME scratchpad per monitor, as special:NAME:OUTPUT. Keyed on the output
-- name, not the id; ids get reshuffled every time a monitor is replugged.
local function local_pad(name, mon)
  return name .. ":" .. mon.name
end

function M.local_scratchpad(name)
  return function()
    local m = hl.get_active_monitor()
    if m then hl.dispatch(hl.dsp.workspace.toggle_special(local_pad(name, m))) end
  end
end

-- To the pad of the monitor the window's on, which isn't necessarily the
-- focused one.
function M.move_to_local_scratchpad(name)
  return function()
    local w = hl.get_active_window()
    local m = w and w.monitor
    if m then hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. local_pad(name, m) })) end
  end
end

-- Into THERE (special:NAME by default), or back out to the workspace under it
-- if it's already in a special:NAME*. Not "m+0": that resolves against the
-- focused monitor, which follow_mouse = 2 makes the cursor's, not the window's.
function M.move_to_workspace_or_back(name, there)
  return M.on(
    { workspace = "n[s:special:" .. name .. "]",
      action = function(w)
        local ws = w.monitor and w.monitor.active_workspace
        if ws then hl.dispatch(hl.dsp.window.move({ workspace = ws })) end
      end },
    there or hl.dsp.window.move({ workspace = "special:" .. name }))
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
    local layout = not w.floating and w.workspace and w.workspace.tiled_layout
    if layout == "scrolling" then
      hl.dispatch(hl.dsp.layout("colresize " .. frac))
    elseif layout == "master" then
      local master = w.layout and w.layout.is_master
      hl.dispatch(hl.dsp.layout("mfact exact " .. (master and frac or 1 - frac)))
    else
      hl.dispatch(hl.dsp.window.resize({ x = math.floor(px), y = w.size.y }))
    end
  end
end

function M.send_key(mods, key)
  return function(w)
    hl.dispatch(hl.dsp.send_shortcut({ mods = mods, key = key, window = w }))
  end
end

return M
