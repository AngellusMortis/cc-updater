local basePath = settings.get("ghu.base")
local ghu = require(basePath .. "core/apis/ghu")

local function updateRepo(repo, basePath)
    local items = ghu.split(repo, ":")
    local base = "/"
    if #items == 1 then
        base = "/"
    elseif #items > 2 then
        error("Bad repo: " .. repo)
    else
        repo = items[0]
        base = items[1]
    end

    items = ghu.split(repo, "@")
    if #items == 1 then
        ref = "master"
    elseif #items > 2 then
        error("Bad repo: " .. repo)
    else
        repo = items[0]
        ref = items[1]
    end

    local status = string.format("%s (%s)", repo, basePath)
    if basePath == nil then
        status = repo
        basePath = "/ghu/" .. repo
    end
    basePath = basePath .. base
    print("." .. status)

    local baseURL = "https://raw.githubusercontent.com/" .. repo .. base .. ref .. "/"
    local manifest = ghu.getJSON(baseURL .. "manifest.json")
    local localManifest = {}
    local manifestPath = basePath .. "manfiest"
    if fs.exists(manifestPath) then
        local f = fs.open(manifestPath, "r")
        localManifest = textutils.unserialize(f.readAll())
        f.close()
    end

    for path, checksum in pairs(manifest) do
        if checksum ~= localManifest[path] then
            print(".." .. path)
            ghu.download(baseURL .. path, basePath .. path)
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
updateRepo(ghu.coreRepo, ghu.base .. "core")
for _, repo in pairs(ghu.extraRepos) do
    updateRepo(repo)
end
