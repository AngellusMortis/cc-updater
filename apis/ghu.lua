local basePath = "/ghu/"
local ghu = {}
ghu.s = {}

ghu.s.autoUpdate = {name="ghu.autoUpdate", default=true}
ghu.s.coreRepo = {name="ghu.coreRepo", default="AngellusMortis/cc-github-updater"}
ghu.s.extraRepos = {name="ghu.extraRepos", default={}}

local autoUpdate = settings.get(ghu.s.autoUpdate.name, ghu.s.autoUpdate.default)
settings.set(ghu.s.autoUpdate.name, autoUpdate)
local coreRepo = settings.get(ghu.s.coreRepo.name, ghu.s.coreRepo.default)
settings.set(ghu.s.coreRepo.name, coreRepo)
local extraRepos = settings.get(ghu.s.extraRepos.name, ghu.s.extraRepos.default)
settings.set(ghu.s.extraRepos.name, extraRepos)

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
    modulePath = modulePath .. ";" .. basePath .. path .. "/apis/?"
    modulePath = modulePath .. ";" .. basePath .. path .. "/apis/?.lua"
    modulePath = modulePath .. ";" .. basePath .. path .. "/apis/?/init.lua"
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
    shellPath = shellPath .. ":" .. basePath .. path .. "/programs"
    if term.isColor() then
        shellPath = shellPath .. ":" .. basePath .. path .. "/programs/advanced"
    end
    if turtle then
        shellPath = shellPath .. ":" .. basePath .. path .. "/programs/turtle"
    else
        shellPath = shellPath .. ":" .. basePath .. path .. "/programs/rednet"
        shellPath = shellPath .. ":" .. basePath .. path .. "/programs/fun"
        if term.isColor() then
            shellPath = shellPath .. ":" .. basePath .. path .. "/programs/fun/advanced"
        end
    end
    if pocket then
        shellPath = shellPath .. ":" .. basePath .. path .. "/programs/pocket"
    end
    if commands then
        shellPath = shellPath .. ":" .. basePath .. path .. "/programs/command"
    end
    if http then
        shellPath = shellPath .. ":" .. basePath .. path .. "/programs/http"
    end
    shell.setPath(shellPath)
end

---------------------------------------
-- Initializes default module paths
---------------------------------------
ghu.initModulePaths = function()
    ghu.addModulePath("core")
    for i, repo in ipairs(extraRepos) do
        ghu.addModulePath(repo)
    end
end

---------------------------------------
-- Initializes default shell paths
---------------------------------------
ghu.initShellPaths = function()
    ghu.addShellPath("core")
    for i, repo in ipairs(extraRepos) do
        ghu.addShellPath(repo)
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

return ghu
