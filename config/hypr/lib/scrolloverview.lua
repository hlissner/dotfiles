-- config/hypr/lib/scrolloverview.lua

local nav = require("lib/nav")

local so = hl.plugin.scrolloverview

local M = {}

-- The overview is a modal thing with no status line; a keypress that did
-- nothing looks exactly like one that worked.
local function fail()
  hl.dispatch(hl.dsp.exec_cmd("hey wm play-sound error"))
end

-- Which monitors have an overview open, by name. The plugin won't say, so I
-- keep count of what goes through dispatch() below. The pinch gesture
-- doesn't, but it only ever opens the one under you, which crossing handles
-- anyway. Whatever this gets wrong dies with the submap, which only lets go
-- once the last overview has closed.
local open = {}

-- The plugin takes no scale per overview; it reads the global option as one
-- opens, then again for pinned floats and swipes for as long as it's up. So
-- a one-off scale has to stay put until the submap lets go.
local default_scale

hl.on("keybinds.submap", function(submap)
  if submap ~= "scrolloverview" then
    open = {}
    if default_scale then
      hl.config({ plugin = { scrolloverview = { scale = default_scale } } })
      default_scale = nil
    end
  end
end)

local function monitors(target)
  if target == "all" then
    local out = {}
    for _, m in ipairs(hl.get_monitors() or {}) do out[#out + 1] = m.name end
    return out
  end
  if target ~= "" then return { target } end
  local m = hl.get_active_monitor()
  return { m and m.name }
end

-- The plugin's "on|off|toggle [MONITOR|all]", minding its rules: no target
-- is the focused monitor (except to off, where it's all of them), and toggle
-- only closes if every target was open. Worked out before dispatching, in
-- case the submap lets go (and empties `open`) under us.
local function dispatch(arg)
  local action, target = arg:match("^(%S+)%s*(.*)$")
  if action == "off" and (target == "" or target == "all") then
    so._dispatch("overview", arg)
    open = {}
    return
  end
  local names, state = monitors(target), action ~= "off"
  if action == "toggle" then
    state = false
    for _, name in ipairs(names) do state = state or not open[name] end
  end
  so._dispatch("overview", arg)
  for _, name in ipairs(names) do open[name] = state or nil end
end

function M.overview(arg, scale)
  return function()
    local ws = hl.get_active_special_workspace()
    if ws then
      hl.dispatch(hl.dsp.workspace.toggle_special((ws.name:gsub("^special:", ""))))
    end
    if scale then
      default_scale = default_scale or hl.get_config("plugin:scrolloverview:scale")
      hl.config({ plugin = { scrolloverview = { scale = scale } } })
    end
    dispatch(arg)
  end
end

-- Where the overview ought to be: with the focused window, else on the focused
-- monitor. Under follow_mouse = 2 those two needn't agree.
local function current()
  local w = hl.get_active_window()
  return w and w.monitor or hl.get_active_monitor()
end

-- Take the overview from FROM to TO. One overview at a time, dragged to
-- whichever monitor focus crosses to -- unless one's already waiting there
-- (toggle all), where closing the one behind us would just be vandalism.
-- Open before closing: the first overview owns the submap and hands it to a
-- live successor on close, whereas closing the only one resets it out from
-- under the bind that's running. And "toggle", not "on": an overview still
-- animating shut counts as open to "on", which then does nothing, so a quick
-- there-and-back loses both. Toggle reopens it.
local function carry(from, to)
  if not (from and to) or from.id == to.id or open[to.name] then return end
  dispatch("toggle " .. to.name)
  dispatch("off " .. from.name)
end

-- lib/nav's ladders, with the overview in tow whenever one steps off onto
-- another monitor. It follows focus on its own; only crossing needs a hand.
--
-- When focus crosses, the one we leave is closed afterwards, or it's still the
-- "active" one and commits its selection by stealing focus back. When a window
-- crosses, it's closed *before* it goes: closing switches its monitor to the
-- selected window's workspace, without asking whose that is now, and a
-- monitor left showing its neighbour's workspace wrecks every ladder after it.
local function carried(action)
  return function(dir)
    local run = action(dir, carry)
    return function()
      local from = current()
      if not run() then fail() return end
      carry(from, current())
    end
  end
end

M.focus     = carried(nav.focus)
M.move      = carried(nav.move)
M.focus_end = carried(nav.focus_end)
M.move_end  = carried(nav.move_end)
M.shuffle   = carried(nav.shuffle)

return M
