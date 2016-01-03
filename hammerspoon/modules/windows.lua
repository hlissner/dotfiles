-- TODO: Window management library

local function currentFrame()
  return hs.window.focusedWindow():frame()
end

local function currentScreenFrame()
  return hs.window.focusedWindow():screen():frame()
end

----------------------------------------
window = {
  direction = {
    up = 1,
    down = 2,
    left = 4,
    right = 8
  },

  history = {},
  historyLimit = 20,
  historyIndex = 1
}

function window:move (f, window, remember)
  if window == nil then
    window = hs.window.focusedWindow()
  end
  local oldFrame = window:frame()
  if oldFrame ~= f then
    window:move(hs.geometry(f.x, f.y, f.w, f.h))
    if remember ~= false then
      self:remember(oldFrame)
    end
  end
end

function window:center ()
  local s = currentScreenFrame()
  local f = currentFrame()
  self:move({x = (s.w / 2) - (f.w / 2), y = (s.h / 2) - (f.h / 2), w = f.w, h = f.h})
end

function window:maximize ()
  local f = currentFrame()
  self:move(currentScreenFrame())
end

function window:slide (direction, amount)
  local f = currentFrame()
  local s = currentScreenFrame()
  if direction == self.direction.up then
    f.y = amount == true and s.y or f.y - amount
  elseif direction == self.direction.down then
    if amount == true then
      f.y = s.y + (s.h - f.h)
    else
      f.y = f.y + amount
    end
  elseif direction == self.direction.left then
    if amount == true then
      if f.x == s.x then
        hs.window.focusedWindow():moveOneScreenWest()
      end
      s = currentScreenFrame()
      f.x = s.x
    else
      f.x = f.x - amount
    end
  elseif direction == self.direction.right then
    if amount == true then
      if f.x == (s.x + (s.w - f.w)) then
        hs.window.focusedWindow():moveOneScreenEast()
      end
      s = currentScreenFrame()
      f.x = s.x + (s.w - f.w)
    else
      f.x = f.x + amount
    end
  end
  self:move(f)
end

-- TODO Multiple monitor support
function window:resizeIn (direction, amount)
  local f = currentFrame()
  local s = currentScreenFrame()
  if direction == self.direction.up then
    if amount == true then
    else
      f.h = f.h - amount
    end
  elseif direction == self.direction.down then
    -- f.h = amount == true and 10 or f.h - amount
    if amount == true then
    else
      f.h = f.h - amount
      f.y = f.y + amount
    end
  elseif direction == self.direction.left then
    if amount == true then
    else
      f.w = f.w - amount
    end
  elseif direction == self.direction.right then
    if amount == true then
    else
      f.w = f.w - amount
      f.x = f.x + amount
    end
  end
  self:move(f)
end

-- TODO Improve multiple monitor support
function window:resizeOut (direction, amount)
  local f = currentFrame()
  local s = currentScreenFrame()
  if direction == self.direction.up then
    if amount == true then
      f.h = f.h + f.y
      f.y = 0
    else
      f.h = f.h + amount
      f.y = f.y - amount
    end
  elseif direction == self.direction.down then
    if amount == true then
      f.h = s.h - f.y
    else
      f.h = f.h + amount
    end
  elseif direction == self.direction.left then
    if amount == true then
      f.w = f.w + f.x
      f.x = 0
    else
      f.w = f.w + amount
      f.x = f.x - amount
    end
  elseif direction == self.direction.right then
    -- FIXME If on other monitor, extends past boundaries
    if amount == true then
      f.w = s.w - f.x
    else
      f.w = f.w + amount
    end
  end
  self:move(f)
end

function window:undo ()
  if #self.history > 0 and self.historyIndex > 0 then
    self.historyIndex = self.historyIndex - 1
    local win = self.history[self.historyIndex]
    win[2]:move(win[1])
  else
    hs.alert("Can't undo further")
  end
end

function window:redo ()
  if self.historyIndex < #self.history then
    self.historyIndex = self.historyIndex + 1
    local win = self.history[self.historyIndex]
    win[2]:move(win[1])
  else
    hs.alert("Can't redo further")
  end
end

function window:remember(frame)
  if frame ~= self.history[#self.history] then
    if self.historyIndex < #self.history then
      for i = #self.history, self.historyIndex do
        table.remove(self.history, i)
      end
    end
    table.insert(self.history, {frame, hs.window.focusedWindow()})
    self.historyIndex = self.historyIndex + 1
    if #self.history > self.historyLimit then
      table.remove(self.history, 1)
    end
  end
end

--
local globalMode = hs.hotkey.modal.new()
local modes = {
  position = hs.hotkey.modal.new('cmd-ctrl', 'up'),
  resizeTL = hs.hotkey.modal.new('cmd-ctrl', 'left'),
  resizeBR = hs.hotkey.modal.new('cmd-ctrl', 'right'),
}
local currentMode = nil

-- Screen overlay
local function initOverlay(width, height)
  local f = hs.screen.primaryScreen():frame()
  return hs.drawing.rectangle(hs.geometry(
                                (f.w / 2) - (width / 2),
                                (f.h / 2) - (height / 2),
                                width, height))
    :setAlpha(0.65)
    :setFillColor(hs.drawing.color.black)
    :bringToFront()
end
local overlay = initOverlay(300, 400)

--
for key, modal in pairs(modes) do
  modal:bind('', 'escape', function() modal:exit() end)

  modal.entered = function (self)
    for k, m in pairs(modes) do
      if k ~= key then m:exit() end
    end
    currentMode = key
    globalMode:enter()
    overlay:show()
  end
  modal.exited = function (self)
    if currentMode == key then
      currentMode = nil
      globalMode:exit()
      overlay:hide()
    end
  end
end

local step = 10
local bigstep = 100

globalMode
:bind('', '=',          function() window:center() end)
:bind('shift', '=',     function() window:maximize() end)
:bind('cmd', 'z',       function() window:undo() end)
:bind('cmd-shift', 'z', function() window:redo() end)

modes.position
:bind('', 'up',         function() window:slide(window.direction.up,         1) end)
:bind('', 'down',       function() window:slide(window.direction.down,       1) end)
:bind('', 'left',       function() window:slide(window.direction.left,       1) end)
:bind('', 'right',      function() window:slide(window.direction.right,      1) end)

:bind('cmd', 'up',      function() window:slide(window.direction.up,         true) end)
:bind('cmd', 'down',    function() window:slide(window.direction.down,       true) end)
:bind('cmd', 'left',    function() window:slide(window.direction.left,       true) end)
:bind('cmd', 'right',   function() window:slide(window.direction.right,      true) end)

:bind('shift', 'up',    function() window:slide(window.direction.up,         step) end)
:bind('shift', 'down',  function() window:slide(window.direction.down,       step) end)
:bind('shift', 'left',  function() window:slide(window.direction.left,       step) end)
:bind('shift', 'right', function() window:slide(window.direction.right,      step) end)

:bind('alt', 'up',      function() window:slide(window.direction.up,         bigstep) end)
:bind('alt', 'down',    function() window:slide(window.direction.down,       bigstep) end)
:bind('alt', 'left',    function() window:slide(window.direction.left,       bigstep) end)
:bind('alt', 'right',   function() window:slide(window.direction.right,      bigstep) end)

modes.resizeTL
:bind('', 'up',         function() window:resizeOut(window.direction.up,    1) end)
:bind('', 'down',       function() window:resizeIn(window.direction.down,   1) end)
:bind('', 'left',       function() window:resizeOut(window.direction.left,  1) end)
:bind('', 'right',      function() window:resizeIn(window.direction.right,  1) end)

:bind('cmd', 'up',      function() window:resizeOut(window.direction.up,    true) end)
:bind('cmd', 'down',    function() window:resizeIn(window.direction.down,   true) end)
:bind('cmd', 'left',    function() window:resizeOut(window.direction.left,  true) end)
:bind('cmd', 'right',   function() window:resizeIn(window.direction.right,  true) end)

:bind('shift', 'up',    function() window:resizeOut(window.direction.up,    step) end)
:bind('shift', 'down',  function() window:resizeIn(window.direction.down,   step) end)
:bind('shift', 'left',  function() window:resizeOut(window.direction.left,  step) end)
:bind('shift', 'right', function() window:resizeIn(window.direction.right,  step) end)

:bind('alt', 'up',      function() window:resizeOut(window.direction.up,    bigstep) end)
:bind('alt', 'down',    function() window:resizeIn(window.direction.down,   bigstep) end)
:bind('alt', 'left',    function() window:resizeOut(window.direction.left,  bigstep) end)
:bind('alt', 'right',   function() window:resizeIn(window.direction.right,  bigstep) end)

modes.resizeBR
:bind('', 'up',         function() window:resizeIn(window.direction.up,     1) end)
:bind('', 'down',       function() window:resizeOut(window.direction.down,  1) end)
:bind('', 'left',       function() window:resizeIn(window.direction.left,   1) end)
:bind('', 'right',      function() window:resizeOut(window.direction.right, 1) end)

:bind('cmd', 'up',      function() window:resizeIn(window.direction.up,     true) end)
:bind('cmd', 'down',    function() window:resizeOut(window.direction.down,  true) end)
:bind('cmd', 'left',    function() window:resizeIn(window.direction.left,   true) end)
:bind('cmd', 'right',   function() window:resizeOut(window.direction.right, true) end)

:bind('shift', 'up',    function() window:resizeIn(window.direction.up,     step) end)
:bind('shift', 'down',  function() window:resizeOut(window.direction.down,  step) end)
:bind('shift', 'left',  function() window:resizeIn(window.direction.left,   step) end)
:bind('shift', 'right', function() window:resizeOut(window.direction.right, step) end)

:bind('alt', 'up',      function() window:resizeIn(window.direction.up,     bigstep) end)
:bind('alt', 'down',    function() window:resizeOut(window.direction.down,  bigstep) end)
:bind('alt', 'left',    function() window:resizeIn(window.direction.left,   bigstep) end)
:bind('alt', 'right',   function() window:resizeOut(window.direction.right, bigstep) end)

return window
