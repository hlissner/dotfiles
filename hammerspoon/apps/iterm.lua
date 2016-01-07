
local tmux_prefix = {{'ctrl'}, 'c'}

local function isTmuxWindow()
  return function ()
    hs.window.focusedWindow():title():find("tmux")
  end
end

local function tmuxpresskey(mod, key)
  if isTmuxWindow() then
    hs.eventtap.keyStroke({'ctrl'}, 'c')
    hs.eventtap.keyStroke(mod, key)
    return true
  end
  return false
end

-- App settings
local iterm2
App.new("iTerm2")
   .onLaunched(function (self, app)
       -- cmd+N for switching tmux windows
       for i = 1,9 do
         i = tostring(i)
         self.bind({'cmd'}, i, function()
             if isTmuxWindow() then
               os.execute("/usr/local/bin/tmux select-window -t " .. i)
             end
         end)
       end

       -- new window
       self.bind({'cmd'}, 'n', function()
         if not tmuxpresskey({}, 'c') then
           app:selectMenuItem({"Shell", "New Window"})
         end
       end)

       -- close pane/window
       self.bind({'cmd'}, 'w', function()
         if not tmuxpresskey({}, 'x') then
           app:selectMenuItem({"Shell", "Close"})
         end
       end)
     end)
   .bind({'cmd', 'shift'}, 'w', util.call(hs.window, 'close')) -- close pane/window
