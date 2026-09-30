-- config/hypr/hyprland.lua
--
-- My scrolling-layout-centric Hyprland config.

hey.ws    = require("lib/workspace")
hey.dsp   = require("lib/dsp")
hey.media = require("lib/media")
hey.nav   = require("lib/nav")

hey.plugins = {}
if hl.plugin.scrolloverview then
  hey.plugins.so = require("lib/scrolloverview")
end


-- * Options

-- https://wiki.hypr.land/Configuring/Start/
hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
    no_focus_fallback = true,
    layout = "scrolling"
  },
  input = {
    kb_options = "compose:ralt",
    follow_mouse = 2,
    focus_on_close = 2,
    float_switch_override_focus = 0,
    touchpad = {
      natural_scroll = false,
      tap_and_drag = false,
      drag_lock = 2,
      drag_3fg = 1,
    }
  },
  decoration = {
    dim_strength = 0.35,
    dim_inactive = true,
    dim_special = 0.4,
    dim_around = 0.4,
    blur = { size = 4 }
  },
  render = {
    direct_scanout = 2,
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true
  },
  master = {
    new_status = "master",
    mfact = 0.65
  },
  scrolling = {
    fullscreen_on_one_column = true
  },
  misc = {
    background_color = "0xff000000",
    force_default_wallpaper = 0,
    disable_watchdog_warning = true,
    disable_hyprland_logo = true,
    disable_autoreload = true,
    disable_splash_rendering = true,
    key_press_enables_dpms = true,
    initial_workspace_token_timeout = 20
  },
  cursor = {
    default_monitor = hey.hypr.primaryMonitor,
    zoom_rigid = true
  },
})


-- ** Animations
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })

hl.animation({ leaf = "layers",     enabled = true, speed = 3.0, bezier = "default", style = "fade" })
hl.animation({ leaf = "windows",    enabled = true, speed = 5.0, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "border",     enabled = false })
hl.animation({ leaf = "fade",       enabled = true, speed = 4.0, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.0, bezier = "default", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5.0, bezier = "default", style = "slidefadevert -100%" })


-- * Layer rules

-- Invisible margins/padding will get blurred too without this
hl.layer_rule({ match = { namespace = "notifications" },
                blur = true,
                ignore_alpha = 0.3 })
-- Since we can't focus anything with rofi up anyway, convey this visually.
hl.layer_rule({ match = { namespace = "rofi" },
                dim_around = true,
                animation = "slide top" })


-- * Workspace rules

local PRIMARY_WORKSPACE = 100

-- Workspaces need room to grow "infinitely" in either direction (north or
-- south), so I generate fixed workspaces for all monitors as multiples of 100.
do
  local ws = 200
  for _, m in ipairs(hey.hypr.monitors) do
    local primary = m.output == hey.hypr.primaryMonitor
    hl.workspace_rule({ workspace = tostring(primary and PRIMARY_WORKSPACE or ws),
                        monitor = m.output,
                        default = true,
                        persistent = true })
    -- Only the others count up, or the first of them starts at 300 and 200
    -- is never anyone's.
    if not primary then ws = ws + PRIMARY_WORKSPACE end
  end

  -- Over time, gaps between workspaces form (I'm approximating Niri's "infinite
  -- workspaces" feature), but really, each monitor is given a primary workspace
  -- at #100, #200, #300, etc. (the "roots") and create workspaces up and down.
  -- Gaps can form in between and, in *very* long sessions, neighboring
  -- workspaces may eventually converge, causing the heat death of the universe.
  -- This prevents that silently reordering workspaces relative to their roots.
  hl.on("config.reloaded", hey.ws.compact)
  -- And if a monitor's been tricked into showing its neighbour's workspace, a
  -- reload is the "have you tried turning it off and on again" for it.
  hl.on("config.reloaded", hey.ws.rehome)
end
-- Steam and its games, out of the way until summoned.
hl.workspace_rule({ workspace = "special:game",
                    gaps_in = 0,
                    gaps_out = 0,
                    no_border = true,
                    no_shadow = true,
                    no_rounding = true })
-- One scratchpad per monitor, as special:pad:OUTPUT (see hey.dsp.local_scratchpad).
hl.workspace_rule({ workspace = "n[s:special:pad:]",
                    gaps_in = 10,
                    gaps_out = 85 })


-- * Window rules

-- no going idle if fullscreened
hl.window_rule({ match = { fullscreen = true },
                 idle_inhibit = "fullscreen" })
-- no floats should be fullscreening/maximizing themselves
hl.window_rule({ match = { float = true },
                 suppress_event = "fullscreen maximize" })
hl.window_rule({ match = { class = "^(imv|swayimg)$" },  -- image previewers
                 float = true,
                 center = true,
                 dim_around = true,
                 border_size = 1,
                 max_size = { "monitor_w*0.96", "monitor_h*0.96" } })
hl.window_rule({ match = { initial_title = "emacs-everywhere" },
                 float = true })

-- In multi-monitor setups where some displays are smaller than others, file
-- dialogs can "remember" their last size in larger monitors and be maximized
-- beyond the current monitor's boundaries, so...
hl.window_rule({ name = "dialog-windows",
                 match = { float = true, class = "^(xdg-desktop-portal-gtk|librewolf)" },
                 center = true,
                 max_size = { "monitor_w*0.9", "monitor_h*0.9" } })
hl.window_rule({ match = { class = "^(steam|feishin|emacs|librewolf)$" },
                 scrolling_width = 0.8 })
hl.window_rule({ match = { class = "^foot$" },
                 scrolling_width = 0.35 })
hl.window_rule({ match = { class = "^foot$", workspace = "n[s:special:pad:]" },
                 scrolling_width = 0.40 })
hl.window_rule({ match = { class = "^feishin$" },
                 workspace = "special:game silent" })


-- ** Steam

hl.window_rule({ name = "steam-all-windows",
                 match = { class = "steam" },
                 workspace = "special:game silent",
                 immediate = true,
                 no_dim = true,
                 no_blur = true,
                 no_anim = true,
                 no_shadow = true,
                 no_max_size = true,
                 min_size = {1, 1} })
hl.window_rule({ name = "steam-main-window",
                 match = { class = "steam", initial_title = "Steam" },
                 suppress_event = "fullscreen maximize",
                 float = false,
                 fullscreen = false })
hl.window_rule({ name = "steam-popups",
                 match = { class = "steam", initial_title = "negative:Steam" },
                 float = true })
hl.window_rule({ name = "steam-games",
                 match = { initial_class = "(gamescope|steam_app_\\d+)" },
                 workspace = "special:game silent",
                 no_dim = true,
                 immediate = true,
                 no_blur = true,
                 no_anim = true,
                 no_initial_focus = true,
                 suppress_event = "maximize",
                 content = "game",
                 fullscreen = true,
                 float = false,
                 tile = false })


-- * Gestures

-- 3-finger swipe up/down
hl.gesture({ fingers = 3, direction = "up", action = hey.dsp.over(
  { class = "^librewolf$", action = hey.dsp.send_key("CTRL SHIFT", "Tab") },     -- previous tab
  { workspace = "n[s:special:]", action = hey.dsp.local_scratchpad("pad") },
  hey.plugins.so
    and hey.plugins.so.overview("toggle all")
    or hl.dsp.exec_cmd("noctalia msg window-switcher")) })
hl.gesture({ fingers = 3, direction = "down", action = hey.dsp.over(
  { workspace = "n[s:special:pad:]", action = hey.dsp.local_scratchpad("pad") }, -- exit workspace
  { class = "^librewolf$", action = hey.dsp.send_key("CTRL", "Tab") },           -- next tab
  hl.dsp.exec_cmd("noctalia msg panel-toggle control-center")) })
-- 4-finger swipe left/right = roll the scrolling layout tape
hl.gesture({ fingers = 4,
             direction = "horizontal",
             action = "scroll_move",
             scale = -1 })


-- * Keybinds

-- ** Most common OS operations
hl.bind("SUPER + Space", hl.dsp.exec_cmd("hey @rofi appmenu"))
hl.bind("SUPER + SHIFT + r", hl.dsp.exec_cmd("hey reload @hypr"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd("hey .open-term"))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("foot || xterm")) -- failsafe
hl.bind("SUPER + Escape", function () -- reset
  hl.dispatch(hey.dsp.zoom(0))
  hl.exec_cmd("noctalia msg notification-clear-active")
end)

-- ** External tools
hl.bind("SUPER + c", hl.dsp.exec_cmd("hey @rofi calcmenu"))
hl.bind("SUPER + e", hl.dsp.exec_cmd([[emacsclient --eval "(emacs-everywhere)"]]))
hl.bind("SUPER + d", hl.dsp.exec_cmd("noctalia msg annotate"))
hl.bind("SUPER + w", hl.dsp.exec_cmd("noctalia msg window-switcher"))
hl.bind("SUPER + x", hl.dsp.exec_cmd("hey .ocr region"))
hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd("hey .screencast webm region 3"))
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("hey .screencast mp4 region 3"))

-- ** Zoom
hl.bind("SUPER + Minus", hey.dsp.zoom(-0.3), { repeating = true, submap_universal = true })
hl.bind("SUPER + Equal", hey.dsp.zoom(0.3),  { repeating = true, submap_universal = true })

-- ** Quit/Session control
hl.bind("SUPER + q", hl.dsp.window.close(), { submap_universal = true })
hl.bind("SUPER + SHIFT + q", hl.dsp.window.kill())
hl.bind("SUPER + SHIFT + CTRL + q", hl.dsp.exec_cmd("hey @rofi powermenu"))

-- ** Window layout controls
hl.bind("SUPER + f", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + f", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + p", function()  -- float + pin window
  hl.dispatch(hl.dsp.window.float({ action = "set" }))
  hl.dispatch(hl.dsp.window.pin())
end)
hl.bind("SUPER + o", function()  -- cycle focus between floating/tiling
  local w = hl.get_active_window()
  hl.dispatch(hl.dsp.window.cycle_next({ floating = w and not w.floating }))
end)
hl.bind("SUPER + SHIFT + o", hl.dsp.layout("consume_or_expel prev"))

-- ** Workspaces / special workspaces
do
  -- A per-monitor scratch pad
  hl.bind("SUPER + grave", hey.dsp.local_scratchpad("pad"))
  hl.bind("SUPER + SHIFT + grave", hey.dsp.move_to_workspace_or_back("pad", hey.dsp.move_to_local_scratchpad("pad")))

  -- A global workspace for games/movies/media
  hl.bind("SUPER + 0", hey.dsp.scratchpad("game"))
  hl.bind("SUPER + SHIFT + 0", hey.dsp.move_to_workspace_or_back("game"))
end

-- ** Window management, movements, and resizing
do
  local widths = { 700, 0.5, 0.6, 0.8, 1.0 }  -- on 2-6; px if > 1
  local dirs   = { h = "left", j = "down", k = "up", l = "right" }
  local defbinds = function(prefix, nav)
  -- A "return to home workspace" button (and return back)
    hl.bind(prefix .. "1", hey.dsp.on(
      { workspace = PRIMARY_WORKSPACE, action = hl.dsp.focus({ workspace = "previous_per_monitor" }) },
      hl.dsp.focus({ workspace = tostring(PRIMARY_WORKSPACE) })))

    -- hjkl focuses, SHIFT moves, CTRL goes to the far end first before crossing
    -- into adjacent monitors. h/l run off the tape onto the next monitor, j/k
    -- onto the next workspace (see lib/nav.lua).
    for key, dir in pairs(dirs) do
      hl.bind(prefix .. key,                      nav.focus(dir))
      hl.bind(prefix .. "SHIFT + " .. key,        nav.move(dir))
      hl.bind(prefix .. "CTRL + " .. key,         nav.focus_end(dir))
      hl.bind(prefix .. "SHIFT + CTRL + " .. key, nav.move_end(dir))
    end
    hl.bind(prefix .. "TAB", hey.dsp.on(
      { layout = "scrolling", action = nav.shuffle("right") },
      { layout = "monocle",   action = hl.dsp.layout("cyclenext") },
      { layout = "master",    action = hl.dsp.layout("swapwithmaster") }))
    hl.bind(prefix .. "SHIFT + TAB", hey.dsp.on(
      { layout = "scrolling", action = nav.shuffle("left") },
      { layout = "monocle",   action = hl.dsp.layout("cycleprev") },
      { layout = "master",    action = hl.dsp.exec_cmd("hey @rofi windowmenu") }))
  end

  defbinds("SUPER + ", hey.nav)
  -- Same logic in scroll-overview, just without the SUPER prefix, and dragging
  -- the overview along whenever focus crosses monitors.
  if hey.plugins.so then
    hl.define_submap("scrolloverview", function() defbinds("", hey.plugins.so) end)
  end

  -- Quick one-handed resizing on SUPER + {2-6}
  for i, spec in ipairs(widths) do
    hl.bind("SUPER + " .. (i + 1), hey.dsp.resize_width_to(spec), { submap_universal = true })
  end
  -- Move/resize with mouse LMB/RMB (SO already defines its own)
  hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true, submap_universal = true })
  hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, submap_universal = true })
end

-- ** Monitor brightness controls
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 10%-"), { locked = true, repeating = true })
hl.bind("XF86PowerOff",           hey.dsp.dpms(false), { locked = true })

-- ** Audio and player controls
hl.bind("XF86AudioRaiseVolume",        hey.media.volume("up"),          { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",        hey.media.volume("down"),        { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioRaiseVolume", hey.media.player_volume("up"),   { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioLowerVolume", hey.media.player_volume("down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",               hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("SHIFT + XF86AudioMute",       hl.dsp.exec_cmd("noctalia msg mic-mute"),    { locked = true })

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("noctalia msg media toggle"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"))
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("noctalia msg media next"))
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("noctalia msg media previous"))


-- * We have Niri at home

if hey.plugins.so then
  local so = hl.plugin.scrolloverview
  hl.config({
    plugin = {
      scrolloverview = {
        scale = 0.8,
        layout = "auto",       -- follows each monitor's orientation
        workspace_gap = 50,
        wallpaper = 1,
        blur = false,
        cross_monitor_drag = true,
        shadow = {
          enabled = true,
          range = 10
        },
        input = {
          touchpad_scroll_factor = 3.0
        }
      }
    }
  })

  so.gesture({ fingers = 3, direction = "pinch" })

  -- Make it more obvious what window is focused by dimming everything else.
  local dim_strength = hl.get_config("decoration:dim_strength")
  hl.on("keybinds.submap", function(submap)
    local active = submap == "scrolloverview"
    hl.config({ decoration = { dim_strength = active and 0.8 or dim_strength } })
  end)

  hl.bind("SUPER + SUPER_L",         hey.plugins.so.overview("toggle"),          { release = true })
  hl.bind("SUPER + SHIFT + SUPER_L", hey.plugins.so.overview("toggle all", 0.4), { release = true })

  hl.define_submap("scrolloverview", function()
    hl.bind("SUPER + SUPER_L", so.overview("off"), { release = true })
    hl.bind("SUPER + SHIFT + SUPER_L", so.overview("off"), { release = true })

    hl.bind("Return", function() so.overview("select"); so.overview("off") end)
    hl.bind("Space", so.overview("select"))
    hl.bind("Escape", so.overview("off"))

    -- LMB = Select window and close overview
    hl.bind("mouse:272", function() so.overview("select") so.window("select") so.overview("off") end, { mouse = true })
    -- MMB = Close window
    hl.bind("mouse:274", so.window("close"), { mouse = true })

    -- Don't forward keys to the underlying application!
    hl.bind("catchall", hl.dsp.no_op(), { ignore_mods = true })
  end)
end
