--!nonstrict
-- Countdown timer service - the headless [[service]] entry.
--
-- The service owns the timer state and handles the countdown logic.
-- It publishes state changes to other entries via noctalia.state,
-- and listens for commands (START, PAUSE, RESET) from panel and bar.
--
--   noctalia.setUpdateInterval(ms)     set tick rate for countdown
--   noctalia.state.set(key, value)     publish state to other entries
--   noctalia.state.watch(key, fn)      react to commands from UI entries
--   noctalia.notify(title, body)       alert user when timer completes

noctalia.setUpdateInterval(1000)

local function formatTime(seconds)
  local m = seconds // 60
  local s = seconds % 60
  if m >= 60 then
    return `{m // 60}:{string.format("%02d", m % 60)}:{string.format("%02d", s)}`
  end
  return `{m}:{string.format("%02d", s)}`
end

---- Initialize state
noctalia.state.set("timer.state", "IDLE") -- IDLE, NOTIFY, RUNNING, PAUSED
noctalia.state.set("timer.remaining", 0)
noctalia.state.set("timer.formattedTime", "0")
-- The countdown total captured when the timer starts, so UI entries can render
-- a progress bar (remaining / duration). Reset to 0 when the timer is cleared.
noctalia.state.set("timer.duration", 0)

noctalia.state.watch("timer.remaining", function (value)
  noctalia.state.set("timer.formattedTime", formatTime(value))
end)

noctalia.state.watch("timer.cmd", function(cmd)

  local actions = {
    PAUSE = function()
      noctalia.state.set("timer.state", "PAUSED")
    end,
    START = function ()
      local remaining = noctalia.state.get("timer.remaining")
      local STATE = noctalia.state.get("timer.state")

      if (STATE == "IDLE" or STATE == "PAUSED") and remaining > 0 then
        -- Capture the total on a fresh start so progress bars have a baseline;
        -- leave it untouched when resuming from PAUSED.
        if STATE == "IDLE" then
          noctalia.state.set("timer.duration", remaining)
        end
        noctalia.state.set("timer.state", "RUNNING")
      end
    end,
    RESET = function ()
      noctalia.state.set("timer.remaining", 0)
      noctalia.state.set("timer.duration", 0)
      noctalia.state.set("timer.state", "IDLE")
    end
  }


  local action = actions[cmd]
  if action then
    action()
  else
    noctalia.log(`Unknown command: {cmd}`)
  end

end)

-- send notification and sound when implemented
local function notifyUser()
  noctalia.notify(noctalia.tr("ui.notify_title"), noctalia.tr("ui.notify_body"))
end

function update()
  local STATE = noctalia.state.get("timer.state")
  local remaining = noctalia.state.get("timer.remaining")

  if STATE == "RUNNING" then
    if remaining > 0 then
      noctalia.state.set("timer.remaining", remaining - 1)
    else
      noctalia.state.set("timer.state", "NOTIFY")
      notifyUser()
    end

  end
end

-- HEY: the only way in from outside the shell; see config/noctalia/bin/timer.zsh.
function onIpc(event, payload)
  if event == "start" then
    local seconds = tonumber(payload)
    if seconds == nil or seconds <= 0 then
      noctalia.log(`Not a duration in seconds: {payload}`)
      return
    end
    -- Not RESET-then-START through timer.cmd: a state.watch callback is
    -- deferred onto this VM's mailbox rather than run inside set(), so RESET's
    -- handler lands *after* the remaining written here and zeroes it, and
    -- START then reads 0 and does nothing. (The panel gets away with a bare
    -- START only because it has no RESET racing it -- but a bare START is a
    -- no-op while a timer already runs, which is no good from a keybind.)
    -- Writing what START would have written is synchronous, and needs no
    -- callback to have run first.
    noctalia.state.set("timer.remaining", seconds)
    noctalia.state.set("timer.duration", seconds)
    noctalia.state.set("timer.state", "RUNNING")
  elseif event == "pause" or event == "reset" then
    noctalia.state.set("timer.cmd", string.upper(event))
  else
    noctalia.log(`Unknown ipc event: {event}`)
  end
end
