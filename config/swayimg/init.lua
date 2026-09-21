-- config/swayimg/init.lua

swayimg.mode = "viewer"
swayimg.antialiasing = true
swayimg.decoration = false
swayimg.overlay = false
swayimg.exif_orientation = true
swayimg.text.visible = false

local next_keys = { "n", "j", "Tab" }
local prev_keys = { "p", "k", "Shift+ISO_Left_Tab" }

for _, mode in ipairs({ swayimg.viewer, swayimg.gallery, swayimg.slideshow }) do
  mode.on_key("q", function() swayimg.exit() end)
end

for _, mode in ipairs({ swayimg.viewer, swayimg.slideshow }) do
  mode.on_key(next_keys, function() mode.open("next") end)
  mode.on_key(prev_keys, function() mode.open("prev") end)
end
swayimg.gallery.on_key(next_keys, function() swayimg.gallery.select("right") end)
swayimg.gallery.on_key(prev_keys, function() swayimg.gallery.select("left") end)

swayimg.viewer.on_key("i", function()  -- also on `t`
  swayimg.text.visible = not swayimg.text.visible
end)
