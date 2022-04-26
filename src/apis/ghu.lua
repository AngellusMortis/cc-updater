local expect = require("cc.expect").expect
local ghu = {}
ghu.root = "/"
ghu.base = "/ghu/"
if fs.exists("/disk/ghu") then
    ghu.root = "/disk/"
    ghu.base = "/disk/ghu/"
end

ghu.s = {}
ghu.s.base = {
    name = "ghu.base",
    default = ghu.base,
    type = "string",
    description = "The base path for cc-updater. Recommendeded not to change."
}
ghu.s.autoUpdate = {
    name="ghu.autoUpdate",
    default = true,
    type = "boolean",
    description = "Auto-update cc-updater repos on computer boot."
}
ghu.s.autoRun = {
    name="ghu.autoRun",
    default = true,
    type = "boolean",
    description = "Allow extra repos to provide auto-run programs."
}
ghu.s.coreRepo = {
    name = "ghu.coreRepo",
    default = "AngellusMortis/cc-updater@v1:/src",
    type = "string",
    description = "Core repo for cc-updater. Recommended not to change."
}
ghu.s.extraRepos = {
    name = "ghu.extraRepos",
    default = {},
    type = "table",
    description = "List of extra cc-updater repos."
}

settings.define(ghu.s.base.name, ghu.s.base)
settings.define(ghu.s.autoUpdate.name, ghu.s.autoUpdate)
settings.define(ghu.s.autoRun.name, ghu.s.autoRun)
settings.define(ghu.s.coreRepo.name, ghu.s.coreRepo)
settings.define(ghu.s.extraRepos.name, ghu.s.extraRepos)

ghu.autoUpdate = settings.get(ghu.s.autoUpdate.name)
ghu.autoRun = settings.get(ghu.s.autoRun.name)
ghu.coreRepo = settings.get(ghu.s.coreRepo.name)
ghu.extraRepos = settings.get(ghu.s.extraRepos.name)

if fs.exists(settings.get(ghu.s.base.name)) then
    ghu.base = settings.get(ghu.s.base.name)
end
if string.sub(settings.get(ghu.s.base.name), 1, string.len(5))== "/disk" then
    ghu.root = "/disk/"
end

settings.set(ghu.s.base.name, ghu.base)

---------------------------------------
-- Parse Github Repo
---------------------------------------
ghu.parseRepo = function(repo)
    expect(1, repo, "string")
    local parts = ghu.split(repo, ":")

    local base = "/"
    if #parts == 1 then
        base = "/"
    elseif #parts > 2 then
        error("Bad repo: " .. repo)
    else
        repo = parts[1]
        base = parts[2] .. "/"
    end

    parts = ghu.split(repo, "@")
    if #parts == 1 then
        ref = "master"
    elseif #parts > 2 then
        error("Bad repo: " .. repo)
    else
        repo = parts[1]
        ref = parts[2]
    end

    return repo, ref, base
end

---------------------------------------
-- Add Module path
--
-- Helper function to add a search path to package.path to loading APIs
-- Everything is automatically prefix with /ghu/
--
-- path should be normally be Github {repoOwner}/{repoName}
-- General structure is /ghu/{repoOwner}/{repoName}/apis/
---------------------------------------
ghu.addModulePath = function(path)
    expect(1, path, "string")
    local modulePath = package.path
    local basePath = ";" .. ghu.base .. path
    modulePath = modulePath .. basePath .. "apis/?"
    modulePath = modulePath .. basePath .. "apis/?.lua"
    modulePath = modulePath .. basePath .. "apis/?/init.lua"
    package.path = modulePath
end

---------------------------------------
-- Add Shell path
--
-- Helper function to add a search path to shell.path for programs
-- Everything is automatically prefixed with /ghu/
--
-- path should be normally be Github {repoOwner}/{repoName}
-- General structure is
--
-- Follows the same structure as the base CC paths but prefixed with
-- /ghu/{repoOwner}/{repoName}/
---------------------------------------
ghu.addShellPath = function(path)
    expect(1, path, "string")
    local shellPath = shell.path()
    local basePath = ":" .. ghu.base .. path
    help.setPath(help.path() .. basePath .. "help")
    basePath = basePath  .. "programs/"

    shellPath = shellPath .. basePath
    if term.isColor() then
        shellPath = shellPath .. basePath .. "advanced"
    end
    if turtle then
        shellPath = shellPath .. basePath .. "turtle"
    else
        shellPath = shellPath .. basePath .. "rednet"
        shellPath = shellPath .. basePath .. "fun"
        if term.isColor() then
            shellPath = shellPath .. basePath .. "fun/advanced"
        end
    end
    if pocket then
        shellPath = shellPath .. basePath .. "pocket"
    end
    if commands then
        shellPath = shellPath .. basePath .. "command"
    end
    if http then
        shellPath = shellPath .. basePath .. "http"
    end
    shell.setPath(shellPath)
end

---------------------------------------
-- Initializes default module paths
---------------------------------------
ghu.initModulePaths = function()
    ghu.addModulePath("core/")
    for i, repoString in ipairs(ghu.extraRepos) do
        local repo, _, path = ghu.parseRepo(repoString)
        ghu.addModulePath(repo .. path)
    end
end

---------------------------------------
-- Initializes default shell paths
---------------------------------------
ghu.initShellPaths = function()
    ghu.addShellPath("core/")
    for i, repoString in ipairs(ghu.extraRepos) do
        local repo, _, path = ghu.parseRepo(repoString)
        ghu.addShellPath(repo .. path)
    end
end

---------------------------------------
-- Splits a string
---------------------------------------
ghu.split = function(str, sep)
    expect(1, str, "string")
    expect(2, sep, "string")

    if sep == nil then
        sep = ","
    end
    local t={}
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

---------------------------------------
-- Performs HTTP GET and checks reponse
---------------------------------------
ghu.getAndCheck = function(url)
    expect(1, url, "string")

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

---------------------------------------
-- Download File
---------------------------------------
ghu.download = function(url, path)
    expect(1, url, "string")
    expect(2, path, "string")

    if (fs.exists(path)) then
        fs.delete(path)
    end

    local r = ghu.getAndCheck(url)
    local f = fs.open(path, 'w')
    f.write(r.readAll())
    f.close()
end

---------------------------------------
-- Gets JSON from URL
---------------------------------------
ghu.getJSON = function(url)
    expect(1, url, "string")

    local r = ghu.getAndCheck(url)
    return textutils.unserializeJSON(r.readAll())
end


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

---------------------------------------
-- Parses string into boolean
---------------------------------------
ghu.strBool = function(orig)
    if type(orig) == "boolean" then
        return orig
    end
    expect(1, orig, "string")

    local value = orig:lower()
    value = boolMap[value]
    if value == nil then
        error(string.format("Unexpected string bool value: %s", orig))
    end
    return value
end

---------------------------------------
-- Concatenate tables
---------------------------------------
ghu.tableConcat = function(src, new)
    expect(1, src, "table")
    expect(2, new, "table")

    for _, v in ipairs(new) do
        table.insert(src, v)
    end
    return src
end

---------------------------------------
-- Copy for lua tables
---------------------------------------
ghu.copy = function(orig)
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[ghu.copy(orig_key)] = ghu.copy(orig_value)
        end
        setmetatable(copy, ghu.copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end

    return copy
end

---------------------------------------
-- Gets autorun programs
--
-- Returns list of {ghu.extraRepos}/autorun/*.lua files
---------------------------------------
ghu.getAutoruns = function()
    local autoruns = {}
    for i, repoString in ipairs(ghu.extraRepos) do
        local repo, _, path = ghu.parseRepo(repoString)
        local repoPath = ghu.base .. repo .. path .. "autorun/"
        autoruns = ghu.tableConcat(autoruns, fs.find(repoPath .. "*.lua"))
    end
    return autoruns
end

return ghu
