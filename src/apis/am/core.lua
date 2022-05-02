local v = require("cc.expect")

local boolMap = {
    ["true"] = true,
    ["yes"] = true,
    ["1"] = true,
    ["y"] = true,
    ["t"] = true,
    ["false"] = false,
    ["no"] = false,
    ["0"] = false,
    ["n"] = false,
    ["f"] = false,
}

---Parses string into boolean
---@param str string to parse
---@return boolean
local function strBool(str)
    v.expect(1, str, "string", "boolean")
    if type(str) == "boolean" then
        return str
    end

    local value = str:lower()
    value = boolMap[value]
    if value == nil then
        error(string.format("Unexpected string bool value: %s", str))
    end
    return value
end

---Splits a string
---@param str string to split
---@param sep Seperater
---@return table
local function split(str, sep)
    v.expect(1, str, "string")
    v.expect(2, sep, "string", "nil")

    if sep == nil then
        sep = ","
    end
    local t={}
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

---Merge a table into another
---@param dest Table to keep (values added and overwritten)
---@param src Table to pull values from
---@return table
local function merge(dest, src)
    for key, value in pairs(src) do
        dest[key] = value
    end
    return dest
end

---Concatenate two tables
---@param left Table to keep and output
---@param right Table to take values from
---@return table
local function concat(left, right)
    v.expect(1, left, "table")
    v.expect(2, right, "table")

    for _, v in ipairs(right) do
        table.insert(left, v)
    end
    return left
end

---Copy for lua tables
---@generic T
---@param orig table/value to copy
---@return T
local function copy(orig)
    local orig_type = type(orig)
    local new

    if orig_type == 'table' then
        new = {}
        for orig_key, orig_value in next, orig, nil do
            new[copy(orig_key)] = copy(orig_value)
        end
        setmetatable(new, copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        new = orig
    end

    return new
end

---Performs HTTP GET and checks reponse
---@param url URL to call
---@return table
local function getAndCheck(url)
    v.expect(1, url, "string")

    url = url .. "?ts=" .. os.time(os.date("!*t"))
    local r = http.get(url)
    if r == nil then
        error(string.format("Bad HTTP Response: %s", url))
    end
    local rc, _ = r.getResponseCode()
    if rc ~= 200 then
        error(string.format("Bad HTTP code: %d", rc))
    end
    return r
end

---Downloads a File to disk
---@param url URL to call
---@param path Path to write file to
local function download(url, path)
    v.expect(1, url, "string")
    v.expect(2, path, "string")

    if (fs.exists(path)) then
        fs.delete(path)
    end

    local r = getAndCheck(url)
    local f = fs.open(path, 'w')
    f.write(r.readAll())
    f.close()
end

---Gets JSON from URL
---@param url URL to call
---@return table
local function getJSON(url)
    v.expect(1, url, "string")

    local r = getAndCheck(url)
    return textutils.unserializeJSON(r.readAll())
end

---Normalizes arguments for Events
---
---Arguments should either be in the form of a single table:
---```
---cleanEventArgs({os.pullEvent()})
---```
---Or a list of arguments
---```
---cleanEventArgs(os.pullEvent())
---```
---Response will always be `eventName, args`. If there is only a single event argument,
---it will be returned as a single value
---
---Example:
---* a `terminate` event will return `"terminate"`
---* a `timer` event will return `"timer", id`
---* a `monitor_touch` event will return `"monitor_touch", {id, x, y}`
---@param url URL to call
---@return string, Any
local function cleanEventArgs(event, ...)
    local args = { ... }
    if type(event) == "table" then
        args = event
        event = args[1]
        table.remove(args, 1)
    end

    if #args == 1 then
        args = args[1]
    elseif #args == 0 then
        args = nil
    end

    return event, args
end

---Makes a setting wrapper to access settings
---
---Argument is a single table with settings defintitions. Setting
--- defintitons match `settings.define` options (https://tweaked.cc/module/settings.html#v:define)
--  but with one additional key: `name` which is the name parameter for
--- `settings.define`, `settings.get` or `settings.set`
---
---This will return back the table and automatically `settings.define` each of the settings.
--- The returned table will now have a new `.value` key that will act as a wrapper for `settings.get`
--- and `settings.set`. If you do `s.mySetting.value = s.mySetting.default` it will automatically create
--- a copy of that default value if it is mutable (table).
---
---As note: if you need to mutate the setting, you _must_ call `.value = newValue`, you cannot mutate
--- a table and expect it to update.
---```
---s.mySetting.value.key = "test" -- will not work
---value = s.mySetting.value
---value.key = "test"
---s.mySetting.value = value -- will work
---```
---Example:
---```
---{mySetting={name="test.mySetting", default=true, type="boolean", description="Setting description"}}
---```
---@param s Setting definition
---@return table
local function makeSettingWrapper(s)
    for key, setting in pairs(s) do
        setting.get = function()
            return settings.get(setting.name)
        end
        setting.set = function(value)
            if value == setting.default then
                value = copy(setting.default)
            end
            settings.set(setting.name, value)
            settings.save()
        end
        s[key] = setting
        settings.define(setting.name, setting)
    end
    return s
end

local core = {}
core.strBool = strBool
core.split = split
core.merge = merge
core.concat = concat
core.copy = copy
core.getAndCheck = getAndCheck
core.download = download
core.getJSON = getJSON
core.cleanEventArgs = cleanEventArgs
core.makeSettingWrapper = makeSettingWrapper
return core
