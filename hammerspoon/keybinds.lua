k = hs.hotkey.modal.new('cmd', 'escape')


-- Screen overlay
local f = screen:frame()
local r = hs.drawing.rectangle(hs.geometry(0, 0, f.w, f.h + 30))
r:setAlpha(0.5)
r:setFillColor(hs.drawing.color.black)
r:bringToFront()

function k:entered() hs.alert("Command mode!"); r:show() end
function k:exited() r:hide(); hs.alert("Bye bye") end


-- Bindings
k:bind('', 'escape', function() k:exit() end)
k:bind('', 'r', function() core.reload() end)
