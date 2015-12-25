
local tmux_prefix = {{'ctrl'}, 'c'}

local function isTmuxWindow()
    return function ()
        hs.window.focusedWindow():title():find("tmux")
    end
end

App.new("iTerm2")
    .onInit(function (self)
        -- cmd+N for switching tmux windows
        for i = 1,9 do
            i = tostring(i)
            self.bind({'cmd'}, i, function()
                os.execute("/usr/local/bin/tmux select-window -t " .. i)
            end, isTmuxWindow)
        end
    end)
    .bind({'cmd'}, 'n', invoke({tmux_prefix, 'c'}), isTmuxWindow) -- new window
    .bind({'cmd'}, 'w', invoke({tmux_prefix, 'x'}), isTmuxWindow) -- close pane/window
    .bind({'cmd', 'shift'}, 'w', util.call(hs.window, 'close')) -- close pane/window
