--[[
##name: ]]--
program_name = "am-cc Startup"
--[[
##file: am/turtle/place.lua
##version: ]]--
program_version = "0.2.1.0"
--[[

##type: startup
##desc: Startup program

##detailed:

##planned:

##issues:

##parameters:

--]]

local base_path = "/"

if (fs.exists("/disk/am-cc")) then
    base_path = "/disk/"
end

shell.setPath(shell.path() .. ":"..base_path.."am-cc/programs:"..base_path.."am-cc/turtle")