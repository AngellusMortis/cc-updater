local args = { ... }
local self = {
    --[[
    ##name: ]]--
    name = "Updater",
    --[[
    ##file: am/programs/update.lua
    ##version: ]]--
    version = "5.2.1.0",
    --[[

    ##type: program
    ##desc: Checks for updates of the files currently on the file system for am-cc

    ##detailed:

    ##planned:

    ##issues:

    ##parameters:

    --]]

    -- hardcoded default settings
    settings_file = "",
    log_file = "",
    update_url = "https://tundrasofangmar.net/cc/",
    update_path = "f",

    has_core = true,
    checked = 0,
    updated = 0,
    failed = 0,
    base_x = args[1] or 1,
    base_y = args[2] or 3
}

if (core == nil) then
    self.has_core = false
end
if (self.has_core) then
    self.settings_file = core.settings_base.."/update"
    self.log_file = core.log_base.."/update"
end

--prototypes
self.get_update_data = nil
self.check_path_for_folders = nil
self.get_version_info = nil
self.compare_version = nil
self.check_for_updates = nil

self.get_update_data = function()
    local response = http.get(self.update_url.."?random="..math.random(1, 1000000))
    if (response.getResponseCode() == 200) or (response.getResponseCode() == 304) then
        response = response.readAll()
        if (self.has_core) then
            core.log(self, core.strings.levels.debug, response)
        end
        response = textutils.unserialize(response)
        if not response["success"] then
            error("Update failed: "..response["error"])
        end
        return response["data"]
    else
        return false
    end
end

self.check_path_for_folders = function(path)
    local temp_path = ""
    for index,folder in ipairs(core.split(path, "/")) do
        if not (fs.exists(temp_path.."/"..folder)) then
            fs.makeDir(temp_path.."/"..folder)
        end
        temp_path = temp_path.."/"..folder
    end
end

self.get_version_info = function(path)
    local handle = fs.open(path, "r")
    if (handle) then
        version_info = false
        local line = handle.readLine()
        while (not version_info) and line do
            if not (string.gmatch(line, "##version")() == nil) then
                temp_version = string.gmatch(handle.readLine(), "%d+%.%d+%.%d+%.%d+")()
                temp_version = core.split(temp_version, "%.")
                version_info = {}
                version_info["major"] = tonumber(temp_version[1])
                version_info["minor"] = tonumber(temp_version[2])
                version_info["revision"] = tonumber(temp_version[3])
                version_info["build"] = tonumber(temp_version[4])
            end
            line = handle.readLine()
        end

        handle.close()
        return version_info
    end
    error("Failed to get version info: "..path)
end

self.compare_version = function(version_1, version_2)
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

self.failed_to_update = function(file, malformed)
    malformed = malformed or false
    self.failed = self.failed + 1
    if not (self.has_core) then
        if (malformed) then
            print("Malformed version: "..file)
        else
            print("Failed to update: "..file)
        end
    else
        term.setCursorPos(self.base_x+9, self.base_y+2)
        core.text.color_write(string.format("%3d", self.failed), colors.yellow)

        core.log(self, core.strings.levels.error, "failed to update "..file.."("..tostring(malformed)..")")
    end
end

self.check_for_updates = function(data, path)
    local check_path = "/"
    if not (path == "/") then
        check_path = "/"..path..check_path
    end
    if not (core.base_path == "/") then
        check_path = core.base_path..check_path
    end

    for index,value in pairs(data) do
        if not (tonumber(index) == nil) then
            self.checked = self.checked + 1
            if (self.has_core) then
                term.setCursorPos(self.base_x+9, self.base_y)
                core.text.color_write(string.format("%3d", self.checked), colors.yellow)

                core.log(self, core.strings.levels.debug, "checking "..check_path..value["file"])
            end
            local do_update = true
            if ((path == "am-cc/programs/computer") and not (turtle == nil)) or ((path == "am-cc/programs/turtle") and (turtle == nil)) then
                do_update = false
            elseif (fs.exists(check_path..value["file"])) then
                file_version = self.get_version_info(check_path..value["file"])
                if (file_version == false) or (not (self.compare_version(value["version"], file_version) == 1)) then
                    if (file_version == false) then
                        if not (self.has_core) then
                            self.failed_to_update(check_path..value["file"], true)
                        end
                    end
                    do_update = false
                end
            end

            if (do_update) then
                self.check_path_for_folders(check_path)
                if not (self.has_core) then
                    term.write(check_path..value["file"].."...")
                else
                    core.log(self, core.strings.levels.debug, "updating "..check_path..value["file"])
                end
                if (fs.exists(check_path..value["file"])) then
                    fs.move(check_path..value["file"], check_path..value["file"]..".bak")
                end
                handle = fs.open(check_path..value["file"], "w")
                if (handle) then
                    local response = http.get(self.update_url..self.update_path..check_path..value["file"]..".lua?random="..math.random(1, 1000000))
                    if (response.getResponseCode() == 200) or (response.getResponseCode() == 304) then
                        handle.write(response.readAll())
                        handle.close()
                        fs.delete(check_path..value["file"]..".bak")
                        if not (self.has_core) then
                            print("done")
                        else
                            core.log(self, core.strings.levels.info, "updated "..check_path..value["file"])
                        end
                        self.updated = self.updated + 1
                        if (self.has_core) then
                            term.setCursorPos(self.base_x+9, self.base_y+1)
                            core.text.color_write(string.format("%3d", self.updated), colors.yellow)
                        end
                    else
                        fs.move(check_path..value["file"]..".bak", check_path..value["file"])
                        self.failed_to_update(check_path..value["file"])
                    end
                else
                    fs.move(check_path..value["file"]..".bak", check_path..value["file"])
                    self.failed_to_update(check_path..value["file"])
                end
            end
        else
            self.check_for_updates(value, index)
        end
    end
end

local main = function()
    math.randomseed(os.time() * 1024 % 46)
    local old = shell.dir()

    if not (self.has_core) then
        core = {}
        core.base_path = "/"

        if (fs.exists("/disk/am-cc")) then
            core.base_path = "/disk/"
        end

        shell.setDir(core.base_path)

        core.split = function(str, pat)
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

        term.clear()
        term.setCursorPos(1,1)
        print("am-cc Installer v"..self.version)
        term.write("Checking for files...")
    end

    local update_data = self.get_update_data()

    if (update_data == false) then
        error("Could not retrieve update data")
    else
        if not (self.has_core) then
            print("done")
            term.write("Downloading files:")
        else
            if (args[1] == nil) then
                term.clear()
                core.text.print_title(self)
            end
            term.setCursorPos(self.base_x, self.base_y)
            core.text.color_write("Checked: ", colors.cyan)
            core.text.color_write(string.format("%3d", self.checked), colors.yellow)
            term.setCursorPos(self.base_x, self.base_y+1)
            core.text.color_write("Updated: ", colors.green)
            core.text.color_write(string.format("%3d", self.updated), colors.yellow)
            term.setCursorPos(self.base_x, self.base_y+2)
            core.text.color_write("Failed:  ", colors.red)
            core.text.color_write(string.format("%3d", self.failed), colors.yellow)
        end

        self.check_for_updates(update_data, core.base_path)

        if not (self.has_core) then
            print(self.checked.." file(s) checked.")
            print(self.updated.." file(s) updated.")
            print(self.failed.." file(s) failed.")

            term.write("Install complete. Rebooting.")
            for i=1,5 do
                local temp = 1
                os.sleep(0.20)
                term.write(".")
            end
            print()

            if (fs.exists("install")) then
                fs.delete("install")
            else
                print("Failed to remove installer. Please delete after reboot.")
                os.sleep(3)
            end
            os.sleep(2)
            os.reboot()
        elseif (args[1] == nil) then
            term.setCursorPos(self.base_x, self.base_y+4)
        end
    end

    shell.setDir(old)
end

main()