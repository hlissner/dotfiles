--
commandMode = hs.hotkey.modal.new('cmd', 'escape')

-- Screen overlay
local f = hs.screen.primaryScreen():frame()
local overlay = hs.drawing.rectangle(hs.geometry(0, 0, f.w, f.h + 30))
overlay:setAlpha(0.5)
overlay:setFillColor(hs.drawing.color.black)
overlay:bringToFront()

--
function commandMode:entered() overlay:show() end
function commandMode:exited()  overlay:hide() end

-- Command mode keybindings
hs.fnutils.each({
  { '',      'escape', util.call(commandMode, 'exit') },
  { '',      'r',      util.reload },
  { 'shift', 'r',      function() hs.openConsole(); commandMode:exit() end },
}, function (item)
  commandMode:bind(item[1], item[2], item[3])
end)

-- Global keybindings
hs.fnutils.each({
  -- { {'cmd', 'ctrl'}, 'up',    function() print("UP"); modes.position:enter() end },
  -- { {'cmd', 'ctrl'}, 'left',  function() print("LEFT"); resizeBRMode:enter() end },
  -- { {'cmd', 'ctrl'}, 'right', function() print("RIGHT"); resizeTLMode:enter() end },
}, function (item)
  hs.hotkey.bind(item[1], item[2], item[3])
end)

