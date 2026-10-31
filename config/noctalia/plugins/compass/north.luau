--!nonstrict
local edge = require("./edge.luau")("north", layer)

function update()
  noctalia.setUpdateInterval(60000)
  edge.render()
end

function onConfigChanged()
  edge.render()
end
