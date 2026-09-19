-- config/hypr/hyprland.lua

require("lib/util")


-- * Options

-- https://wiki.hypr.land/Configuring/Start/
hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
    no_focus_fallback = true,
    layout = "master",
    allow_tearing = false,
    resize_on_border = false
  },

  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model   = "",
    kb_options = "compose:ralt",
    kb_rules   = "",
    follow_mouse = 2,
    focus_on_close = 2,
    float_switch_override_focus = 0,
    touchpad = {
        natural_scroll = false,
    },
    sensitivity = 0  -- -1.0 - 1.0, 0 means no modification.
  },

  decoration = {
    dim_strength = 0.2,
    dim_inactive = true,
    dim_special = 0.4,
    dim_around = 0.4,
    -- shadow {
    --   enabled = true
    --   range = 10
    --   render_power = 4
    --   color = rgba(0f0f0f88)
    -- }
    blur = {
        enabled = true,
        size = 4,
        passes = 1
    }
  },

  render = {
    direct_scanout = 2,
  },

  -- Obnoxious.
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true
  },

  animations = {
    enabled = true
  },

  dwindle = {
    -- pseudotile = yes # master switch for pseudotiling. Enabling is bound to
    -- mainMod + P in the keybinds section below
    preserve_split = true  -- you probably want this
  },

  -- See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
  master = {
    new_status = "master",
    mfact = 0.65
  },

  -- See https://wiki.hyprland.org/Configuring/Variables/ for more
  misc = {
    background_color = "0xff000000",
    force_default_wallpaper = 0,  -- Set to 0 to disable the anime mascot wallpapers
    disable_watchdog_warning = true,
    disable_hyprland_logo = true,
    disable_autoreload = true,
    disable_splash_rendering = true,
    key_press_enables_dpms = true,
    initial_workspace_token_timeout = 20
  },

  cursor = {
    default_monitor = hey.hypr.primaryMonitor,
    hide_on_key_press = false,
    enable_hyprcursor = true,
    zoom_rigid = true
  },

  scrolling = {
    fullscreen_on_one_column = false
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

-- Invisible margins/padding will get blurred too; ignorezero fixes this.
hl.layer_rule({
  match = { namespace = "notifications" },
  blur = true,
  ignore_alpha = 0.3
})
-- Since we can't focus anything with rofi up anyway, convey this visually.
hl.layer_rule({
  match = { namespace = "rofi" },
  dim_around = true,
  animation = "slide top"
})


-- * Workspace rules

-- hey is spliced in by modules/hyprland/default.nix, from hey/info.json.
if hey.hypr.primaryMonitor then
  -- Designate workspaces 1-9 for my main monitor
  for i = 1, 9 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = hey.hypr.primaryMonitor,
        default = i == 1,
        persistent = i == 1
    })
  end
  -- A workspace exclusively for games
  hl.workspace_rule({
    workspace = tostring(10),
    layout = "monocle",
    monitor = hey.hypr.primaryMonitor,
    gaps_in = 0,
    gaps_out = 0,
    no_border = true,
    no_shadow = true,
    no_rounding = true
  })

  hl.window_rule({
    name  = "games-workspace",
    match = { workspace = "10" },
    no_blur      = true,
    no_anim      = true,
    immediate    = true,
    idle_inhibit = "fullscreen"
  })
end

hl.workspace_rule({
    workspace = "special:term",
    gaps_in = 15,
    gaps_out = 80,
    layout = "scrolling",
    on_created_empty = "hey .scratch term"
})
hl.workspace_rule({
    workspace = "special:pad",
    gaps_in = 6,
    gaps_out = 80
})


-- * Window rules

-- no going idle if something is fullscreened
hl.window_rule({ match={ fullscreen = true }, idle_inhibit = "fullscreen" })
-- No floats should be fullscreening/maximizing themselves
hl.window_rule({ match={ float = true }, suppress_event = "fullscreen maximize" })

-- In multi-monitor setups where some displays are smaller than others, file
-- dialogs can "remember" their last size in larger monitors and be maximized
-- beyond the current monitor's boundaries, so...
hl.window_rule({
    name = "dialog-windows",
    match = { float = true, class = "^(xdg-desktop-portal-gtk|librewolf)" },
    center = true,
    max_size = { "monitor_w*0.9", "monitor_h*0.9" }
})

hl.window_rule({ match={ class = "^librewolf$" }, scrolling_width = 0.8 })

hl.window_rule({ match={ class = "^foot$" }, scrolling_width = 0.3 })

hl.window_rule({ -- see config/hypr/bin/screendraw.zsh
    match = { class = "^Gromit-mpx$" },
    float = true,
    no_blur = true,
    no_max_size = true,
    no_anim = true,
    no_shadow = true
})


-- ** Steam

hl.window_rule({
    name = "steam-all-windows",
    match = { class = "steam" },
    workspace = "5 silent",
    immediate = true,
    no_blur = true,
    no_anim = true,
    no_shadow = true,
    no_max_size = true,
    min_size = {1, 1}
})
hl.window_rule({
    name = "steam-main-window",
    match = { class = "steam", initial_title = "Steam" },
    suppress_event = "fullscreen maximize",
    float = false,
    fullscreen = false
})
hl.window_rule({
    name = "steam-popups",
    match = { class = "steam", initial_title = "negative:Steam" },
    float = true,
    center = true
})
hl.window_rule({
    name = "steam-games",
    match = { initial_class = "(gamescope|steam_app_\\d+)" },
    workspace = "10 silent",
    suppress_event = "maximize",
    content = "game",
    fullscreen = true,
    float = false,
    tile = false
})


-- * Keybinds

hl.bind("SUPER + Space",          hl.dsp.exec_cmd("hey @rofi appmenu"))
hl.bind("SUPER + Return",         hl.dsp.exec_cmd("hey .open-term"))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + c",              hl.dsp.exec_cmd("hey @rofi calcmenu"))
hl.bind("SUPER + d",              hl.dsp.exec_cmd("hey .screendraw"))
hl.bind("SUPER + Escape",         hl.dsp.exec_cmd("dms ipc call notifications clearAll; dms ipc toast hide"))

-- ** Zoom

hl.bind("SUPER + Minus", hey.dsp.zoomIn(-0.3), { repeating = true })
hl.bind("SUPER + Equal", hey.dsp.zoomIn(0.3),  { repeating = true })
hl.bind("SUPER + SHIFT + Equal", hey.dsp.zoomIn(0.0)) -- reset

-- ** Quit/Session control
hl.bind("SUPER + q", hl.dsp.submap("session"))
hl.define_submap("session", "reset", function()
    hl.bind("SUPER + q", hl.dsp.window.close())
    hl.bind("SUPER + k", hl.dsp.window.kill())
    hl.bind("SUPER + p", hl.dsp.exec_cmd("hey @rofi powermenu"))
    hl.bind("SUPER + SHIFT + l", hl.dsp.exec_cmd("loginctl lock-session"))
    hl.bind("SUPER + d", my.dsp.dpms(false))
    hl.bind("SUPER + SUPER_L", hl.dsp.submap("reset"), { release = true })
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- ** Screenshot/recording
hl.bind("Print", hl.dsp.submap("screenshot"))
hl.define_submap("screenshot", "reset", function()
    hl.bind("Print",    hl.dsp.exec_cmd("hey .screenshot region"))
    hl.bind("w",        hl.dsp.exec_cmd("hey .screenshot window"))
    hl.bind("m",        hl.dsp.exec_cmd("hey .screenshot full"))
    hl.bind("l",        hl.dsp.exec_cmd("hey .screenshot last"))
    hl.bind("catchall", hl.dsp.submap("reset"))
end)
hl.bind("SUPER + Print", hl.dsp.submap("screencap"))
hl.define_submap("screencap", "reset", function()
    hl.bind("SUPER + Print",         hl.dsp.exec_cmd("hey .screencast webm region 3"))
    hl.bind("SUPER + w",             hl.dsp.exec_cmd("hey .screencast webm window 3"))
    hl.bind("SUPER + r",             hl.dsp.exec_cmd("hey .screencast webm region 3"))
    hl.bind("SUPER + m",             hl.dsp.exec_cmd("hey .screencast mp4 output 3"))
    hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("hey .screencast mp4 region 3"))
    hl.bind("SUPER + SHIFT + w",     hl.dsp.exec_cmd("hey .screencast mp4 window 3"))
    hl.bind("SUPER + SHIFT + r",     hl.dsp.exec_cmd("hey .screencast mp4 region 3"))
    hl.bind("SUPER + SUPER_L",       hl.dsp.submap("reset"), { release = true })
    hl.bind("catchall",              hl.dsp.submap("reset"))
end)

-- ** Layout controls
hl.bind("SUPER + f",              hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + f",      hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + o", hey.dsp.layout({
  scrolling = hl.dsp.layout("consume_or_expel next"),
  monocle   = hl.dsp.focus({ last = true }),
  master    = hl.dsp.layout("addmaster"),
}))
hl.bind("SUPER + SHIFT + o", hey.dsp.layout({
  scrolling = hl.dsp.layout("consume_or_expel prev"),
  monocle   = hl.dsp.focus({ urgent_or_last = true }),
  master    = hl.dsp.layout("removemaster"),
}))
hl.bind("SUPER + TAB", hey.dsp.layout({
  scrolling = hl.dsp.layout("swapcol r"),
  monocle   = hl.dsp.layout("cyclenext"),
  master    = hl.dsp.layout("swapwithmaster"),
}))
hl.bind("SUPER + SHIFT + TAB", hey.dsp.layout({
  scrolling = hl.dsp.layout("swapcol l"),
  monocle   = hl.dsp.layout("cycleprev"),
  master    = hl.dsp.exec_cmd("hey @rofi windowmenu"),
}))
hl.bind("SUPER + Left",         hl.dsp.layout("orientationleft"))
hl.bind("SUPER + Right",        hl.dsp.layout("orientationright"))
hl.bind("SUPER + Up",           hl.dsp.layout("orientationtop"))
hl.bind("SUPER + Down",         hl.dsp.layout("orientationbottom"))
hl.bind("SUPER + SHIFT + Down", hl.dsp.layout("orientationcenter"))

-- ** Scratchpads
hl.bind("SUPER + grave",     hl.dsp.workspace.toggle_special("term"))
hl.bind("SUPER + e",         hl.dsp.exec_cmd([[emacsclient --eval "(emacs-everywhere)"]]))
hl.bind("SUPER + s",         hl.dsp.workspace.toggle_special("pad"))
hl.bind("SUPER + SHIFT + s", hl.dsp.window.move({ workspace = "special:pad" }))

-- ** Windows
hl.bind("SUPER + h",                hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + j",                hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + k",                hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + l",                hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + SHIFT + h",        hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + j",        hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + k",        hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + l",        hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + CTRL + h", hl.dsp.window.move({ monitor = "left" }))
hl.bind("SUPER + SHIFT + CTRL + j", hl.dsp.window.move({ monitor = "down" }))
hl.bind("SUPER + SHIFT + CTRL + k", hl.dsp.window.move({ monitor = "up" }))
hl.bind("SUPER + SHIFT + CTRL + l", hl.dsp.window.move({ monitor = "right" }))
hl.bind("SUPER + CTRL + h",         hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + j",         hl.dsp.focus({ monitor = "d" }))
hl.bind("SUPER + CTRL + k",         hl.dsp.focus({ monitor = "u" }))
hl.bind("SUPER + CTRL + l",         hl.dsp.focus({ monitor = "r" }))
-- Cycle between floats and tiles
hl.bind("SUPER + w", function()
  local w = hl.get_active_window()
  if not w then return end
  hl.dispatch(hl.dsp.window.cycle_next({ floating = not w.floating }))
end)

-- ** Workspaces
for i = 1, 10 do
  local key = i % 10
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Quick-resize windows
for i, spec in ipairs({ 640, 0.4, 0.5, 0.6, 0.8, 1.0 }) do
  hl.bind("SUPER + CTRL + " .. i, hey.dsp.resize_width_to(spec))
end

-- ** Move/resize windows with mouse LMB/RMB
hl.bind("SUPER + mouse:272",      hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273",      hl.dsp.window.resize(), { mouse = true })

-- ** Monitor brightness control
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 10%-"), { locked = true, repeating = true })
hl.bind("XF86PowerOff",           hey.dsp.dpms(false), { locked = true; })

-- ** Audio and player controls
local step = 10
hl.bind("XF86AudioRaiseVolume",        hey.dsp.volume("up", step),               { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",        hey.dsp.volume("down", step),             { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioRaiseVolume", hey.dsp.player_volume("up", step),        { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioLowerVolume", hey.dsp.player_volume("down", step),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",               hl.dsp.exec_cmd("dms ipc audio mute"),    { locked = true })
hl.bind("SHIFT + XF86AudioMute",       hl.dsp.exec_cmd("dms ipc audio micmute"), { locked = true })

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("dms ipc mpris playPause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("dms ipc mpris playPause"))
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("dms ipc mpris next"))
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("dms ipc mpris previous"))
