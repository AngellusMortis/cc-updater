--[[
##name: ]]--
program_name = "am-cc Road/Tunnel Maker"
--[[
##file: am-cc/turtle/road.lua
##version: ]]--
program_version = "0.1.0.0"
--[[

##type: turtle
##desc: Mines out a tunnel

##images:

##detailed:


##planned:

##issues:

##parameters:
args[1]: length (default: 10)
args[2]: width (default: 2)
args[3]: height (default: 3)

--]]

local args = { ... }

local function main()
    local length = args[1] or 10
    local width = args[2] or 2
    local height = args[3] or 3

    for i=1,length do
        
    end
end