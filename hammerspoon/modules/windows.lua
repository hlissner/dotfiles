-- TODO: Window management library

local window = {
    direction = {
        up = 1,
        down = 2,
        left = 4,
        right = 8
    },

    move = function (x, y, w, h)
    end,

    slide = function (direction, amount)
    end,

    resizeIn = function (direction, amount)
    end,

    resizeOut = function (direction, amount)
    end,
}

--
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

    modal.entered = function(self)
        for k, m in pairs(modes) do
            if k ~= key then m:exit() end
        end
        currentMode = key
        overlay:show()
    end
    modal.exited = function(self)
        if currentMode == key then
            currentMode = nil
            overlay:hide()
        end
    end
end

local step = 10
local bigstep = 100

modes.position
    :bind('cmd', 'up',      function() window.slide(window.direction.up,         true) end)
    :bind('cmd', 'down',    function() window.slide(window.direction.down,       true) end)
    :bind('cmd', 'left',    function() window.slide(window.direction.left,       true) end)
    :bind('cmd', 'right',   function() window.slide(window.direction.right,      true) end)

    :bind('shift', 'up',    function() window.slide(window.direction.up,         step) end)
    :bind('shift', 'down',  function() window.slide(window.direction.down,       step) end)
    :bind('shift', 'left',  function() window.slide(window.direction.left,       step) end)
    :bind('shift', 'right', function() window.slide(window.direction.right,      step) end)

    :bind('alt', 'up',      function() window.slide(window.direction.up,         bigstep) end)
    :bind('alt', 'down',    function() window.slide(window.direction.down,       bigstep) end)
    :bind('alt', 'left',    function() window.slide(window.direction.left,       bigstep) end)
    :bind('alt', 'right',   function() window.slide(window.direction.right,      bigstep) end)

modes.resizeTL
    :bind('cmd', 'up',      function() window.resizeOut(window.direction.up,    true) end)
    :bind('cmd', 'down',    function() window.resizeIn(window.direction.down,   true) end)
    :bind('cmd', 'left',    function() window.resizeOut(window.direction.left,  true) end)
    :bind('cmd', 'right',   function() window.resizeIn(window.direction.right,  true) end)

    :bind('shift', 'up',    function() window.resizeOut(window.direction.up,    step) end)
    :bind('shift', 'down',  function() window.resizeIn(window.direction.down,   step) end)
    :bind('shift', 'left',  function() window.resizeOut(window.direction.left,  step) end)
    :bind('shift', 'right', function() window.resizeIn(window.direction.right,  step) end)

    :bind('alt', 'up',      function() window.resizeOut(window.direction.up,    bigstep) end)
    :bind('alt', 'down',    function() window.resizeIn(window.direction.down,   bigstep) end)
    :bind('alt', 'left',    function() window.resizeOut(window.direction.left,  bigstep) end)
    :bind('alt', 'right',   function() window.resizeIn(window.direction.right,  bigstep) end)

modes.resizeBR
    :bind('cmd', 'up',      function() window.resizeIn(window.direction.up,     true) end)
    :bind('cmd', 'down',    function() window.resizeOut(window.direction.down,  true) end)
    :bind('cmd', 'left',    function() window.resizeIn(window.direction.left,   true) end)
    :bind('cmd', 'right',   function() window.resizeOut(window.direction.right, true) end)

    :bind('shift', 'up',    function() window.resizeIn(window.direction.up,     step) end)
    :bind('shift', 'down',  function() window.resizeOut(window.direction.down,  step) end)
    :bind('shift', 'left',  function() window.resizeIn(window.direction.left,   step) end)
    :bind('shift', 'right', function() window.resizeOut(window.direction.right, step) end)

    :bind('alt', 'up',      function() window.resizeIn(window.direction.up,     bigstep) end)
    :bind('alt', 'down',    function() window.resizeOut(window.direction.down,  bigstep) end)
    :bind('alt', 'left',    function() window.resizeIn(window.direction.left,   bigstep) end)
    :bind('alt', 'right',   function() window.resizeOut(window.direction.right, bigstep) end)

