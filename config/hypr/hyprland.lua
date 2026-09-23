-- config/hypr/hyprland.lua

hey.dsp = require("lib/dsp")          -- bind and gesture actions


-- * Events

hl.on("keybinds.submap", function(submap)
  local quoted = submap:gsub("'", [['\'']])
  hl.exec_cmd("hey hook -f on-submap '" .. quoted .. "'")
end)


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
    float_switch_override_focus = 0
  },

  decoration = {
    dim_strength = 0.2,
    dim_inactive = true,
    dim_special = 0.4,
    dim_around = 0.4,
    blur = { size = 4 }
  },

  render = {
    direct_scanout = 2,
  },

  -- Obnoxious.
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true
  },

  master = {
    new_status = "master",
    mfact = 0.65
  },

  misc = {
    background_color = "0xff000000",
    force_default_wallpaper = 0,  -- I'm not *that* much of a weeb
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
  }
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

-- Invisible margins/padding will get blurred too; ignorezero fixes this.
hl.layer_rule({ match = { namespace = "notifications" },
                blur = true,
                ignore_alpha = 0.3 })
-- Since we can't focus anything with rofi up anyway, convey this visually.
hl.layer_rule({ match = { namespace = "rofi" },
                dim_around = true,
                animation = "slide top" })


-- * Workspace rules

-- Designate workspaces 1-9 for my main monitor
for i = 1, 9 do
  hl.workspace_rule({ workspace = tostring(i),
                      monitor = hey.hypr.primaryMonitor,
                      default = i == 1,
                      persistent = i == 1 })
end
-- A workspace exclusively for games
hl.workspace_rule({ workspace = "10",
                    layout = "monocle",
                    monitor = hey.hypr.primaryMonitor,
                    gaps_in = 0,
                    gaps_out = 0,
                    no_border = true,
                    no_shadow = true,
                    no_rounding = true })

hl.window_rule({ name  = "games-workspace",
                 match = { workspace = "10" },
                 no_blur      = true,
                 no_anim      = true,
                 immediate    = true })
-- Every scratchpad scrolls; the rules below only differ in their gaps.
hl.workspace_rule({ workspace = "special:pad",
                    on_created_empty = "hey .scratch term",
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

-- In multi-monitor setups where some displays are smaller than others, file
-- dialogs can "remember" their last size in larger monitors and be maximized
-- beyond the current monitor's boundaries, so...
hl.window_rule({ name = "dialog-windows",
                 match = { float = true, class = "^(xdg-desktop-portal-gtk|librewolf)" },
                 center = true,
                 max_size = { "monitor_w*0.9", "monitor_h*0.9" } })
hl.window_rule({ match = { class = "^(emacs|feishin|librewolf)$" },
                 scrolling_width = 0.8 })
hl.window_rule({ match = { class = "^foot$" },
                 scrolling_width = 0.35 })


-- ** Steam

hl.window_rule({ name = "steam-all-windows",
                 match = { class = "steam" },
                 workspace = "5 silent",
                 immediate = true,
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
                 workspace = "10 silent",
                 suppress_event = "maximize",
                 content = "game",
                 fullscreen = true,
                 float = false,
                 tile = false })


-- * Gestures

-- 3-finger up/down = the app under the cursor gets first refusal, then Noctalia
hl.gesture({ fingers = 3, direction = "up", action = hey.dsp.over(
  { class = "^librewolf$", action = hey.dsp.send_key("CTRL SHIFT", "Tab") },
  hl.plugin.scrolloverview
    and hl.plugin.scrolloverview.overview("toggle all")
    or hl.dsp.exec_cmd("noctalia msg window-switcher")) })
hl.gesture({ fingers = 3, direction = "down", action = hey.dsp.over(
  { class = "^librewolf$", action = hey.dsp.send_key("CTRL", "Tab") },
  hl.dsp.exec_cmd("noctalia msg panel-toggle control-center")) })

-- 3-finger swipe left/right = roll the scrolling layout tape
hl.gesture({ fingers = 3,
             direction = "horizontal",
             action = "scroll_move",
             scale = -1 })


-- * Keybinds

hl.bind("SUPER + Space",          hl.dsp.exec_cmd("hey @rofi appmenu"))
hl.bind("SUPER + Return",         hl.dsp.exec_cmd("hey .open-term"))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + c",              hl.dsp.exec_cmd("hey @rofi calcmenu"))
hl.bind("SUPER + Escape",         hl.dsp.exec_cmd("noctalia msg notification-clear-active"))
hl.bind("SUPER + r",              hl.dsp.exec_cmd("hey reload @hypr"), { description = "Reload hyprland's config" })

-- ** Zoom
hl.bind("SUPER + Minus",         hey.dsp.zoom(-0.3), { repeating = true, submap_universal = true })
hl.bind("SUPER + Equal",         hey.dsp.zoom(0.3),  { repeating = true, submap_universal = true })
hl.bind("SUPER + SHIFT + Equal", hey.dsp.zoom(0),    { submap_universal = true })

-- ** Quit/Session control
hl.bind("SUPER + q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + q", hl.dsp.window.kill())
hl.bind("SUPER + SHIFT + CTRL + q", hl.dsp.exec_cmd("hey @rofi powermenu"))

-- ** Screenshot/recording/drawing
hl.bind("SUPER + x", hl.dsp.exec_cmd("hey .ocr region"))
hl.bind("SUPER + d", hl.dsp.exec_cmd("noctalia msg annotate"))
hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd("hey .screencast webm region 3"))
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("hey .screencast mp4 region 3"))

-- ** Layout controls
hl.bind("SUPER + f", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + f", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + o", function()
  local w = hl.get_active_window()
  hl.dispatch(hl.dsp.window.cycle_next({ floating = w and not w.floating }))
end)
hl.bind("SUPER + SHIFT + o", hl.dsp.layout("consume_or_expel prev"))
hl.bind("SUPER + TAB", hey.dsp.on(
  { layout = "scrolling", action = hl.dsp.layout("swapcol r") },
  { layout = "monocle",   action = hl.dsp.layout("cyclenext") },
  { layout = "master",    action = hl.dsp.layout("swapwithmaster") }),
  { submap_universal = true })
hl.bind("SUPER + SHIFT + TAB", hey.dsp.on(
  { layout = "scrolling", action = hl.dsp.layout("swapcol l") },
  { layout = "monocle",   action = hl.dsp.layout("cycleprev") },
  { layout = "master", action = hl.dsp.exec_cmd("hey @rofi windowmenu") }),
  { submap_universal = true })

-- ** Scratchpads
hl.bind("SUPER + grave",     hey.dsp.scratchpad("pad"))
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:pad" }))
hl.bind("SUPER + e",         hl.dsp.exec_cmd([[emacsclient --eval "(emacs-everywhere)"]]))

-- ** Windows
-- hjkl focuses, SHIFT moves, CTRL does the same across monitors.
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  hl.bind("SUPER + " .. key,                hl.dsp.focus({ direction = dir }), { submap_universal = true })
  hl.bind("SUPER + SHIFT + " .. key,        hl.dsp.window.move({ direction = dir }), { submap_universal = true })
  hl.bind("SUPER + CTRL + " .. key,         hl.dsp.focus({ monitor = dir }), { submap_universal = true })
  hl.bind("SUPER + SHIFT + CTRL + " .. key, hl.dsp.window.move({ monitor = dir }), { submap_universal = true })
end

-- ** Workspaces
for i = 1, 10 do
  local key = i % 10
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), { submap_universal = true })
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { submap_universal = true })
end

-- ** Quick-resize windows
for i, spec in ipairs({ 700, 0.4, 0.5, 0.6, 0.8, 1.0 }) do
  hl.bind("SUPER + CTRL + " .. i, hey.dsp.resize_width_to(spec))
end

-- ** Move/resize windows with mouse LMB/RMB
hl.bind("SUPER + mouse:272",      hl.dsp.window.drag(),   { mouse = true }, { submap_universal = true })
hl.bind("SUPER + mouse:273",      hl.dsp.window.resize(), { mouse = true }, { submap_universal = true })

-- ** Monitor brightness control
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 10%-"), { locked = true, repeating = true })
hl.bind("XF86PowerOff",           hey.dsp.dpms(false), { locked = true })

-- ** Audio and player controls
hl.bind("XF86AudioRaiseVolume",        hey.dsp.volume("up"),          { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",        hey.dsp.volume("down"),        { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioRaiseVolume", hey.dsp.player_volume("up"),   { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioLowerVolume", hey.dsp.player_volume("down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",               hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("SHIFT + XF86AudioMute",       hl.dsp.exec_cmd("noctalia msg mic-mute"),    { locked = true })

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("noctalia msg media toggle"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"))
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("noctalia msg media next"))
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("noctalia msg media previous"))


-- * Plugins

-- We have niri at home
if hl.plugin.scrolloverview then
  local so = hl.plugin.scrolloverview
  hey.plugins = hey.plugins or {}
  hey.plugins.so = require("lib/scrolloverview")
  hl.config({
    plugin = {
      scrolloverview = {
        scale = 0.6,
        layout = "auto",       -- follows each monitor's orientation
        workspace_gap = 75,
        gesture_distance = 300,
        wallpaper = 2,
        blur = true,
        cross_monitor_drag = true,
        shadow = {
          enabled = true,
          range = 50,
          color = 0x1196cdf8
        },
        input = {
          touchpad_scroll_factor = 2.5
        }
      }
    }
  })

  so.gesture({ fingers = 4, direction = "pinch" })

  hl.bind("SUPER + w", function()
    so.overview("toggle all")
  end)

  hl.define_submap("scrolloverview", function()
    -- Same shape as the hjkl binds outside the overview: SHIFT moves, CTRL
    -- crosses monitors. The difference is that plain hjkl crosses them too,
    -- once the selection has nowhere left to go on this one.
    for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
      hl.bind(key,                       hey.plugins.so.navigate(dir))
      hl.bind("SHIFT + " .. key,         hey.plugins.so.move(dir))
      hl.bind("CTRL + " .. key,          hl.dsp.focus({ monitor = dir }))
      hl.bind("CTRL + SHIFT + " .. key,  hey.plugins.so.move_to_edge(dir))
    end

    for i, spec in ipairs({ 700, 0.4, 0.5, 0.6, 0.8, 1.0 }) do
      hl.bind(tostring(i), hey.dsp.resize_width_to(spec))
    end

    hl.bind("Return", function() so.overview("select"); so.overview("off") end)
    hl.bind("Space", so.overview("select"))
    hl.bind("Escape", so.overview("off"))
    hl.bind("SUPER + w", so.overview("off"))
    hl.bind("SUPER + q", so.window("close"))
    hl.bind("mouse:272", function()
      so.overview("select")
      so.window("select")
      so.overview("off")
    end, { mouse = true })
    hl.bind("mouse:274", so.window("close"), { mouse = true })
    -- Don't forward keys to the underlying application!
    hl.bind("catchall", hl.dsp.no_op(), { ignore_mods = true })
  end)
end
