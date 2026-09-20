--!nonstrict
-- config/noctalia/plugins/hypr-submap/submap.luau
--
-- Hyprland announces submap changes on .socket2.sock and nowhere else, so the
-- only way to watch one is to hold the socket open. `hyprctl submap` seeds the
-- first value; after that it's all socat.

local currentSubmap = ""

local function setting(key, fallback)
  local value = noctalia.getConfig(key)
  if value == nil or value == "" then
    return fallback
  end
  return value
end

local function socketPath()
  local sig = noctalia.getenv("HYPRLAND_INSTANCE_SIGNATURE")
  local runtimeDir = noctalia.getenv("XDG_RUNTIME_DIR")
  if sig == nil or runtimeDir == nil then
    return nil
  end
  return `{runtimeDir}/hypr/{sig}/.socket2.sock`
end

local function render()
  -- Hyprland spells "no submap" as the empty string; the settings spell it
  -- "default", and so does anyone writing a glyph for it.
  local submap = if currentSubmap == "" then "default" else currentSubmap

  if submap == "default" and setting("hide_when_default", false) then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  barWidget.setGlyph(setting("glyphs", {})[submap] or setting("glyph", "keyboard"))
  -- An empty string is how you take the label off.
  barWidget.setText(
    if setting("show_label", true) then `{setting("prefix", "")}{submap}` else ""
  )
  -- The glyph is the whole widget now, so this is the only thing left that
  -- names which submap you're actually in.
  barWidget.setTooltip(submap)
end

local sock = socketPath()
if sock ~= nil then
  -- runAsync hands the callback a result table, not the bare stdout upstream
  -- assumed -- so this seed threw on every start and the widget sat on "" until
  -- the first submap change came down the socket.
  noctalia.runAsync("hyprctl submap", function(result)
    if result ~= nil and result.exitCode == 0 then
      currentSubmap = noctalia.string.trim(result.stdout)
      render()
    end
  end)
  noctalia.runStream(`stdbuf -oL -eL socat -u UNIX-CONNECT:{sock} -`, function(line)
    local match = line:match("submap>>(.*)")
    if match ~= nil then
      currentSubmap = noctalia.string.trim(match)
      render()
    end
  end)
end

function update()
  render()
end

function onClick()
  noctalia.runAsync("hyprctl dispatch 'hl.dsp.submap(\"reset\")' ")
end
