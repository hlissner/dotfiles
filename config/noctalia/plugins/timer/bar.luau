--!nonstrict
-- Timer bar widget - the [[widget]] entry for the status bar.
--
-- The bar widget displays the timer's current state: an hourglass
-- icon when idle, or the formatted countdown when running. Click
-- the widget to open the panel for duration input and controls.
--
--   barWidget.render(tree)             declarative UI tree
--   barWidget.isVertical()             branch on bar orientation
--   noctalia.getConfig(key)            per-placement widget settings
--   noctalia.togglePanel(id)           open/close the timer panel

local STATE = "IDLE"
local formattedTime = "00:00"
local isVertical = false

local Tooltip = {
  hasTooltip = false,
}

function Tooltip.show()
  barWidget.setTooltip(formattedTime)
  Tooltip.hasTooltip = true
end

function Tooltip.hide()
  -- trying to clear a tooltip when there is none is crashing the plugin
  if Tooltip.hasTooltip then
    barWidget.clearTooltip()
    Tooltip.hasTooltip = false
  end
end

-- HEY: upstream hardcoded a color per state (on_surface/primary/error), and an
-- explicit color prop beats the widget's own color/icon_color/capsule_foreground
-- -- so styling this widget like every other one on the bar did nothing. A tree
-- that leaves color unset inherits those instead, which is what nil buys here.
-- The two states worth shouting about are settings now; "" means inherit too.
local STATE_COLOR_SETTINGS = {
  RUNNING = "running_color",
  NOTIFY = "notify_color",
}

local function getHourglassColor()
  local key = STATE_COLOR_SETTINGS[STATE]
  if key == nil then
    return nil
  end
  local color = noctalia.getConfig(key)
  if color == nil or color == "" then
    return nil
  end
  return color
end

local function render()
  local showCounterWhenIdle = noctalia.getConfig("show_idle_on_horizontal")
  local hourGlassColor = getHourglassColor()

  -- HEY: upstream reads the setting as "drop the countdown text", which leaves
  -- an hourglass in the bar saying nothing. I want the widget gone until it
  -- has something to say, on a vertical bar too.
  barWidget.setVisible(STATE ~= "IDLE" or showCounterWhenIdle ~= false)

  if isVertical then
      barWidget.render(ui.column({ align = "center" }, {
        ui.glyph({ name = "hourglass", color = hourGlassColor }),
      }))

      if STATE == "RUNNING" then
        Tooltip.show()
      end
  else
    -- Idle state: timer at zero, just show hourglass icon when showCounterWhenIdle in widget settings was set false
    if STATE == "IDLE" and showCounterWhenIdle == false then
      barWidget.render(ui.row({ align = "center" }, {
        ui.glyph({ name = "hourglass", color = hourGlassColor }),
      }))
      return
    end

    -- Running or paused with time remaining
    barWidget.render(ui.row({ gap = 6, align = "center" }, {
      ui.glyph({ name = "hourglass", color = hourGlassColor }),
      ui.label({ text = formattedTime, fontWeight = "bold", color = hourGlassColor }),
    }))
  end
end

-- update needed for initial load
function update()
  isVertical = barWidget.isVertical()
  render()
end

noctalia.state.watch("timer.state", function(value)
  -- if state was RUNNING and is updated to something else,
  -- we disable the tooltip
  if isVertical and STATE == "RUNNING" and value ~= "RUNNING" then
    Tooltip.hide()
  end

  STATE = value
  render()
end)

noctalia.state.watch("timer.formattedTime", function(value)
  formattedTime = value
  if STATE == "RUNNING" then
    render()
  end
end)

function onClick()
  if STATE == "NOTIFY" then
    -- click on the bar when timer is done should stop NOTIFY state and
    -- should not open the panel. the user most likely don't want to set another timer
    noctalia.state.set("timer.cmd", "RESET")
    return
  end
  noctalia.togglePanel("hey/timer:panel")  -- HEY: was noctalia/timer:panel
end
