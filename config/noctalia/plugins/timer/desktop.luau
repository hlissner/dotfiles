--!nonstrict
-- Countdown timer desktop widget - a [[desktop_widget]] client of the shared
-- timer service.
--
-- Like the bar and panel entries, this widget owns no timer logic: it reflects
-- the service's state (noctalia.state) and drives it with START/PAUSE/RESET
-- commands. Desktop widgets are background layer-shell surfaces that cannot take
-- keyboard focus, so the duration is set with keyboard-free +/- buttons rather
-- than a text input (the panel handles typed input). The desktop widget, bar
-- widget, and panel all control one shared countdown.
--
--   desktopWidget.render(tree)         declarative UI tree
--   noctalia.getConfig(key)            per-widget styling (color, progress bar)
--   noctalia.state.set(key, value)     send commands to the service
--   noctalia.state.watch(key, fn)      react to state changes
--   button onClick = "name"            calls a plugin global
--   button onClick = function() end     calls a render-scoped closure (plugin_api >= 9)

local color = noctalia.getConfig("color")
local showProgress = noctalia.getConfig("show_progress")

local STATE = "IDLE"
local remaining = 0
local formattedTime = "0"
local duration = 0 -- countdown total when the timer started, for the progress bar

local function timeColor()
  if STATE == "NOTIFY" then
    return "error"
  elseif remaining > 0 then
    return color
  end
  return "outline"
end

local function render()
  local remainingText = remaining > 0 and formattedTime or "--:--"

  local rows = {
    ui.label({
      text = remainingText,
      fontSize = 34,
      fontWeight = "bold",
      color = timeColor(),
    }),
  }

  if showProgress then
    table.insert(rows, ui.progress({
      progress = duration > 0 and remaining / duration or 0,
      fill = color,
      width = 160,
      height = 6,
      radius = 3,
    }))
  end

  -- Adjusting the duration only makes sense while idle; hide the +/- row once
  -- the timer is running/paused/notifying.
  if STATE == "IDLE" then
    table.insert(rows, ui.row({ gap = 4, justify = "center" }, {
      ui.button({ text = "-1m", variant = "ghost", controlSize = "sm", onClick = "onMinus1" }),
      ui.button({ text = "+1m", variant = "ghost", controlSize = "sm", onClick = "onPlus1" }),
      ui.button({ text = "+5m", variant = "ghost", controlSize = "sm", onClick = "onPlus5" }),
    }))
  end

  local btnText = STATE == "RUNNING" and noctalia.tr("ui.pause") or noctalia.tr("ui.start")
  local btnVariant = STATE == "RUNNING" and "secondary" or "primary"

  table.insert(rows, ui.row({ gap = 8, justify = "center" }, {
    ui.button({
      text = noctalia.tr("ui.reset"),
      variant = "destructive",
      onClick = "onReset",
    }),
    ui.button({
      text = btnText,
      variant = btnVariant,
      onClick = "onToggle",
      enabled = remaining > 0,
    }),
  }))

  desktopWidget.render(ui.column({ gap = 10, align = "center" }, rows))
end

-- Nudge the shared countdown by whole minutes while idle. State is synchronous,
-- so read-modify-write against the local mirror is safe here.
local function adjust(deltaSeconds)
  if STATE ~= "IDLE" then
    return
  end
  local target = math.max(0, remaining + deltaSeconds)
  noctalia.state.set("timer.remaining", target)
end

noctalia.state.watch("timer.state", function(value)
  STATE = value
  render()
end)

noctalia.state.watch("timer.formattedTime", function(value)
  formattedTime = value
  render()
end)

noctalia.state.watch("timer.remaining", function(value)
  remaining = value
  render()
end)

noctalia.state.watch("timer.duration", function(value)
  duration = value
  render()
end)

function onMinus1()
  adjust(-60)
end

function onPlus1()
  adjust(60)
end

function onPlus5()
  adjust(300)
end

function onReset()
  noctalia.state.set("timer.cmd", "RESET")
end

function onToggle()
  if STATE == "RUNNING" then
    noctalia.state.set("timer.cmd", "PAUSE")
  else
    -- IDLE (start) or PAUSED (resume): the service reads timer.remaining
    noctalia.state.set("timer.cmd", "START")
  end
end

-- Seed from the service's current state (watches keep us in sync afterwards),
-- then draw the initial tree.
STATE = noctalia.state.get("timer.state") or "IDLE"
remaining = noctalia.state.get("timer.remaining") or 0
formattedTime = noctalia.state.get("timer.formattedTime") or "0"
duration = noctalia.state.get("timer.duration") or 0
render()
