local v = require("cc.expect")

local ghu = {}
ghu.p = {}
ghu.p.root = "/"
ghu.p.base = "/ghu/"
if fs.exists("/disk/ghu") then
    ghu.p.base = "/disk/ghu/"
end
ghu.p.base = settings.get("ghu.base", "/ghu/")
if string.sub(ghu.p.base, 1, string.len(5))== "/disk" then
    ghu.p.root = "/disk/"
end
ghu.p.core = ghu.p.base .. "core/"
ghu.p.ext = ghu.p.base .. "ext/"

core = require(ghu.p.core .. "apis/am/core")

local modulesInitialized = pcall(function () require("am.core") end)
local shellInitialized = shell.resolveProgram("ghuconf")
local s = {}
s = {}
s.base = {
    name = "ghu.base",
    default = ghu.p.base,
    type = "string",
    description = "The base path for cc-updater. Recommendeded not to change."
}
s.autoUpdate = {
    name="ghu.autoUpdate",
    default = true,
    type = "boolean",
    description = "Auto-update cc-updater repos on computer boot."
}
s.autoRun = {
    name="ghu.autoRun",
    default = true,
    type = "boolean",
    description = "Allow extra repos to provide auto-run programs."
}
s.coreRepo = {
    name = "ghu.coreRepo",
    default = "AngellusMortis/cc-updater@v1:/src",
    type = "string",
    description = "Core repo for cc-updater. Recommended not to change."
}
s.extraRepos = {
    name = "ghu.extraRepos",
    default = {},
    type = "table",
    description = "List of extra cc-updater repos."
}
ghu.s = core.makeSettingWrapper(s)
-- hack for ghureload to ensure startup is only loaded once
_G.ghuStartupRan = false


---Gets disk path for repo
---@param repo string repo/module
---@param base string? relative path in repo
---@return string
local function getRepoPath(repo, base)
    v.expect(1, repo, "string")
    v.expect(2, base, "string", "nil")

    local path = ghu.p.ext .. repo
    if repo == "core" then
        path = ghu.p.core
        base = ""
    end
    if base == nil or base == "" then
        base = "/src"
    end

    base = base:gsub("/src", "")
    if base:sub(1, 1) == "/" then
        base = base:sub(2)
    end
    if path:sub(#path, #path) ~= "/" then
        path = path .. "/"
    end
    path = path .. base
    if path:sub(#path, #path) ~= "/" then
        path = path .. "/"
    end
    return path
end

---Parse Github repo string
---
---Format is `{owner}/{repoName}(@{ref})?(:{base}?`
---
---If `ref` is left out, it defaults to `master`
---If `base` is left out, it defaults to `/src`
---@param repoString string Github repo string
---@return string, string, string, string
local function parseRepo(repoString)
    v.expect(1, repoString, "string")

    local isCore = repoString == "core"
    if isCore then
        repoString = ghu.s.coreRepo.get()
    end

    local parts = core.split(repoString, ":")
    local repo = parts[1]
    local base = "/"
    if #parts == 1 then
        base = "/src"
    elseif #parts > 2 then
        error("Bad repo path: " .. repoString)
    else
        repo = parts[1]
        base = parts[2] .. "/"
    end

    parts = core.split(repo, "@")
    if #parts == 1 then
        ref = "master"
    elseif #parts > 2 then
        error("Bad repo ref: " .. repoString)
    else
        repo = parts[1]
        ref = parts[2]
    end
    return getRepoPath(isCore and "core" or repo, base), repo, ref, base
end

---Get manifest path for downloaded repo
---@param repoString string repo/module
---@return string
local function getManifestPath(repoString)
    v.expect(1, repoString, "string")

    local path = parseRepo(repoString)
    return path .. "manifest"
end

---Get manifest for downloaded repo on disk
---@param repoString string repo/module
---@return table
local function readManifest(repoString)
    v.expect(1, repoString, "string")

    local manifestPath = getManifestPath(repoString)
    if not fs.exists(manifestPath) then
        return {files={}}
    end

    local f = fs.open(manifestPath, "r")
    local manifest = textutils.unserialize(f.readAll())
    if manifest.files == nil then
        manifest = {files=manifest}
    end
    f.close()

    return manifest
end

---Write manifest for downloaded repo on disk
---@param repoString string repo/module
---@param manifest table manifest table
local function writeManifest(repoString, manifest)
    v.expect(1, repoString, "string")

    local manifestPath = getManifestPath(repoString)
    if fs.exists(manifestPath) then
        fs.delete(manifestPath)
    end

    local f = fs.open(manifestPath, "w")
    f.write(textutils.serialize(manifest))
    f.close()
end

---Downloads and updates a repo
---@param repoString string repo/module
---@return number, number
local function updateRepo(repoString)
    v.expect(1, repoString, "string")

    local isCore = repoString == "core"
    local basePath, repo, ref, base = parseRepo(repoString)
    print("." .. repo)
    print("..ref:" .. ref .. ".path:" .. base)
    print("..dest:" .. basePath)

    local baseURL = "https://raw.githubusercontent.com/" .. repo .. "/" .. ref .. base .. "/"
    local manifest = core.getJSON(baseURL .. "manifest.json")
    local localManifest = readManifest(repoString)

    local downloadCount = 0
    local repoCount = 1
    if manifest.dependencies ~= nil and #(manifest.dependencies) > 0 then
        print("..deps:" .. tostring(#(manifest.dependencies)))
        print("..startdeps:" .. repo .. base)
        for _, depRepo in ipairs(manifest.dependencies) do
            local depDownload, depCount = updateRepo(depRepo)
            downloadCount = downloadCount + depDownload
            repoCount = repoCount + depCount
        end
        print("..enddeps:" .. repo .. base)
    end

    for path, checksum in pairs(manifest.files) do
        if path == "startup.lua" and not isCore then
            error("Only coreRepo can set startup.lua")
        end
        if checksum ~= localManifest.files[path] then
            print("..." .. path)
            if path == "startup.lua" then
                core.download(baseURL .. path, ghu.p.root .. path)
            else
                core.download(baseURL .. path, basePath .. path)
            end
            downloadCount = downloadCount + 1
        end
    end
    print("..total: " .. tostring(downloadCount))

    writeManifest(repoString, manifest)
    return downloadCount, repoCount
end

---Get dependencies for downloaded repo
---@param repoString string repo/module
---@param manifest? table Optional manifest to use
---@return table
function getDeps(repoString, manifest)
    v.expect(1, repoString, "string")
    v.expect(2, manifest, "table", "nil")
    if manifest == nil then
        manifest = readManifest(repoString)
    end
    if manifest == nil then
        error("Could not load manifest")
        return
    end

    deps = {}
    if manifest.dependencies == nil then
        return deps
    end

    for _, depString in ipairs(manifest.dependencies) do
        deps = core.concat(deps, getDeps(depString))
        deps[#deps + 1] = depString
    end

    return deps
end

---Gets autorun programs for subscribed repos
---@return table
local function getAutoruns()
    local autoruns = {}
    for i, repoString in ipairs(ghu.s.extraRepos.get()) do
        local path = parseRepo(repoString)
        local autorunPath = path .. "autorun/"
        autoruns = core.concat(autoruns, fs.find(autorunPath .. "*.lua"))
    end
    return autoruns
end

---Adds repo to shell path
---
---Helper function to add a search path to `shell.path` for repo
---
---Follows the same structure as the base CC paths
---@param repoString string repo/module
local function addShellPath(repoString)
    v.expect(1, repoString, "string")

    local path = parseRepo(repoString)
    local shellPath = shell.path()
    local basePath = ":" .. path
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

-- Adds all subscribed repos to shell path
local function initShellPaths(force)
    v.expect(1, force, "boolean", "nil")
    if force == nil then
        force = false
    end

    if shellInitialized and not force then
        return
    end

    addShellPath("core")
    local loadedModules = {["core"]=true}
    for i, repoString in ipairs(ghu.s.extraRepos.get()) do
        if loadedModules[repoString] == nil then
            addShellPath(repoString)
            loadedModules[repoString] = true
        end

        local deps = getDeps(repoString)
        for _, dep in ipairs(deps) do
            addShellPath(dep)
        end
    end
end

---Add Module path
--
-- Helper function to add a search path to package.path for repos
---@param repoString string repo/module
local function addModulePath(repoString)
    v.expect(1, repoString, "string")

    local path = parseRepo(repoString)
    local modulePath = package.path
    local basePath = ";" .. path
    modulePath = modulePath .. basePath .. "apis/?"
    modulePath = modulePath .. basePath .. "apis/?.lua"
    modulePath = modulePath .. basePath .. "apis/?/init.lua"
    package.path = modulePath
end

---Initializes default module paths for subscribe repos
local function initModulePaths(force)
    v.expect(1, force, "boolean", "nil")
    if force == nil then
        force = false
    end

    if modulesInitialized and not force then
        return
    end

    addModulePath("core")
    local loadedModules = {["core"]=true}
    for i, repoString in ipairs(ghu.s.extraRepos.get()) do
        if loadedModules[repoString] == nil then
            addModulePath(repoString)
            loadedModules[repoString] = true
        end

        local deps = getDeps(repoString)
        for _, dep in ipairs(deps) do
            addModulePath(dep)
        end
    end
    modulesInitialized = true
end

ghu.parseRepo = parseRepo
ghu.getRepoPath = getRepoPath
ghu.getManifestPath = getManifestPath
ghu.readManifest = readManifest
ghu.writeManifest = writeManifest
ghu.updateRepo = updateRepo
ghu.getDeps = getDeps
ghu.getAutoruns = getAutoruns
ghu.addShellPath = addShellPath
ghu.initShellPaths = initShellPaths
ghu.addModulePath = addModulePath
ghu.initModulePaths = initModulePaths

initShellPaths()
initModulePaths()

return ghu
