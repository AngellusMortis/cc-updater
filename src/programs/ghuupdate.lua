local basePath = settings.get("ghu.base")
local ghu = require(basePath .. "core/apis/ghu")

local function updateRepo(repoString, basePath, allowStartup)
    local repo, ref, base = ghu.parseRepo(repoString)
    local status = repo
    if basePath == nil then
        basePath = ghu.base .. repo
    end
    destPath = base:gsub("/src", "")
    basePath = basePath .. destPath
    print("." .. repo)
    print("..ref:" .. ref .. ".path:" .. base)
    print("..dest:" .. basePath)

    local baseURL = "https://raw.githubusercontent.com/" .. repo .. "/" .. ref .. base
    local manifest = ghu.getJSON(baseURL .. "manifest.json")
    local localManifest = {}
    local manifestPath = basePath .. "manfiest"
    if fs.exists(manifestPath) then
        local f = fs.open(manifestPath, "r")
        localManifest = textutils.unserialize(f.readAll())
        f.close()
    end

    for path, checksum in pairs(manifest) do
        if path == "startup.lua" and not allowStartup then
            error("Only coreRepo can set startup.lua")
        end
        if checksum ~= localManifest[path] then
            print("..." .. path)
            if path == "startup.lua" then
                ghu.download(baseURL .. path, ghu.root .. path)
            else
                ghu.download(baseURL .. path, basePath .. path)
            end
        end
    end

    if fs.exists(manifestPath) then
        fs.delete(manifestPath)
    end
    local f = fs.open(manifestPath, "w")
    f.write(textutils.serialize(manifest))
    f.close()
end

print("Updating repos...")
updateRepo(ghu.coreRepo, ghu.base .. "core", true)
for _, repo in pairs(ghu.extraRepos) do
    updateRepo(repo)
end
