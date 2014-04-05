--[[
##name: ]]--
program_name = "am-cc Updater"
--[[
##file: am/programs/update.lua
##version: ]]--
program_version = "5.1.1.0"
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
local update_path = "f"

local old = shell.dir()
local base_path = "/"

if (fs.exists("/disk/am-cc")) then
    base_path = "/disk/"
end

shell.setDir(base_path)

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

local function get_update_data()
    local response = textutils.unserialize(http.get(update_url.."?random="..math.random(1, 1000000)).readAll())
    if not response["success"] then
        error("Update failed: "..response["error"])
    end
    return response["data"]
end

local function check_path_for_folders(path)
    local temp_path = ""
    for index,folder in ipairs(split(path, "/")) do
        if not (fs.exists(temp_path.."/"..folder)) then
            fs.makeDir(temp_path.."/"..folder)
        end
        temp_path = temp_path.."/"..folder
    end
end

local function get_version_info(path)
    handle = fs.open(path, "r")
    if (handle) then
        version_info = false
        line = handle.readLine()
        while (not version_info) and line do
            if not (string.gmatch(line, "##version") == nil) then
                temp_program_version = program_version
                loadstring(handle.readLine())
                temp_version = program_version
                program_version = temp_program_version
                temp_version = split(temp_version, "%.")
                version_info = {}
                version_info["major"] = tonumber(temp_version[1])
                version_info["minor"] = tonumber(temp_version[2])
                version_info["revision"] = tonumber(temp_version[3])
                version_info["build"] = tonumber(temp_version[4])
            end
        end

        handle.close()
        return version_info
    end
    error("Failed to get version info: "..path)
end

local function compare_version(version_1, version_2)
    if (version_1["major"] == version_2["major"]) then
        if (version_1["minor"] == version_2["minor"]) then
            if (version_1["revision"] == version_2["revision"]) then
                if (version_1["build"] == version_2["build"]) then
                    return 0
                elseif (version_1["build"] > version_2["build"]) then
                    return 1
                else
                    return -1
                end
            elseif (version_1["revision"] > version_2["revision"]) then
                return 1
            else
                return -1
            end
        elseif (version_1["minor"] > version_2["minor"]) then
            return 1
        else
            return -1
        end
    elseif (version_1["major"] > version_2["major"]) then
        return 1
    else
        return -1
    end
end

local function check_for_updates(data, path)
    check_path_for_folders(base_path..path)
    check_path = ""
    if not (base_path == "/") then
        check_path = base_path
    end
    if not (path == "/") then
        check_path = check_path..path
    end

    for index,value in pairs(data) do
        if not (tonumber(index) == nil) then
            print("Checking: "..check_path.."/"..value["file"])
            local do_update = true
            if ((path == "am-cc/programs/computer") and not (turtle == nil)) or ((path == "am-cc/programs/turtle") and (turtle == nil)) then
                do_update = false
            elseif (fs.exists(check_path.."/"..value["file"])) then
                file_version = get_version_info(check_path.."/"..value["file"])
                if not (compare_version(value["version"], file_version) == 1) then
                    do_update = false
                end
            end

            if (do_update) then
                print("Updating: "..check_path.."/"..value["file"])
                if (fs.exists(check_path.."/"..value["file"])) then
                    fs.move(check_path.."/"..value["file"], check_path.."/"..value["file"]..".bak")
                end
                handle = fs.open(check_path.."/"..value["file"], "w")
                if (handle) then
                    handle.write(http.get(update_url..update_path..check_path.."/"..value["file"]..".lua?random="..math.random(1, 1000000)).readAll())
                    handle.close()
                    fs.delete(check_path.."/"..value["file"]..".bak")
                else
                    fs.move(check_path.."/"..value["file"]..".bak", check_path.."/"..value["file"])
                    error("Failed to update: "..check_path.."/"..value["file"])
                end
            end
        else
            check_for_updates(value, index)
        end
    end
end

local function main()
    math.randomseed(os.time() * 1024 % 46)
    term.clear()
    term.setCursorPos(1,1)
    print("Getting file data...")
    local update_data = get_update_data()

    check_for_updates(update_data, base_path)
end

main()
shell.setDir(old)
