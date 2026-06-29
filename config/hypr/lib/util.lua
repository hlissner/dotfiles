-- config/hypr/lib/util.lua

my = {}
my.dsp = {}

function my.dsp.zoomIn(ratio)
    return function()
        local zoomvalue = hl.get_config("cursor:zoom_factor")
        if ratio == 0.0 then
            hl.config({ cursor = { zoom_factor = 1.0 } })
        elseif (zoomvalue + ratio) > 3.0 then
            hl.config({ cursor = { zoom_factor = 3.0 } })
        elseif (zoomvalue + ratio) < 1.0 then
            hl.config({ cursor = { zoom_factor = 1.0 } })
        else
            hl.config({ cursor = { zoom_factor = zoomvalue + ratio } })
        end
    end
end

-- Upstream warning: "It is NOT recommended to set DPMS or forceidle with a
-- keybind directly, as it might cause undefined behavior. Instead, consider
-- something like..."
function my.dsp.dpms(state)
    return function()
        hl.timer(function()
            hl.dispatch(hl.dsp.dpms({ action = state and "enable" or "disable" }))
        end, { timeout = 500, type = "oneshot"})
    end
end

function my.dsp.layout(bind_table)
    return function()
        local workspace = hl.get_active_special_workspace() or
                          hl.get_active_workspace()
        if not workspace then
            return
        end

        local layout = workspace.tiled_layout
        if bind_table[layout] then
            hl.dispatch(bind_table[layout])
        else
            hl.exec_cmd([[dsp ipc toast error "No keybind for ]] .. layout .. [[ layout"]])
        end
    end
end
