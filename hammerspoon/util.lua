
return {
    apps = {},
    bindings = {},

    ls = function(directory)
        local i, t, popen = 0, {}, io.popen
        for filename in popen('ls -a "'..directory..'"'):lines() do
            i = i + 1
            t[i] = filename
        end
        return t
    end,

    reload = function()
        hs.reload()
        hs.alert("Config reloaded!")
    end,

    call = function(obj, fn)
        return function () return obj[fn](obj) end
    end,

    autoimport = function(dir)
        for _, file in pairs(util.ls(dir)) do
            if file:find(".+%.lua") then
                local a = string.gsub(file, '%.lua', '')
                print(a .. " loaded")
                require(dir .. "/" .. a)
            end
        end
    end
}

