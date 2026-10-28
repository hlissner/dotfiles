--!nonstrict
-- config/noctalia/plugins/peripheral-battery/poll.luau
--
-- One poll for every widget, published on the plugin's state channel. Two
-- halves feed it: a poll (sysfs, then upower, then BlueZ to second-guess
-- upower) and a watcher for what's only on the wire (hidraw), which reports
-- on its own schedule. Either one publishes the union.

local SYSFS = "/sys/class/power_supply"
local HIDRAW = "/sys/class/hidraw"

-- How soon after a connect to look again; see the runStream call at the bottom.
local SETTLE_MS = 1500

-- The watcher ticks every 5s. Past this it's either dead or the machine was
-- asleep; one more poll of silence says which.
local HID_SILENCE_MS = 25000
-- A runtime gets four streams, and `upower --monitor` is one.
local HID_STARTS = 3
-- The vendors the watcher knows how to ask. Checked here so that on a machine
-- without any it is never forked at all.
local HID_VENDORS = { ["000028DE"] = true, ["0000260D"] = true }

local function battery(fields)
  return {
    id = fields.id or "",   -- what tells it apart; key() derives one if empty
    model = fields.model or "",
    native = fields.native or "",
    serial = fields.serial or "",
    vendor = fields.vendor or "",
    path = fields.path or "",
    percent = fields.percent or 0,
    state = string.lower(fields.state or "unknown"),
  }
end

local function key(dev)
  if dev.id ~= "" then
    return string.lower(dev.id)
  elseif dev.native ~= "" then
    return string.lower(string.match(dev.native, "([^/]+)$") or dev.native)
  end
  return string.lower(dev.model)
end

-- Waking from suspend (or catching a device mid-enumeration) leaves peripheral
-- with 0% battery and state="unknown" for a poll or two. EXTERMINATE.
local function unreadable(dev)
  return dev.state == "unknown" and dev.percent <= 0
end

local function add(devices, seen, dev)
  local k = key(dev)
  if k == "" or seen[k] or unreadable(dev) then
    return
  end
  seen[k] = true
  table.insert(devices, dev)
end

---- Sources

local function uevent(name)
  local text = noctalia.readFile(`{SYSFS}/{name}/uevent`)
  if text == nil then
    return nil
  end
  local out = {}
  for field, value in string.gmatch(text, "POWER_SUPPLY_([A-Z_]+)=([^\n]*)") do
    out[field] = value
  end
  return out
end

-- On a laptop this includes its own battery. Fine: nothing is drawn that a
-- widget's device list doesn't ask for.
local function fromSysfs(devices, seen)
  local names = noctalia.listDir(SYSFS)
  if names == nil then
    return
  end
  for _, name in ipairs(names) do
    local ev = uevent(name)
    if ev ~= nil and ev.TYPE == "Battery" and ev.CAPACITY ~= nil then
      add(devices, seen, battery({
        model = ev.MODEL_NAME or name,
        native = name,
        serial = ev.SERIAL_NUMBER,
        vendor = ev.MANUFACTURER,
        percent = tonumber(ev.CAPACITY),
        state = ev.STATUS,
      }))
    end
  end
end

local FIELDS = {
  ["native-path"] = "native",
  model = "model",
  serial = "serial",
  state = "state",
  vendor = "vendor",
}

local function fromUpower(text, devices, seen)
  local current = nil

  local function flush()
    if current ~= nil and current.percent ~= nil then
      add(devices, seen, battery(current))
    end
    current = nil
  end

  for line in string.gmatch(text, "[^\n]+") do
    if string.match(line, "^%S") ~= nil then
      flush()
      local path = string.match(line, "^Device:%s+(%S+)")
      if path ~= nil then
        current = { path = path }
      end
    elseif current ~= nil then
      local name, value = string.match(line, "^%s+([%w%-]+):%s+(.-)%s*$")
      if name == "percentage" then
        current.percent = tonumber(string.match(value, "^([%d%.]+)%%")) or current.percent
      elseif name ~= nil and FIELDS[name] ~= nil then
        current[FIELDS[name]] = value
      end
    end
  end
  flush()
end

-- Waking from suspend causes issues. upowerd persists "dead" devices from
-- before the suspend. BlueZ is needed to double check.
local function bluezMac(dev)
  local mac = string.match(dev.native, "^/org/bluez/.-/dev_(%x%x_%x%x_%x%x_%x%x_%x%x_%x%x)$")
  if mac == nil then
    return nil
  end
  return string.lower((string.gsub(mac, "_", ":")))
end

local function anyBluez(devices)
  for _, dev in ipairs(devices) do
    if bluezMac(dev) ~= nil then
      return true
    end
  end
  return false
end

local function dropDisconnected(devices, text)
  local connected = {}
  for mac in string.gmatch(text, "Device%s+(%S+)") do
    connected[string.lower(mac)] = true
  end
  for i = #devices, 1, -1 do
    local mac = bluezMac(devices[i])
    if mac ~= nil and not connected[mac] then
      table.remove(devices, i)
    end
  end
end

---- Announcing

local PREAMBLE = "event=$1 device=$2 model=$3 vendor=$4 " ..
  "serial=$5 native=$6 path=$7 percent=$8 state=$9; "

local function label(dev)
  if dev.model ~= "" then
    return dev.model
  elseif dev.vendor ~= "" then
    return dev.vendor
  end
  return dev.native ~= "" and dev.native or dev.path
end

local function fire(event, dev)
  local cmd = noctalia.getConfig(`on_{event}`)
  if cmd == nil or cmd == "" then
    return
  end
  noctalia.runAsync({
    "/bin/sh", "-c", PREAMBLE .. cmd, "peripheral-battery",
    event, key(dev), dev.model, dev.vendor, dev.serial, dev.native, dev.path,
    tostring(math.floor(dev.percent + 0.5)), dev.state,
  }, function(result)
    if result.exitCode ~= 0 then
      noctalia.log(`on_{event} exited {result.exitCode}: {noctalia.string.trim(result.stderr)}`)
    end
  end)
end

-- The mouse naps every few minutes and I don't need a popup for each one.
local function quiet(dev)
  for _, entry in ipairs(noctalia.getConfig("quiet") or {}) do
    local name = string.lower(noctalia.string.trim(entry))
    for _, field in ipairs({ dev.model, dev.serial, dev.native, dev.path, dev.vendor }) do
      if name ~= "" and field ~= "" and string.find(string.lower(field), name, 1, true) ~= nil then
        return true
      end
    end
  end
  return false
end

local function announce(event, dev)
  local notify = noctalia.getConfig("notify") or "never"
  if (notify == "both" or notify == event) and not quiet(dev) then
    noctalia.notify(label(dev), noctalia.tr(`notify.{event}`, {
      percent = tostring(math.floor(dev.percent + 0.5)),
    }))
  end
  fire(event, dev)
end

-- Connect/disconnect is the difference between two settled publishes, not
-- upower's own added/removed.
local known = nil

local function anyUpower(byKey)
  for _, dev in pairs(byKey) do
    if dev.path ~= "" then
      return true
    end
  end
  return false
end

local function diff(devices, outage)
  local now = {}
  for _, dev in ipairs(devices) do
    now[key(dev)] = dev
  end
  -- A dead upowerd takes every BlueZ device off the list at once, a dead
  -- watcher every hidraw one. That's one outage, not five disconnects -- nor
  -- five reconnects after, which leaving `known` alone takes care of.
  if outage and known ~= nil then
    return
  end
  -- The first publish is only a baseline; don't announce the already paired.
  if known ~= nil then
    for k, dev in pairs(now) do
      if known[k] == nil then
        announce("connect", dev)
      end
    end
    for k, dev in pairs(known) do
      if now[k] == nil then
        announce("disconnect", dev)
      end
    end
  end
  known = now
end

---- Publishing: the last poll plus whatever the watcher has

local polled = nil   -- nil until the first poll lands, so the baseline is whole
local hid = {}       -- node -> device, as the watcher last reported it

local function publish(outage)
  local devices, seen = {}, {}
  for _, dev in ipairs(polled or {}) do
    add(devices, seen, dev)
  end
  for _, dev in pairs(hid) do
    add(devices, seen, dev)
  end
  if polled ~= nil then
    diff(devices, outage)
  end
  noctalia.state.set("batteries", devices)
end

---- The watcher: `hey .dev hid-battery -w`, one JSON event per line

local hidSeenMs = nil   -- its last line; nil until started
local hidStarts = 0
local hidSilentPolls = 0

local function hidHardware()
  for _, name in ipairs(noctalia.listDir(HIDRAW) or {}) do
    local text = noctalia.readFile(`{HIDRAW}/{name}/device/uevent`)
    local vendor = text ~= nil and string.match(text, "HID_ID=%x+:(%x+):") or nil
    if vendor ~= nil and HID_VENDORS[vendor] then
      return true
    end
  end
  return false
end

local function onHidLine(line)
  hidSeenMs = noctalia.nowMs()
  hidSilentPolls = 0
  local ev = noctalia.json.decode(line)
  if ev == nil then
    return
  end
  if ev.event == "battery" then
    local dev = battery({
      -- hidraw numbers shuffle on replug; a serial, when there is one, doesn't.
      id = ev.serial ~= "" and ev.serial or ev.node,
      model = ev.name,
      native = ev.node,
      serial = ev.serial,
      percent = ev.percent,
      state = ev.state,
    })
    local old = hid[ev.node]
    hid[ev.node] = dev
    -- The Steam Controller reports every ~4s, and most are the same number.
    if old == nil or old.percent ~= dev.percent or old.state ~= dev.state then
      publish(false)
    end
  elseif ev.event == "gone" and hid[ev.node] ~= nil then
    hid[ev.node] = nil
    publish(false)
  end
end

local function startHid()
  if hidStarts >= HID_STARTS then
    noctalia.log("the hid-battery watcher keeps dying; disable and enable the plugin to try again")
    hidSeenMs = math.huge  -- never silent, never restarted
    return
  end
  hidStarts += 1
  hidSeenMs = noctalia.nowMs()
  hidSilentPolls = 0
  noctalia.runStream("hey .dev hid-battery --watch", onHidLine)
end

-- From update(): start the watcher once there's something for it to watch,
-- and notice when it goes quiet.
local function mindHid()
  if hidSeenMs == nil then
    if hidHardware() then
      startHid()
    end
    return
  end
  if noctalia.nowMs() - hidSeenMs < HID_SILENCE_MS then
    return
  end
  hidSilentPolls += 1
  if hidSilentPolls == 1 then
    -- Could be a resume: a live watcher ticks again within seconds. Drop its
    -- devices meanwhile, as an outage rather than a disconnect each.
    if next(hid) ~= nil then
      hid = {}
      publish(true)
    end
  else
    -- Still nothing a whole poll later. It's dead.
    noctalia.log("the hid-battery watcher went silent; restarting it")
    startHid()
  end
end

---- The poll

local scanning, queued = false, false
local scan

-- runAsync, except a command that couldn't be launched still calls back, so
-- a chain of these can't stall on a missing binary.
local function run(cmd, cb)
  if not noctalia.runAsync(cmd, cb) then
    cb(nil)
  end
end

local function ok(result)
  return result ~= nil and result.exitCode == 0
end

scan = function()
  if scanning then
    queued = true
    return
  end
  scanning = true

  local devices, seen = {}, {}
  local upowerOk = false

  local function finish()
    polled = devices
    publish(not upowerOk and known ~= nil and anyUpower(known))
    scanning = false
    if queued then
      queued = false
      scan()
    end
  end

  fromSysfs(devices, seen)

  -- Async, so a wedged upowerd stalls nothing; the widgets hold their last
  -- publish until it answers. A missing binary comes back as exit 127 and
  -- leaves the sysfs half standing.
  run("upower -d", function(result)
    if ok(result) then
      upowerOk = true
      fromUpower(result.stdout, devices, seen)
    end
    if not anyBluez(devices) then
      return finish()
    end
    run("bluetoothctl devices Connected", function(result)
      if ok(result) then
        dropDisconnected(devices, result.stdout)
      end
      finish()
    end)
  end)
end

local function interval()
  return math.max(5, noctalia.getConfig("poll_seconds") or 30) * 1000
end

function update()
  noctalia.setUpdateInterval(interval())
  mindHid()
  scan()
end

-- A service without this gets completely restarted on any settings edit, which
-- takes both streams down with it.
function onConfigChanged()
  noctalia.setUpdateInterval(interval())
end

-- stdbuf because upower prints through glib, which block-buffers into a pipe:
-- without it the lines arrive 4KB late, which for this volume means never.
--
-- Only added/removed. `changed` is every percentage tick of every battery in
-- the machine, and chasing those would scan more often than the poll it's
-- meant to front -- drifting charge is exactly what poll_seconds is for.
noctalia.runStream("stdbuf -oL upower --monitor", function(line)
  local event = string.match(line, "device (%a+):")
  if event ~= "added" and event ~= "removed" then
    return
  end
  -- A disconnect is true the instant it's announced. A connect isn't: BlueZ
  -- reports the new device at 0%/unknown for a second or two, which
  -- unreadable() rightly throws away. So scan now for the vanishing case, and
  -- drag the next tick in close behind to catch the settled number -- update()
  -- puts the interval back where it belongs.
  scan()
  if event == "added" then
    noctalia.setUpdateInterval(SETTLE_MS)
  end
end)
