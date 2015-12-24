
forApp("Finder", function (appName, eventType, appObject)
    -- Bring all Finder windows forward when one gets activated
    appObject:selectMenuItem({"Window", "Bring All to Front"})
end)

forApp("iTerm2", function (appName, _, appObject)
    -- cmd+N switch-to-window shortcuts in Tmux
    for i = 1,9 do
        i = tostring(i)
        bind(appName, 'cmd', i, function ()
            if string.find(appObject:focusedWindow():title(), ".*tmux") then
                -- os.execute("/usr/local/bin/tmux select-window -t " .. i)
                hs.eventtap.keyStroke({'ctrl'}, 'c')
                hs.eventtap.keyStroke({}, i)
            end
        end)
    end
end)
