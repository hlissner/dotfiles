--!nonstrict
-- config/noctalia/plugins/ntfy/service.luau
--
-- One `GET /topics/json` held open; ntfy writes a JSON object per line on it
-- (open, keepalive, message, poll_request) and this forks notify-send for
-- the messages. The id of the last one delivered rides in plugin state, which
-- is process-lifetime: a reconnect asks for `?since=<id>` and gets what the
-- outage missed, a restarted service doesn't replay what it already showed.
--
-- The stream can die without saying so. httpStream sets no transfer timeout,
-- low-speed limit or TCP keepalive on its curl handle, so a socket the other
-- end dropped while this box slept stays half-open forever and onClose never
-- fires. The tick is the watchdog: ntfy sends a keepalive every
-- `keepalive_interval` seconds of silence, so a stream that's said nothing in
-- two of those is dead and gets dropped. The server won't tell us the
-- interval (`/v1/config` doesn't carry it), hence the setting.

local MIN_BACKOFF_MS = 1000
local MAX_BACKOFF_MS = 60000
-- Tick rate while the stream is up; each tick runs the staleness check, so it
-- bounds how late a dead stream is noticed. There's no switching it off.
local TICK_MS = 30000
-- Slack on top of two missed keepalives.
local STALE_SLACK_MS = 15000

local stream = nil      -- the live httpStream handle, nil between attempts
local subscribed = nil  -- the URL it was opened on, minus ?since
local lastSeen = 0      -- nowMs() of the last line, or of the connect
local backoff = MIN_BACKOFF_MS
local complained = false

-- ntfy priorities: 1 min, 2 low, 3 default, 4 high, 5 max.
local function urgency(priority)
  local p = tonumber(priority) or 3
  if p <= 2 then
    return "low"
  elseif p >= 4 then
    return "critical"
  end
  return "normal"
end

-- A per-topic setting (`app_names`, `icons`), falling back to the global one
-- (`app_name`, `icon`). An empty override counts as unset.
local function perTopic(msg, map, global)
  local overrides = noctalia.getConfig(map) or {}
  local value = msg.topic ~= nil and overrides[msg.topic] or nil
  if value == nil or value == "" then
    value = noctalia.getConfig(global)
  end
  return value
end

local function forward(msg)
  -- No app name anywhere means the topic is the app name.
  local app = perTopic(msg, "app_names", "app_name")
  if app == nil or app == "" then
    app = msg.topic or "ntfy"
  end
  local argv = { "notify-send", "-a", app, "-u", urgency(msg.priority) }
  local icon = perTopic(msg, "icons", "icon") or ""
  if icon ~= "" then
    table.insert(argv, "-i")
    table.insert(argv, icon)
  end
  table.insert(argv, "--")
  table.insert(argv, msg.title or msg.topic or "ntfy")
  table.insert(argv, msg.message or "")
  noctalia.runAsync(argv)
end

local function endpoint()
  local server = noctalia.getConfig("server") or ""
  local topics = noctalia.getConfig("topics") or {}
  if server == "" or #topics == 0 then
    return nil
  end
  return `{server}/{table.concat(topics, ",")}/json`
end

local function staleMs()
  local keepalive = tonumber(noctalia.getConfig("keepalive_interval")) or 45
  return keepalive * 2 * 1000 + STALE_SLACK_MS
end

local function drop()
  if stream ~= nil then
    stream.stop()
    stream = nil
  end
end

local function retryLater()
  noctalia.setUpdateInterval(backoff)
  backoff = math.min(backoff * 2, MAX_BACKOFF_MS)
end

local function onLine(line)
  lastSeen = noctalia.nowMs()
  local msg = noctalia.json.decode(line)
  if type(msg) ~= "table" then
    return
  end
  -- Anything parseable means the server's talking; a keepalive counts.
  backoff = MIN_BACKOFF_MS
  if msg.event ~= "message" then
    return
  end
  -- Belt and braces around `since`, in case a server ever treats it as
  -- inclusive.
  if msg.id ~= nil and msg.id == noctalia.state.get("ntfy.since") then
    return
  end
  forward(msg)
  if msg.id ~= nil then
    noctalia.state.set("ntfy.since", msg.id)
  end
end

local function onClose(result)
  stream = nil
  -- The server answered and said no (403 on a protected topic, say). Its
  -- error body already went through onLine and decoded to no event. Say so
  -- once; a dead LAN link gets no popup at all, just the backoff.
  if result.ok and (result.status < 200 or result.status >= 300) and not complained then
    complained = true
    noctalia.notifyError("ntfy", `{subscribed} answered {result.status}`)
  end
  noctalia.log(`ntfy: stream closed (ok={result.ok} status={result.status}); retrying in {backoff // 1000}s`)
  retryLater()
end

local function connect()
  local url = endpoint()
  if url == nil then
    if not complained then
      complained = true
      noctalia.log("ntfy: no server or topics configured; idling")
    end
    noctalia.setUpdateInterval(TICK_MS)
    return
  end
  local since = noctalia.state.get("ntfy.since")
  subscribed = url
  lastSeen = noctalia.nowMs()
  stream = noctalia.httpStream({
    url = if since ~= nil then `{url}?since={since}` else url,
  }, onLine, onClose)
  if stream == nil then
    -- Never left the building: offline mode, or a URL the client won't take.
    retryLater()
  else
    noctalia.log(`ntfy: subscribed to {url}`)
    noctalia.setUpdateInterval(TICK_MS)
  end
end

function update()
  -- nowMs is wall-clock, so a suspend shows up as one big gap on the first
  -- tick after waking rather than after another stale period of waiting.
  if stream ~= nil and noctalia.nowMs() - lastSeen > staleMs() then
    noctalia.log(`ntfy: nothing from {subscribed} in {staleMs() // 1000}s; reconnecting`)
    drop()
  end
  if stream == nil then
    connect()
  end
end

-- Without this a settings edit restarts the runtime, stream and all. With it,
-- only the two settings that name the stream reconnect; the rest are read
-- per message or per tick.
function onConfigChanged()
  complained = false
  if stream ~= nil and endpoint() == subscribed then
    return
  end
  drop()
  backoff = MIN_BACKOFF_MS
  connect()
end

-- `noctalia msg plugin hey/ntfy:stream all reconnect`, from the on-wakeup
-- hook: the link is presumed back, no point waiting for the watchdog.
function onIpc(event, payload)
  if event == "reconnect" then
    drop()
    backoff = MIN_BACKOFF_MS
    connect()
  else
    noctalia.log(`ntfy: unknown ipc event: {event}`)
  end
end

function onExit()
  drop()
end

connect()
