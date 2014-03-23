--[[
##name: ]]--
program_name = "am-cc Updater"
--[[
##file: am/turtle/branch.lua
##version: ]]--
program_version = "5.0.0"
--[[

##type: program
##desc: Checks for updates of the files currently on the file system for am-cc

##detailed:

##planned:

##issues:

##parameters:

--]]

local args = { ... }

local update_url = "https://tundrasofangmar.net/cc/"
local update_self = false

local old = shell.dir()
local path = "/"

if (fs.exists("/disk/am-cc")) then
    path = "/disk/"
end

shell.setDir(path)

