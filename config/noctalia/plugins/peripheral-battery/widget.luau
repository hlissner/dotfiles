--!nonstrict
-- config/noctalia/plugins/peripheral-battery/widget.luau
--
-- An icon, vertical power meter, and a percentage.

local PLUGGED = {
  charging = "bolt-filled",
  ["pending-charge"] = "plug-filled",
  ["fully-charged"] = "plug-filled",
  full = "plug-filled",
  ["not charging"] = "plug-filled",
}

local batteries = noctalia.state.get("batteries") or {}

local function setting(key, fallback)
  local value = noctalia.getConfig(key)
  if value == nil or value == "" then
    return fallback
  end
  return value
end

-- Find the device by name
local function find()
  local wanted = string.lower(setting("device", ""))
  if wanted == "" then
    return nil
  end
  for _, dev in ipairs(batteries) do
    for _, field in ipairs({ dev.model, dev.serial, dev.native, dev.path, dev.vendor }) do
      if field ~= "" and string.find(string.lower(field), wanted, 1, true) ~= nil then
        return dev
      end
    end
  end
  return nil
end

local function meter(pct, color, track)
  local width = setting("meter_width", 9)
  local height = setting("meter_height", 16)
  local charge = math.clamp(math.floor(height * pct / 100 + 0.5), 0, height)
  if pct > 0 then
    charge = math.max(2, charge)
  end
  return ui.column({ gap = 1, align = "center" }, {
    ui.box({ width = math.max(3, math.floor(width * 0.6)), height = 2, radius = 1, fill = track }),
    ui.column({ width = width, height = height, radius = 3, fill = track, justify = "end" }, {
      ui.box({ height = charge, radius = 3, fill = color }),
    }),
  })
end

local function render()
  local dev = find()
  if dev == nil then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  local pct = math.clamp(math.floor(dev.percent + 0.5), 0, 100)
  local plugged = PLUGGED[dev.state]
  local warn = plugged == nil and pct <= setting("warn_below", 20)
  local fg = warn and "error" or nil

  local children = {
    ui.glyph({ name = setting("glyph", "battery-vertical"), color = fg }),
    meter(pct, warn and "error" or "on_surface", "on_surface/0.3"),
  }
  if plugged ~= nil then
    table.insert(children, ui.glyph({ name = plugged, size = 10, color = fg }))
  end
  if setting("show_label", true) then
    local text = barWidget.isVertical() and tostring(pct) or `{pct}%`
    table.insert(children, ui.label({ text = text, color = fg }))
  end

  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = setting("gap", 4), align = "center" }, children))

  barWidget.setTooltip({
    { key = dev.model ~= "" and dev.model or dev.native, value = `{pct}%` },
    { key = "Status", value = (string.gsub(dev.state, "^%l", string.upper)) },
  })
end

noctalia.state.watch("batteries", function(value)
  batteries = value or {}
  render()
end)

function update()
  -- Don't rebuild as often (default isevery 250ms); editing settings already
  -- does this.
  noctalia.setUpdateInterval(60000)
  render()
end
