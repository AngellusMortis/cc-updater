local basePath = settings.get("ghu.base")
local ghu = require(basePath .. "core/apis/ghu")
shell.setPath("")
shell.run("/rom/startup.lua")
