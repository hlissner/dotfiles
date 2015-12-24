-- TODO: Turn into App class

core = {}
core.__index = core

function core.reload()
  hs.reload()
  hs.alert("Config reloaded!")
end

-- App-specific code, runs when you launch or switch to another app
apps = {}
function forApp(name, func)
  if type(name) == 'table' then
    for i = 1, #name do
      apps[name[i]] = func
    end
  else
    apps[name] = func
  end
end

-- App-specific keybinds
lastApp = ""
binds = {}
function bind(app, mods, key, pressedfn, releasedfn, repeatfn)
  if not binds[app] then
    binds[app] = {}
  end
  if not binds[app][mods] then
    binds[app][mods] = {}
  end
  if binds[app][mods][key] then
    binds[app][mods][key]:enable()
  else
    binds[app][mods][key] = hs.hotkey.bind(mods, key, nil, pressedfn, releasedfn, repeatfn)
  end
end

function appWatcher(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    if (lastApp ~= appName) and (binds[lastApp]) then
      for _, i in pairs(binds[lastApp]) do
        for _, j in pairs(i) do
          j:disable()
        end
      end
    end
    if apps[appName] then
      apps[appName](appName, eventType, appObject)
      lastApp = appName
    end
  end
end
local appWatcher = hs.application.watcher.new(appWatcher)
appWatcher:start()
