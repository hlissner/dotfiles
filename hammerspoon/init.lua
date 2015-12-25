-- Core
util = require('util')

-- Settings
hs.window.animationDuration = 0

-- Modules
-- require('apps')
-- require('urls')
-- require('locations')

util.autoimport("./apps")

--
require('bindings')
