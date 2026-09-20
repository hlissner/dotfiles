--!nonstrict
-- config/noctalia/plugins/screencast/widget.luau
--
-- screencast.zsh leaves two traces behind, and the gap between them is the
-- reason this file has a state machine:
--
--   the .live file   exists while the script will still answer a stop request,
--                    and holds the epoch second wf-recorder started at. Empty
--                    means a session that hasn't got past the countdown yet --
--                    picking a region is not recording. The stop path deletes
--                    the file before the muxer is done, on purpose, so I can
--                    start the next recording immediately.
--   wf-recorder      alive until the container is actually finalized.
--
-- So the file answers "recording?", its contents date the clock, and once it
-- is gone the process answers "still working?". The glyph leaves only when
-- both say no.
--
-- Caveat: `screencast gif` shells out to gifsicle after wf-recorder exits, and
-- that stretch isn't covered. I never use gif.

local IDLE, RECORDING, STOPPING = 1, 2, 3

-- ui.glyph takes name/size/color and nothing else -- no rotation, and bar
-- widgets get no onFrameTick -- so the only spinner available is a glyph
-- family that already draws its own frames. This is the only one Tabler has.
local SPINNER = {
  "clock-hour-12", "clock-hour-1", "clock-hour-2", "clock-hour-3",
  "clock-hour-4", "clock-hour-5", "clock-hour-6", "clock-hour-7",
  "clock-hour-8", "clock-hour-9", "clock-hour-10", "clock-hour-11",
}
local SPINNER_MS = 100    -- one revolution every 1.2s
local BLINK_MS = 1600     -- "slowly": lit for 0.8s, inherited for 0.8s

-- Fast enough to animate, idle enough to be free. The floor upstream enforces
-- is 16ms, so none of these are near anything.
local TICK = { [IDLE] = 500, [RECORDING] = 250, [STOPPING] = SPINNER_MS }

local livefile = nil    -- `hey path runtime screencast` .. ".live"
local startedAt = nil   -- epoch seconds, from the file
local state = IDLE
local probing = false

local function setting(key, fallback)
  local value = noctalia.getConfig(key)
  if value == nil then
    return fallback
  end
  return value
end

-- Empty is a real answer: it means "inherit the bar", which is what an unset
-- color prop does. Only a name gets to override the widget's own styling.
local function color(key)
  local value = noctalia.getConfig(key)
  if value == nil or value == "" then
    return nil
  end
  return value
end

local function elapsed(secs)
  local s = math.max(0, math.floor(secs))
  local h, m = s // 3600, (s % 3600) // 60
  if h > 0 then
    return string.format("%d:%02d:%02d", h, m, s % 60)
  end
  return string.format("%d:%02d", m, s % 60)
end

local function render()
  if state == IDLE then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  local now = noctalia.nowMs()
  local children = {}
  local tip

  if state == STOPPING then
    table.insert(children, ui.glyph({
      name = SPINNER[(now // SPINNER_MS) % #SPINNER + 1],
      color = color("stopping_color"),
    }))
    tip = noctalia.tr("tooltip.stopping")
  else
    local lit = color("recording_color")
    -- Half the cycle lit, half inherited. Phase comes off the wall clock, not
    -- a tick count, so a late tick skips a frame instead of dragging the beat.
    if lit ~= nil and setting("blink", true) and now % BLINK_MS >= BLINK_MS // 2 then
      lit = nil
    end
    table.insert(children, ui.glyph({ name = setting("glyph", "player-play-filled"), color = lit }))
    -- The label is left uncolored on purpose: blinking it too would read as a
    -- fault, and a side bar has no room for "12:34" at all.
    if startedAt ~= nil and setting("show_elapsed", true) and not barWidget.isVertical() then
      table.insert(children, ui.label({ text = elapsed(now / 1000 - startedAt) }))
    end
    tip = noctalia.tr("tooltip.recording")
  end

  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 4, align = "center" }, children))
  -- Never cleared: clearing a tooltip that isn't there takes the plugin down.
  barWidget.setTooltip(tip)
end

local function startTime()
  if not noctalia.fileExists(livefile) then
    return nil
  end
  local raw = noctalia.readFile(livefile)
  return raw ~= nil and tonumber(raw) or nil
end

local function probe()
  if probing then
    return
  end
  probing = true
  noctalia.processMatches(function(matched)
    probing = false
    if state == STOPPING and not matched then
      state = IDLE
      render()
    end
  end, "wf-recorder")
end

function update()
  if livefile ~= nil then
    local started = startTime()
    if started ~= nil then
      startedAt = started
      state = RECORDING
    elseif state == RECORDING then
      state = STOPPING  -- the file is gone; the muxer may not be
    elseif state == STOPPING then
      probe()
    end
  end
  -- After the transition, never before: ask for the new state's rate on the
  -- tick that enters it, or the spinner's first frame runs at the old one.
  noctalia.setUpdateInterval(TICK[state])
  -- Unconditional: the spinner and the clock both move without a state change.
  render()
end

function onClick()
  -- Re-entering the script while the .live file exists *is* its stop switch.
  -- Deliberately not optimistic about the result: if the spawn fails, the next
  -- tick still finds the file and the glyph goes on telling the truth.
  if state == RECORDING then
    noctalia.runAsync({ "hey", ".screencast" })
  end
end

-- hey owns this path. Asking it once beats spelling $XDG_RUNTIME_DIR/hey/ here
-- and finding out it moved the hard way.
noctalia.runAsync({ "hey", "path", "runtime", "screencast" }, function(res)
  if res.exitCode ~= 0 then
    noctalia.log(`screencast: cannot locate the live file: {res.stderr}`)
    return
  end
  livefile = `{(string.gsub(res.stdout, "%s+$", ""))}.live`
end)
