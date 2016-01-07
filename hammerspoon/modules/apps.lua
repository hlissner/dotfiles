local apps = {}

-- App-specific code, runs when you launch or switch to another app
App = {}
App.new = function(name)
  local self = {}
  self.name = name
  self.bindings = {}

  self.onActivateFn = nil
  self.onDeactivateFn = nil
  self.onLaunchedFn = nil
  self.onTerminatedFn = nil

  self.bind = function(mods, key, action, predicate)
    table.insert(self.bindings, {key = hs.hotkey.new(mods, key, action),
                                 predicate = predicate})
    return self
  end

  self.onActivate = function(fn)
    self.onActivateFn = fn
    return self
  end
  self.onDeactivate = function(fn)
    self.onDeactivateFn = fn
    return self
  end
  self.onLaunched = function(fn)
    self.onLaunchedFn = fn
    local app = hs.application.find(self.name)
    if app then
      self.launch(app)
      if app:isFrontmost() then
        self.activate(app)
      end
    end
    return self
  end
  self.onTerminated = function(fn)
    self.onTerminatedFn = fn
    return self
  end

  self.activate = function(appObject)
    if type(self.onActivateFn) == 'function' then
      self:onActivateFn(appObject)
    end
    self:enableBinds()
  end
  self.deactivate = function(appObject)
    if type(self.onDeactivateFn) == 'function' then
      self:onDeactivateFn(appObject)
    end
    self:disableBinds()
  end
  self.launch = function(appObject)
    if type(self.onLaunchedFn) == 'function' then
      self:onLaunchedFn(appObject)
    end
  end
  self.terminate = function(appObject)
    if type(self.onTerminatedFn) == 'function' then
      self:onTerminatedFn(appObject)
    end
    self:clearBinds()
  end

  self.enableBinds = function(self)
    hs.fnutils.each(self.bindings, function(b)
      if b.predicate and not b.predicate() then
        b.key:disable()
      else
        b.key:enable()
      end
    end)
  end

  self.disableBinds = function(self)
    hs.fnutils.each(self.bindings, function(b)
      if b and b.key then
          b.key:disable()
      end
    end)
  end

  self.clearBinds = function(self)
    self:disableBinds()
    self.bindings = {}
  end

  apps[name] = self
  return self
end

function invoke(keys, predicate)
  return function ()
    if predicate and not predicate() then
      return
    end
    if type(keys) == 'table' then
      hs.fnutils.each(keys, function (key)
                        if type(key) ~= 'table' then
                          key = {{}, key}
                        end
                        hs.eventtap.keyStroke(key[1], key[2])
      end)
    elseif type(keys) == 'string' then
      os.execute(keys)
    elseif type(keys) == 'function' then
      return keys()
    end
  end
end

--
function appGlobalWatcher(appName, eventType, appObject)
  if apps[appName] then
    if (eventType == hs.application.watcher.activated) then
      apps[appName].activate(appObject)
    elseif (eventType == hs.application.watcher.deactivated) then
      apps[appName].deactivate(appObject)
    elseif (eventType == hs.application.watcher.launched) then
      apps[appName].launch(appObject)
    elseif (eventType == hs.application.watcher.terminated) then
      apps[appName].terminate(appObject)
    end
  end
end
hs.application.watcher.new(appGlobalWatcher):start()

