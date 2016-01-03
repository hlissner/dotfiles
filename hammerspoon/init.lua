-- Core
util = require('util')

-- Settings
hs.window.animationDuration = 0.1
hs.urlevent.bind("reload", util.reload)

-- Modules
-- require('urls')
-- require('locations')


--
require('modules/apps')
-- require('modules/windows')

util.autoimport("./apps")
require('bindings')

