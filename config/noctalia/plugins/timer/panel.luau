--!nonstrict
-- Timer panel - the [[panel]] entry for duration input and controls.
--
-- The panel provides an interactive surface to set the countdown
-- duration via numeric input (e.g. 300 → 3:00, 10300 → 1:03:00),
-- and start/pause/reset the timer via buttons. The input is disabled
-- while the timer is running. The panel closes automatically on start.
--
--   panel.render(tree)                 declarative UI tree
--   panel.close()                       close the panel surface
--   noctalia.state.set(key, value)     send commands to service
--   noctalia.state.watch(key, fn)      react to state changes

local inputDigits = ""
local remaining = 0
local formattedTime = "0"
local STATE = "IDLE"
-- used to update input value programatically
local inputKey = 0

local function parseDigits(digits)
  digits = digits:gsub("%s", "")
  if digits == "" then
    return 0
  end
  digits = digits:gsub("[^0-9]", "")
  if digits == "" then
    return 0
  end

  local secs = 0
  local mins = 0
  local hours = 0

  if #digits <= 2 then
    secs = tonumber(digits)
  elseif #digits <= 4 then
    local ssStr = digits:sub(-2)
    local mmStr = digits:sub(1, -3)
    secs = tonumber(ssStr) or 0
    mins = tonumber(mmStr) or 0
  else
    local ssStr = digits:sub(-2)
    local mmStr = digits:sub(-4, -3)
    local hhStr = digits:sub(1, -5)

    secs = math.min(59, math.max(0, tonumber(ssStr) or 0))
    mins = math.min(59, math.max(0, tonumber(mmStr) or 0))
    hours = math.max(0, tonumber(hhStr) or 0)
  end

  return hours * (60 ^ 2) + mins * 60 + secs
end

local function render()
  local remainingText = remaining > 0 and formattedTime or "--:--"

  local btnText = STATE == "RUNNING" and noctalia.tr("ui.pause") or noctalia.tr("ui.start")
  local btnVariant = STATE == "RUNNING" and "secondary" or "primary"

  panel.render(ui.column({ gap = 12, padding = 16 }, {
    ui.label({ text = noctalia.tr("ui.duration_label"), fontSize = 16, fontWeight = "bold", color = "primary" }),
    ui.column({ gap = 8, padding = 8, fill = "surface_variant/0.4", radius = 8 }, {
      ui.row({ justify = "center" }, {
        ui.label({
          text = remainingText,
          fontSize = 36,
          fontWeight = "bold",
          color = remaining > 0 and "primary" or "outline",
        }),
      }),
      ui.input({
        key = "dur-" .. inputKey,
        value = inputDigits,
        placeholder = noctalia.tr("ui.duration_placeholder"),
        fontSize = 14,
        focus = true,
        onChange = "onInputChange",
        onSubmit = "onInputSubmit",
        enabled = STATE == "IDLE"
      }),
    }),
    ui.row({ gap = 8, justify = "space_between" }, {
      ui.button({
        text = noctalia.tr("ui.reset"),
        variant = "destructive",
        onClick = "onReset",
      }),
      ui.button({
        text = btnText,
        variant = btnVariant,
        onClick = "onToggle",
        enabled = remaining > 0
      }),
    }),
  }))
end

local function updateInputDigits()
  inputKey = inputKey + 1
end

local function playTimer()
  noctalia.state.set("timer.remaining", parseDigits(inputDigits))
  noctalia.state.set("timer.cmd", "START")
end

local function resumeTimer()
  noctalia.state.set("timer.cmd", "START")
end

local function resetInputDigits()
  if remaining == 0 then
    inputDigits = ""
  else
    inputDigits = formattedTime
  end
  updateInputDigits()
end

function onOpen(_context)
  STATE = noctalia.state.get("timer.state")
  remaining = noctalia.state.get("timer.remaining")
  formattedTime = noctalia.state.get("timer.formattedTime") or "0"
  resetInputDigits()
  render()
end

noctalia.state.watch("timer.state", function(value)
  if STATE == "NOTIFY" and value == "IDLE" then
    -- if panel is open input will still be displaying number
    -- but it won't work to start a new timer so this logic
    -- resets the input user and user won't be confused
    resetInputDigits()
  end

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

function onReset()
  noctalia.state.set("timer.cmd", "RESET")
  inputDigits = ""
  -- reseed the (now empty) input; the timer may have been running/paused,
  -- so the field could still show the old value.
  updateInputDigits()
  render()
end

function onInputChange(value)
  if STATE == "IDLE" then
    noctalia.state.set("timer.remaining", parseDigits(value))
    -- Keep our copy in sync with what the user is typing, but do NOT bump
    -- inputKey here: the input already holds `value`, and reseeding it
    -- mid-keystroke would reset the cursor. inputKey is only for pushing a
    -- new value into the input programmatically (open / reset).
    inputDigits = value
    render()
  end
end

function onInputSubmit()
  if STATE == "IDLE" then
    playTimer()
  elseif STATE == "PAUSED" then
    resumeTimer()
  end
end

function onToggle()
  if STATE == "RUNNING" then
    noctalia.state.set("timer.cmd", "PAUSE")
  elseif STATE == "IDLE" then
    playTimer()
  elseif STATE == "PAUSED" then
    resumeTimer()
  end
end
