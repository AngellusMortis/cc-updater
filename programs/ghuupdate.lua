local basePath = settings.get("ghu.base")
local ghu = require(basePath .. "core/apis/ghu")

local function updateRepo(repo, basePath)
    items = ghu.split(repo, "@")
    if #items == 1 then
        ref = "master"
    elseif #items > 2 then
        error("Bad repo: " .. repo)
    else
        repo = items[0]
        ref = items[1]
    end

    if basePath == nil then
        basePath = "/ghu/" .. repo
    end
    basePath = basePath .. "/"

    local baseURL = "https://raw.githubusercontent.com/" .. repo .."/" .. ref .. "/"
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
            print("Updating " .. path .. "...")
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

print("Updating core repo...")
updateRepo(ghu.coreRepo, ghu.base .. "core")
for _, repo in pairs(ghu.extraRepos) do
    print("Updating " .. repo .. "...")
    updateRepo(repo)
end
