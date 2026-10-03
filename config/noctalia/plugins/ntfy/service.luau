--!nonstrict
-- config/noctalia/plugins/ntfy/service.luau
--
-- One `GET /topics/json` held open; ntfy writes a JSON object per line on it
-- (open, keepalive, message, poll_request) and this forks notify-send for
-- the messages. The id of the last one delivered rides in plugin state, which
-- is process-lifetime: a reconnect asks for `?since=<id>` and gets what the
-- outage missed, a restarted service doesn't replay what it already showed.

local MIN_BACKOFF_MS = 1000
local MAX_BACKOFF_MS = 60000
-- Tick rate while the stream is up. There's no switching the tick off, and a
-- dead handle is what it watches for anyway.
local IDLE_MS = 60000

local stream = nil      -- the live httpStream handle, nil between attempts
local subscribed = nil  -- the URL it was opened on, minus ?since
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

local function retryLater()
  noctalia.setUpdateInterval(backoff)
  backoff = math.min(backoff * 2, MAX_BACKOFF_MS)
end

local function onLine(line)
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
  retryLater()
end

local function connect()
  local url = endpoint()
  if url == nil then
    if not complained then
      complained = true
      noctalia.log("ntfy: no server or topics configured; idling")
    end
    noctalia.setUpdateInterval(IDLE_MS)
    return
  end
  local since = noctalia.state.get("ntfy.since")
  subscribed = url
  stream = noctalia.httpStream({
    url = if since ~= nil then `{url}?since={since}` else url,
  }, onLine, onClose)
  if stream == nil then
    -- Never left the building: offline mode, or a URL the client won't take.
    retryLater()
  else
    noctalia.setUpdateInterval(IDLE_MS)
  end
end

function update()
  if stream == nil then
    connect()
  end
end

-- Without this a settings edit restarts the runtime, stream and all. With it,
-- only the two settings that name the stream reconnect; app_name and icon are
-- read per message.
function onConfigChanged()
  complained = false
  if stream ~= nil and endpoint() == subscribed then
    return
  end
  if stream ~= nil then
    stream.stop()
    stream = nil
  end
  backoff = MIN_BACKOFF_MS
  connect()
end

function onExit()
  if stream ~= nil then
    stream.stop()
    stream = nil
  end
end

connect()
