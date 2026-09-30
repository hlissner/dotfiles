--!nonstrict
-- config/noctalia/plugins/compass/widget.luau
--
-- A dial cut on the diagonals into four quadrants, one per compass point:
-- north/south light up for occupied workspaces that way (the one facing home
-- in its own colour), west/east for windows off-screen that way, and a badge
-- in the middle counts the SUPER+j/k presses home. Draws the service's line
-- for the monitor this bar is on, and nothing else.
--
-- It's an SVG, not a ui.* tree. The reconciler has one radius for all four
-- corners, no overlay and no clipping, so anything wedge-shaped or two-tone
-- is out of reach; ui.image goes through librsvg and clips to whatever the
-- SVG says. Two consequences: the reconciler only reloads an image when
-- its *path* changes, so every distinct look is its own file, named by a hash
-- of its contents; and colours have to be real hex, via noctalia.getColor.

local output = barWidget.outputName()
local compass = noctalia.state.get("compass") or {}

local cacheDir = (noctalia.getenv("XDG_CACHE_HOME") or `{noctalia.getenv("HOME")}/.cache`)
  .. "/noctalia/hey-compass"
noctalia.mkdirAll(cacheDir)
-- Bounded, not swept: a file that vanishes under a bar showing it comes back
-- blank, since the same path won't be loaded twice.
if #(noctalia.listDir(cacheDir) or {}) > 256 then
  for _, name in ipairs(noctalia.listDir(cacheDir) or {}) do
    noctalia.removeFile(`{cacheDir}/{name}`)
  end
end

local function setting(key, fallback)
  local value = noctalia.getConfig(key)
  if value == nil or value == "" then
    return fallback
  end
  return value
end

-- What "Default" in the color dropdowns means, per state.
local PALETTE = {
  normal = {
    fill = "on_surface/0.12", workspace_color = "primary", home_color = "secondary",
    window_color = "tertiary", divider_color = "shadow",
    badge_color = "surface", text_color = "on_surface",
  },
  special = {
    fill = "tertiary/0.25", workspace_color = "tertiary", home_color = "primary",
    window_color = "secondary", divider_color = "shadow",
  },
}

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

local function paint(spec)
  if spec == nil then
    return nil
  end
  local hex, opacity = rgba(spec)
  if hex == nil then
    return nil
  end
  return `fill="{hex}" fill-opacity="{string.format("%.3f", opacity)}"`
end

local function rect(x, y, w, h, spec)
  local p = paint(spec)
  return p and `<rect x="{x}" y="{y}" width="{w}" height="{h}" {p}/>` or ""
end

local function hash(s)
  local h = 5381
  for i = 1, #s do
    h = (h * 33 + string.byte(s, i)) % 4294967296
  end
  return string.format("%08x", h)
end

local function svg(c)
  local size = setting("size", 20)
  local shape = setting("shape", "circle")
  local radius = setting("radius", 5)
  local divider = setting("divider", 1)
  local state = c.special and "special" or "normal"
  local prefix = c.special and "special_" or ""
  local function color(key)
    return setting(prefix .. key, PALETTE[state][key])
  end
  local hops = c.hops or 0

  -- Positive is south of home, so home is up. Its quadrant is lit whatever's
  -- up there -- home is a workspace that way, occupied or not.
  local quadrant = {
    north = hops > 0 and color("home_color") or (c.north and color("workspace_color")) or nil,
    south = hops < 0 and color("home_color") or (c.south and color("workspace_color")) or nil,
    west = c.west and color("window_color") or nil,
    east = c.east and color("window_color") or nil,
  }

  -- 0 in either setting means "derive it", so a size change moves both.
  local circle = setting("badge_size", 0)
  if circle <= 0 then
    circle = math.floor(size * 0.5 + 0.5)
  end
  local font = setting("font_size", 0)
  if font <= 0 then
    font = math.max(6, math.floor(circle * 0.8))
  end

  -- The pizza: four triangles from the centre to the corners of the bounding
  -- square, and the outline clips them to a circle or a rounded square. The
  -- dividers are the two diagonals drawn over the top.
  local mid = string.format("%.1f", size / 2)
  local outline = shape == "square"
    and `<rect width="{size}" height="{size}" rx="{radius}"/>`
    or `<circle cx="{mid}" cy="{mid}" r="{mid}"/>`
  local corner = {
    north = `0,0 {size},0 {mid},{mid}`,
    east = `{size},0 {size},{size} {mid},{mid}`,
    south = `{size},{size} 0,{size} {mid},{mid}`,
    west = `0,{size} 0,0 {mid},{mid}`,
  }

  local out = {
    `<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">`,
    `<clipPath id="c">{outline}</clipPath>`,
    `<g clip-path="url(#c)">`,
    rect(0, 0, size, size, color("fill")),
  }
  for _, dir in ipairs({ "north", "east", "south", "west" }) do
    local p = paint(quadrant[dir])
    if p then
      table.insert(out, `<polygon points="{corner[dir]}" {p}/>`)
    end
  end
  if divider > 0 then
    local hex, opacity = rgba(color("divider_color"))
    if hex then
      local stroke = `stroke="{hex}" stroke-opacity="{string.format("%.3f", opacity)}" stroke-width="{divider}"`
      table.insert(out, `<line x1="0" y1="0" x2="{size}" y2="{size}" {stroke}/>`)
      table.insert(out, `<line x1="{size}" y1="0" x2="0" y2="{size}" {stroke}/>`)
    end
  end
  table.insert(out, "</g>")
  -- A scratchpad isn't on the tape; the count is still there for when it
  -- drops, but it isn't the question being asked right now.
  if hops ~= 0 and not c.special then
    local badge = paint(color("badge_color"))
    if badge then
      table.insert(out, `<circle cx="{mid}" cy="{mid}" r="{string.format("%.1f", circle / 2)}" {badge}/>`)
    end
    local text = paint(color("text_color"))
    if text then
      -- librsvg has no dominant-baseline worth trusting; a bold digit's
      -- cap height is about 0.7em, so lift the baseline by half of that.
      local baseline = string.format("%.1f", size / 2 + font * 0.36)
      table.insert(out, `<text x="{mid}" y="{baseline}" text-anchor="middle" `
        .. `font-family="{setting("font_family", "sans-serif")}" font-weight="bold" font-size="{font}" {text}>`
        .. `{math.abs(hops)}</text>`)
    end
  end
  table.insert(out, "</svg>")
  return table.concat(out, "\n")
end

local function render()
  local c = (output ~= nil and compass[output]) or {}
  local body = svg(c)
  local file = `{cacheDir}/{hash(body)}.svg`
  if not noctalia.fileExists(file) then
    noctalia.writeFile(file, body)
  end
  local size = setting("size", 20)
  barWidget.render(ui.image({ path = file, width = size, height = size, fit = "contain" }))

  local hops = c.hops or 0
  local rows = {
    { key = "Home", value = hops == 0 and "Here"
        or `{math.abs(hops)} {hops > 0 and "up" or "down"}` },
  }
  local around = {}
  for _, dir in ipairs({ "north", "south", "west", "east" }) do
    if c[dir] then
      table.insert(around, dir)
    end
  end
  if #around > 0 then
    table.insert(rows, { key = "More", value = table.concat(around, ", ") })
  end
  if c.special then
    table.insert(rows, { key = "Special", value = "Active" })
  end
  barWidget.setTooltip(rows)
end

noctalia.state.watch("compass", function(value)
  compass = value or {}
  render()
end)

function update()
  -- The service's state channel drives this; the tick only picks up a theme
  -- change, since the colours are baked into the file.
  noctalia.setUpdateInterval(10000)
  render()
end
