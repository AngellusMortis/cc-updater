local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")
shell.setPath("")
shell.run("/rom/startup.lua")
shell.run(ghu.p.core .. "init.lua")
