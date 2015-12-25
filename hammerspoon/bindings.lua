--
commandMode = hs.hotkey.modal.new('cmd', 'escape')

-- Screen overlay
local f = hs.screen.primaryScreen():frame()
local r = hs.drawing.rectangle(hs.geometry(0, 0, f.w, f.h + 30))
r:setAlpha(0.5)
r:setFillColor(hs.drawing.color.black)
r:bringToFront()

--
function commandMode:entered() hs.alert("Command mode!"); r:show() end
function commandMode:exited() r:hide(); hs.alert("Bye bye") end

-- Command mode keybindings
hs.fnutils.each({
    { '',      'escape', util.call(commandMode, 'exit') },
    { '',      'r',      util.reload },
    { 'shift', 'r',      hs.openConsole },
}, function (item)
    commandMode:bind(item[1], item[2], item[3])
end)

-- Global keybindings
hs.fnutils.each({
    -- { {'cmd', 'ctrl'}, 'up',    function() print("UP") end },
    -- { {'cmd', 'ctrl'}, 'left',  function() print("LEFT") end },
    -- { {'cmd', 'ctrl'}, 'right', function() print("RIGHT") end },
}, function (item)
    hs.hotkey.bind(item[1], item[2], item[3])
end)

