--!nonstrict
-- config/noctalia/plugins/peripheral-battery/poll.luau
--
-- One poll for every widget, published on the plugin's state channel.

local SYSFS = "/sys/class/power_supply"

-- How soon after a connect to look again; see the runStream call at the bottom.
local SETTLE_MS = 1500

local function battery(fields)
  return {
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
  if dev.native ~= "" then
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

local scanning, queued = false, false
local scan

scan = function()
  if scanning then
    queued = true
    return
  end
  scanning = true

  local devices, seen = {}, {}

  local function publish()
    noctalia.state.set("batteries", devices)
    scanning = false
    if queued then
      queued = false
      scan()
    end
  end

  local function filterBluez()
    if not anyBluez(devices) then
      publish()
      return
    end
    local started = noctalia.runAsync("bluetoothctl devices Connected", function(result)
      if result.exitCode == 0 then
        dropDisconnected(devices, result.stdout)
      end
      publish()
    end)
    if not started then
      publish()
    end
  end

  fromSysfs(devices, seen)

  -- Async, so a wedged upowerd stalls nothing; the widgets hold their last
  -- publish until it answers. A missing binary comes back as exit 127 and
  -- leaves the sysfs half standing.
  local started = noctalia.runAsync("upower -d", function(result)
    if result.exitCode == 0 then
      fromUpower(result.stdout, devices, seen)
    end
    filterBluez()
  end)
  if not started then
    filterBluez()
  end
end

local function interval()
  return math.max(5, noctalia.getConfig("poll_seconds") or 30) * 1000
end

function update()
  noctalia.setUpdateInterval(interval())
  scan()
end

-- A service without this gets completely restarted on any settings edit, which
-- takes the monitor stream down with it.
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
