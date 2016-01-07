
local tmux_prefix = {{'ctrl'}, 'c'}

-- Helpers
local function isTmuxWindow()
  local win = hs.window.focusedWindow()
  if win then
    return win:title():find("tmux")
  end
  return false
end

local function tmuxPressKey(mod, key)
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

       -- new tmux window
       self.bind({'cmd'}, 'n', function()
         if not tmuxPressKey({}, 'c') then
           App.find("iTerm2"):selectMenuItem({"Shell", "New Window"})
         end
       end)

       -- new window
       self.bind({'cmd', 'shift'}, 'n', function()
         App.find("iTerm2"):selectMenuItem({"Shell", "New Window"})
       end)

       -- close pane/window
       self.bind({'cmd'}, 'w', function()
         if not tmuxPressKey({}, 'x') then
           App.find("iTerm2"):selectMenuItem({"Shell", "Close"})
         end
       end)

       -- detach tmux before quitting iterm
       self.bind({'cmd'}, 'q', function()
         if not tmuxPressKey({}, 'd') then
           App.find("iTerm2"):kill()
         end
       end)
     end)
   .bind({'cmd', 'shift'}, 'w', util.call(hs.window, 'close')) -- close pane/window
