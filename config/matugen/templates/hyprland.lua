
local bg = 0xff{{ colors.background.default.hex_stripped }}
local border = { colors = { 0x88{{ colors.outline.default.hex_stripped }}, 0xff{{ colors.background.default.hex_stripped }} }, angle = 45 }
local primary = 0xff{{ colors.primary.default.hex_stripped }}
local error = 0xff{{ colors.error.default.hex_stripped }}

hl.config({
    general = {
        col = {
            active_border = border,
            inactive_border = bg,
        },
    },
    group = {
        col = {
            border_active = border,
            border_inactive = bg,
            border_locked_active = error,
            border_locked_inactive = bg,
        },

        groupbar = {
            col = {
                active = primary,
                inactive = bg,
                locked_active = error,
                locked_inactive = bg,
            },
        },
    },
})
