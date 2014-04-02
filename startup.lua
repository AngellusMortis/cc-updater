--[[
##name: ]]--
program_name = "am-cc Startup"
--[[
##file: am/turtle/place.lua
##version: ]]--
program_version = "0.3.0.0"
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

local new_path = shell.path()..":"..base_path.."am-cc/programs"

if (turtle == nil) then
    new_path = new_path..":"..base_path.."am-cc/programs/computer"
else
    new_path = new_path..":"..base_path.."am-cc/programs/turtle"
end

shell.setPath(new_path)