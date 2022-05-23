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
---@param str string|boolean to parse
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
---@param str string Value to split
---@param sep? string Seperater defaults to `,`
---@return table
local function split(str, sep)
    v.expect(1, str, "string")
    v.expect(2, sep, "string", "nil")

    if sep == nil then
        sep = ","
    end
    local t={}
    for part in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, part)
    end
    return t
end

---Merge a table into another
---@param dest table Table to keep (values added and overwritten)
---@param src table Table to pull values from
---@return table
local function merge(dest, src)
    for key, value in pairs(src) do
        dest[key] = value
    end
    return dest
end

---Concatenate two tables
---@param left table Table to keep and output
---@param right table Table to take values from
---@return table
local function concat(left, right)
    v.expect(1, left, "table")
    v.expect(2, right, "table")

    for _, value in ipairs(right) do
        table.insert(left, value)
    end
    return left
end

---Copy for lua tables
---@generic T
---@param orig T table/value to copy
---@param meta? boolean
---@return T
local function copy(orig, meta)
    if meta == nil then
        meta = true
    end
    local orig_type = type(orig)
    local new

    if orig_type == 'table' then
        new = {}
        for orig_key, orig_value in next, orig, nil do
            new[copy(orig_key)] = copy(orig_value, meta)
        end
        if meta then
            setmetatable(new, copy(getmetatable(orig)))
        end
    else -- number, string, boolean, etc
        new = orig
    end

    return new
end

---Performs HTTP GET and checks reponse
---@param url string URL to call
---@return table Response
local function getAndCheck(url)
    v.expect(1, url, "string")

    url = url .. "?ts=" .. os.time(os.date("!*t"))
    local r = http.get(url)
    if r == nil then
        error(string.format("Bad HTTP Response: %s", url))
        return
    end
    local rc, _ = r.getResponseCode()
    if rc ~= 200 then
        error(string.format("Bad HTTP code: %d", rc))
    end
    return r
end

---Downloads a File to disk
---@param url string URL to call
---@param path string Path to write file to
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
---@param url string URL to call
---@return table JSON Response
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
---* a `terminate` event will return `"terminate", {}`
---* a `timer` event will return `"timer", {id}`
---* a `monitor_touch` event will return `"monitor_touch", {id, x, y}`
---@param event string Event name
---@param ...? any
---@return string, table Event and args table
local function cleanEventArgs(event, ...)
    local args = { ... }
    if type(event) == "table" then
        args = event
        event = args[1]
        table.remove(args, 1)
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
---@param s table Setting definition
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
            if value == nil then
                settings.unset(setting.name)
            else
                settings.set(setting.name, value)
            end
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
