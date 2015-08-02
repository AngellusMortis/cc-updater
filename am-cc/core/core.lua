--[[
##name: ]]--
name = "am-cc"
--[[
##file: 
am-cc/core/core.lua
##version: ]]--
version = "1.0.0.0"
--[[

##type: 
core
##desc: 
common library

##detailed:
Library of common code for other programs to use. This library should be loaded
by startup.lua

##images:
None

##planned:
None

##issues:
None

##parameters:
None

##usage:
lua: os.loadAPI("am-cc/core/core")

--]]

-- common hardcoded default settings for other programs to use
base_path = "/"
if (fs.exists("/disk/am-cc")) then
    base_path = "/disk/"
end
settings_base = ".settings"
log_base = ".log"

-- hardcoded default settings
settings_file = settings_base.."/am-cc"
log_file = log_base.."/am-cc"

default_settings = {
    log_level = 3,
    update_on_boot = true
}

strings = {
    info = {
        enter = "Press ENTER to continue..."
    },
    errors = {
        clear = "__clear",
        file = " file could not be opened",
        width = "Display is not wide enough",
        height = "Display is not tall enough"
    },
    levels = {
        debug = "DEBUG", -- log level 0
        info = "INFO", -- log level 1
        warn = "WARN", -- log level 2
        error = "ERROR" -- log level 3
    }
}

text = {}

--prototypes
split = nil
check_path_for_folders = nil
setting_or_default = nil
init_settings = nil
write_settings = nil
read_settings = nil
get_log_level = nil
log = nil

text.clear_line = nil
text.color_write = nil
text.wait_for_enter = nil
text.print_error = nil
text.print_title = nil

-- Perl/Python like split (from: http://lua-users.org/wiki/SplitJoin)
split = function(str, pat)
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
-- checks for folders in path and creates them if needed
--  assumes all items are folders
check_path_for_folders = function(path)
    local temp_path = ""
    for index,folder in ipairs(core.split(path, "/")) do
        if not (fs.exists(temp_path.."/"..folder)) then
            fs.makeDir(temp_path.."/"..folder)
        end
        temp_path = temp_path.."/"..folder
    end
end

-- returns program's setting_value, if not set, returns default
-- need this function for bools
setting_or_default = function(program, setting_value, default)
    if (program.settings[setting_value] == nil) then
        return default
    end
    return program.settings[setting_value]
end

-- init settings variable for program
init_settings = function(program)
    core.read_settings(program)

    program.settings = program.settings or {}

    for index,value in pairs(program.default_settings) do
        program.settings[index] = core.setting_or_default(program, index, value)
    end

    core.write_settings(program)
end

-- writes current progress to progress file for program
write_settings = function(program)
    core.check_path_for_folders(core.base_path..core.settings_base)

    local temp_seralized = textutils.serialize(program.settings)
    local handle = fs.open(core.base_path..program.settings_file, "w")

    if (handle == nil) then
        core.text.print_error(program, core.strings.levels.error, "settings"..core.strings.errors.file, true)
    else
        handle.write(temp_seralized)
        handle.close()
    end
    temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
    core.log(program, core.strings.levels.info, "write: settings: "..temp_seralized)
end
-- reads progress from progress file for program
read_settings = function(program)
    local handle = fs.open(core.base_path..program.settings_file, "r")

    if not (handle == nil) then
        temp_seralized = handle.readAll()
        if (string.len(temp_seralized) > 5) then
            program.settings = textutils.unserialize(temp_seralized)
            temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
            core.log(program, core.strings.levels.info, "read: settings: "..temp_seralized)
            handle.close()
        end
    end
end
-- converts level string to int
get_log_level = function(level)
    -- assume debug if not match
    if (level == core.strings.levels.info) then
        return 1
    elseif (level == core.strings.levels.warn) then
        return 2
    elseif (level == core.strings.levels.error) then
        return 3
    end
    return 0
end
-- logs message for program with given log level and message
log = function(program, level, message)
    core.check_path_for_folders(core.base_path..core.log_base)
    if (core.get_log_level(level) >= core.settings["log_level"]) then
        local handle = nil
        if (fs.exists(core.base_path..program.log_file)) then
            handle = fs.open(core.base_path..program.log_file, "a")
        else
            handle = fs.open(core.base_path..program.log_file, "w")
        end
        if (handle == nil) then
            core.settings["debug"] = false
            core.settings["log"] = false
            core.text.print_error(program, core.strings.levels.error, "log"..core.strings.errors.file, false, false)
        else
            handle.writeLine("["..tostring(os.time()).."]: "..tostring(message))
            handle.close()
        end
    end
end

-- Force clears the current terminal line and then
--  sets it to first positions (was having trouble with term.clearLine())
text.clear_line = function()
    pos = {term.getCursorPos()}
    term_size = {term.getSize()}
    term.setCursorPos(1, pos[2])
    term.write(string.rep(" ",term_size[1]))
    term.setCursorPos(1, pos[2])
end
-- writes text in color, if display supports color
text.color_write = function(text, color)
    if (term.isColor()) then
        term.setTextColor(color)
    end
    term.write(text)
    if (term.isColor()) then
        term.setTextColor(colors.white)
    end
end
text.wait_for_enter = function()
    term_size = {term.getSize()}
    term.setCursorPos(1, (term_size[2]-1))
    core.text.clear_line()
    print(core.strings.info.enter)
    repeat
        event, param1 = os.pullEvent("key")
    until param1 == 28
    term.setCursorPos(1, (term_size[2]-1))
    core.text.clear_line()
end
-- prints error on second to last line for program with given level and error_message
-- fatal and wait are optional
text.print_error = function(program, level, error_message, fatal, wait)
    fatal = fatal or false
    if (level == core.strings.levels.error) then
        wait = true
    else
        wait = false
    end
    core.log(program, level, error_message)

    -- if fatal, terminate
    if (fatal) then
        error(error_message)
    else
        term_size = {term.getSize()}
        term.setCursorPos(1, (term_size[2]-2))
        core.text.clear_line()
        core.text.color_write(level..": "..error_message, colors.red)
        if (wait) then
            core.text.wait_for_enter()
            term.setCursorPos(1, (term_size[2]-2))
            core.text.clear_line()
        end
    end
end

text.print_title = function(program)
    local version = core.split(program.version, "%.")
    term.setCursorPos(1, 1)
    core.text.clear_line()
    if (core.name == program.name) then
        core.text.color_write(core.name.." v"..version[1].."."..version[2], colors.lime)
    else
        core.text.color_write(core.name.." "..program.name.." v"..version[1].."."..version[2], colors.lime)
    end
    print()
end

-- core. does not work until after loaded...
local local_setting_or_default = function(setting_value, default)
    if (settings[setting_value] == nil) then
        return default
    end
    return settings[setting_value]
end

local handle = fs.open(base_path..settings_file, "r")
if not (handle == nil) then
    temp_seralized = handle.readAll()
    if (string.len(temp_seralized) > 5) then
        settings = textutils.unserialize(temp_seralized)
        temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
        handle.close()
    end
end
settings = settings or {}

for index,value in pairs(default_settings) do
    settings[index] = local_setting_or_default(index, value)
end
if not (fs.exists(base_path..settings_base)) then
    fs.makeDir(base_path..settings_base)
end

local temp_seralized = textutils.serialize(settings)
local handle = fs.open(base_path..settings_file, "w")

if (handle == nil) then
    error(strings.errors.file)
else
    handle.write(temp_seralized)
    handle.close()
end