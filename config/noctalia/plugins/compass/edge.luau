--!nonstrict
-- config/noctalia/plugins/compass/edge.luau
--
-- Draw a soft glow along an edge of the monitor to indicate an empty workspace
-- (north/south) or window (west/east) in that direction.

local PALETTE = { edge_color = "primary", edge_named_color = "tertiary" }

local cacheDir = (noctalia.getenv("XDG_CACHE_HOME") or `{noctalia.getenv("HOME")}/.cache`) .. "/noctalia/hey-compass"
noctalia.mkdirAll(cacheDir)

-- "role", "role/0.4", "#rrggbb" or "#rrggbbaa" -> hex, opacity.
local function rgba(spec)
  local name, alpha = string.match(spec, "^([^/]+)/?([%d%.]*)$")
  if name == nil then
    return nil
  end
  local hex = string.sub(name, 1, 1) == "#" and name or noctalia.getColor(name)
  if hex == nil then
    return nil
  end
  local opacity = tonumber(alpha) or 1
  if #hex == 9 then
    opacity *= tonumber(string.sub(hex, 8, 9), 16) / 255
    hex = string.sub(hex, 1, 7)
  end
  return hex, opacity
end

local function hash(s)
  local h = 5381
  for i = 1, #s do
    h = (h * 33 + string.byte(s, i)) % 4294967296
  end
  return string.format("%08x", h)
end

-- Mapping out the radial fade/gradiant
local AXIS = {
  north = { cx = 0.5, cy = 0, x2 = 0, y2 = 1 },
  south = { cx = 0.5, cy = 1, x2 = 0, y2 = -1 },
  west = { cx = 0, cy = 0.5, x2 = 1, y2 = 0 },
  east = { cx = 1, cy = 0.5, x2 = -1, y2 = 0 },
}

local function gradient(dir, length, depth, rounding, spec)
  local hex, opacity = rgba(spec)
  if hex == nil then
    return nil
  end
  opacity *= (noctalia.getConfig(`edge_opacity_{dir}`) or 70) / 100
  local a = AXIS[dir]
  local along = a.cx == 0.5
  local w = along and length or depth
  local h = along and depth or length
  local stops = table.concat({
    `<stop offset="0" stop-color="{hex}" stop-opacity="{string.format("%.3f", opacity)}"/>`,
    `<stop offset="0.5" stop-color="{hex}" stop-opacity="{string.format("%.3f", opacity * 0.4)}"/>`,
    `<stop offset="1" stop-color="{hex}" stop-opacity="0"/>`,
  }, "\n")
  local fill
  if rounding <= 0 then
    fill = `<linearGradient id="g" x1="{a.cx}" y1="{a.cy}" x2="{a.cx + a.x2}" y2="{a.cy + a.y2}">{stops}</linearGradient>`
  else
    -- r=0.5 is half the box each way; scale the long axis so the corners sit at
    -- (1 - rounding) of the radius, and the short one to the depth.
    local long = string.format("%.4f", 1 / (rounding / 100))
    local sx, sy = along and long or "2", along and "2" or long
    fill = `<radialGradient id="g" cx="{a.cx}" cy="{a.cy}" r="0.5" `
      .. `gradientTransform="translate({a.cx},{a.cy}) scale({sx},{sy}) translate({-a.cx},{-a.cy})">`
      .. `{stops}</radialGradient>`
  end
  local body = table.concat({
    `<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">`,
    fill,
    `<rect width="{w}" height="{h}" fill="url(#g)"/>`,
    `</svg>`,
  }, "\n")
  local file = `{cacheDir}/{hash(body)}.svg`
  if not noctalia.fileExists(file) then
    noctalia.writeFile(file, body)
  end
  return file
end

return function(dir, layer)
  local output = layer.outputName()
  local compass = noctalia.state.get("compass") or {}
  local overview = noctalia.state.get("overview") == true

  local function setting(key)
    local value = noctalia.getConfig(key)
    if value == nil or value == "" then
      return PALETTE[key]
    end
    return value
  end

  -- The surface's own size isn't exposed;
  local function extent()
    for _, o in ipairs(noctalia.outputs()) do
      if o.name == output then
        return o.width, o.height
      end
    end
    return 1, 1
  end

  local function render()
    local c = (output ~= nil and compass[output]) or {}
    local depth = noctalia.getConfig("edge_width") or 12
    local ow, oh = extent()
    local along = (dir == "north" or dir == "south")
    local file = nil
    if c[dir] == true and not overview then
      file = gradient(dir, along and ow or oh, depth, noctalia.getConfig("edge_rounding") or 60,
        setting(c[dir .. "_named"] and "edge_named_color" or "edge_color"))
    end
    local children = {}
    if file then
      table.insert(children, ui.image({
        path = file,
        width = along and ow or depth,
        height = along and depth or oh,
        fit = "stretch",
        radius = 0,
      }))
    end
    layer.render(ui.column({ flexGrow = 1, fill = "#00000000" }, children))
  end

  noctalia.state.watch("compass", function(value)
    compass = value or {}
    render()
  end)
  noctalia.state.watch("overview", function(value)
    overview = value == true
    render()
  end)

  render()
  return { render = render }
end
