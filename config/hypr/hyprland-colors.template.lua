local primary = "rgb({{colors.primary.default.hex_stripped}})"
local surface = "rgb({{colors.surface.default.hex_stripped}})"
local on_surface = "rgb({{colors.on_surface.default.hex_stripped}})"
local secondary = "rgb({{colors.secondary.default.hex_stripped}})"
local on_secondary = "rgb({{colors.on_secondary.default.hex_stripped}})"
local error = "rgb({{colors.error.default.hex_stripped}})"
local on_error = "rgb({{colors.on_error.default.hex_stripped}})"
local border = {
  colors = {
    0xff{{ colors.background.default.hex_stripped }},
    0x99{{ colors.primary.default.hex_stripped }}
  },
  angle = 45
}

local function apply_theme()
  hl.config({
    general = {
      col = {
        active_border = border,
        inactive_border = surface,
      },
    },
    decoration = {
      rounding = 2,
    },
    group = {
      col = {
        border_active = border,
        border_inactive = surface,
        border_locked_active = error,
        border_locked_inactive = surface,
      },
      groupbar = {
        col = {
          active = secondary,
          inactive = surface,
          locked_active = error,
          locked_inactive = surface,
        },
        text_color = on_secondary,
        text_color_inactive = on_surface,
        text_color_locked_active = on_error,
        text_color_locked_inactive = on_surface,
      },
    },
  })

  if hl.plugin.scrolloverview then
    hl.config({
      plugin = {
        scrolloverview = {
          shadow = {
            color = {
              colors = {
                0x44{{ colors.primary.default.hex_stripped }},
                0x99{{ colors.background.default.hex_stripped }}
              },
              angle = 315
            }
          }
        }
      }
    })
  end
end

return {
  colors = {
    primary = primary,
    surface = surface,
    on_surface = on_surface,
    secondary = secondary,
    on_secondary = on_secondary,
    error = error,
    on_error = on_error,
    border = border,
  },
  apply = apply_theme
}
