--!nonstrict
-- config/noctalia/plugins/peripheral-battery/widget.luau
--
-- One meter per device in `devices`, in that order: an icon, a vertical power
-- meter, and a percentage. A device that isn't there takes up no space.

local PLUGGED = {
  charging = true,
  ["pending-charge"] = true,
  ["fully-charged"] = true,
  full = true,
  ["not charging"] = true,
}
local FULL = { ["fully-charged"] = true, full = true }

local DEFAULT_GLYPH = "battery-vertical"

-- What "Default" in the color dropdowns means, per state. The nil ones are on
-- purpose: an unset color prop is what inherits the bar's styling. The meter
-- can't be nil -- a box with no fill is no box.
local PALETTE = {
  charging = { meter = "on_surface" },
  charged = { meter = "on_surface" },
  discharging = { meter = "on_surface" },
  low = { glyph = "error", meter = "error", label = "error" },
}

local batteries = noctalia.state.get("batteries") or {}

local function setting(key, fallback)
  local value = noctalia.getConfig(key)
  if value == nil or value == "" then
    return fallback
  end
  return value
end

-- `devices` entries are `SUBSTRING=GLYPH`; the glyph is optional.
local function wanted()
  local out = {}
  for _, entry in ipairs(setting("devices", {})) do
    local name, glyph = string.match(entry, "^(.-)=(.*)$")
    name = noctalia.string.trim(name or entry)
    glyph = noctalia.string.trim(glyph or "")
    if name ~= "" then
      table.insert(out, {
        name = string.lower(name),
        glyph = glyph ~= "" and glyph or DEFAULT_GLYPH,
      })
    end
  end
  return out
end

local function find(name)
  for _, dev in ipairs(batteries) do
    for _, field in ipairs({ dev.model, dev.serial, dev.native, dev.path, dev.vendor }) do
      if field ~= "" and string.find(string.lower(field), name, 1, true) ~= nil then
        return dev
      end
    end
  end
  return nil
end

-- Anything not plugged is discharging, "unknown" included: a BlueZ headset
-- never reports a state at all, and it is not on the charger.
local function stateOf(dev, pct)
  if PLUGGED[dev.state] then
    if FULL[dev.state] or pct >= setting("full_at", 95) then
      return "charged"
    end
    return "charging"
  elseif pct <= setting("warn_below", 20) then
    return "low"
  end
  return "discharging"
end

local function meter(pct, color, track)
  local width = setting("meter_width", 9)
  local height = setting("meter_height", 16)
  local charge = math.clamp(math.floor(height * pct / 100 + 0.5), 0, height)
  if pct > 0 then
    charge = math.max(2, charge)
  end
  return ui.column({ gap = 1, align = "center" }, {
    ui.box({ width = math.max(3, math.min(width - 2, math.floor(width * 0.6))), height = 1, radius = 1, fill = track }),
    ui.column({ width = width, height = height, radius = 3, fill = track, justify = "end" }, {
      ui.box({ height = charge, radius = 3, fill = color }),
    }),
  })
end

local function container()
  return barWidget.isVertical() and ui.column or ui.row
end

-- One device's node, and its tooltip row.
local function draw(dev, glyph)
  local pct = math.clamp(math.floor(dev.percent + 0.5), 0, 100)
  local state = stateOf(dev, pct)
  local function color(element)
    return setting(`{state}_{element}_color`, PALETTE[state][element])
  end

  local children = {
    ui.glyph({ name = glyph, color = color("glyph") }),
    meter(pct, color("meter"), "on_surface/0.3"),
  }
  if PLUGGED[dev.state] and setting("show_charge_glyph", true) then
    local name = state == "charged" and setting("charged_glyph", "plug-filled")
      or setting("charging_glyph", "bolt-filled")
    table.insert(children, ui.glyph({ name = name, size = 10, color = color("glyph") }))
  end
  if setting("show_label", true) then
    local text = barWidget.isVertical() and tostring(pct) or `{pct}%`
    table.insert(children, ui.label({ text = text, color = color("label") }))
  end

  return container()({ gap = setting("gap", 4), align = "center" }, children), {
    key = dev.model ~= "" and dev.model or dev.native,
    value = `{pct}%, {(string.gsub(dev.state, "^%l", string.upper))}`,
  }
end

local function render()
  local nodes, rows, drawn = {}, {}, {}
  for _, want in ipairs(wanted()) do
    local dev = find(want.name)
    -- Two entries can match one device; it gets drawn under the first.
    if dev ~= nil and not drawn[dev] then
      drawn[dev] = true
      local node, row = draw(dev, want.glyph)
      table.insert(nodes, node)
      table.insert(rows, row)
    end
  end

  if #nodes == 0 then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)
  barWidget.render(container()({ gap = setting("device_gap", 8), align = "center" }, nodes))
  barWidget.setTooltip(rows)
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
