local basePath = settings.get("ghu.base")
local ghu = require(basePath .. "core/apis/ghu")

local function updateRepo(repo, basePath)
    local parts = ghu.split(repo, ":")

    local base = "/"
    if #parts == 1 then
        base = "/"
    elseif #parts > 2 then
        error("Bad repo: " .. repo)
    else
        repo = parts[1]
        base = parts[2]
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

    local status = repo
    if basePath == nil then
        basePath = "/ghu/" .. repo
    end
    basePath = basePath .. base
    print("." .. repo)
    print("..ref:" .. ref .. ".path:" .. base)
    if basePath ~= nil then
        print("..dest:" .. basePath)
    end

    local baseURL = "https://raw.githubusercontent.com/" .. repo .. "/" .. ref .. base .. "/"
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
            print("..." .. path)
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
