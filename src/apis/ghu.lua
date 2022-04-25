local ghu = {}
ghu.root = "/"
ghu.base = "/ghu/"
if fs.exists("/disk/ghu") then
    ghu.root = "/disk/"
    ghu.base = "/disk/ghu/"
end
ghu.s = {}

ghu.s.base = {name="ghu.base", default=ghu.base}
ghu.s.autoUpdate = {name="ghu.autoUpdate", default=true}
ghu.s.coreRepo = {name="ghu.coreRepo", default="AngellusMortis/cc-updater@v1:/src"}
ghu.s.extraRepos = {name="ghu.extraRepos", default={}}

ghu.autoUpdate = settings.get(ghu.s.autoUpdate.name, ghu.s.autoUpdate.default)
settings.set(ghu.s.autoUpdate.name, ghu.autoUpdate)
ghu.coreRepo = settings.get(ghu.s.coreRepo.name, ghu.s.coreRepo.default)
settings.set(ghu.s.coreRepo.name, ghu.coreRepo)
ghu.extraRepos = settings.get(ghu.s.extraRepos.name, ghu.s.extraRepos.default)
settings.set(ghu.s.extraRepos.name, ghu.extraRepos)

local basePath = settings.get(ghu.s.base.name, ghu.s.base.default)
if fs.exists(basePath) then
    ghu.base = basePath
end
if string.sub(basePath, 1, string.len(5))== "/disk" then
    ghu.root = "/disk/"
end

settings.set(ghu.s.base.name, ghu.base)

---------------------------------------
-- Parse Github Repo
---------------------------------------
ghu.parseRepo = function(repo)
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
    local modulePath = package.path
    modulePath = modulePath .. ";" .. ghu.base .. path .. "/apis/?"
    modulePath = modulePath .. ";" .. ghu.base .. path .. "/apis/?.lua"
    modulePath = modulePath .. ";" .. ghu.base .. path .. "/apis/?/init.lua"
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
    local shellPath = shell.path()
    local basePath = ":" .. ghu.base .. path .. "programs/"

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
    ghu.addModulePath("core")
    for i, repo in ipairs(ghu.extraRepos) do
        ghu.addModulePath(repo)
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
    local r = ghu.getAndCheck(url)
    return textutils.unserializeJSON(r.readAll())
end

return ghu
