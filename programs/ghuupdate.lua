local ghu = require("/ghu/core/apis/ghu")

local function updateRepo(repo, path)
    items = ghu.split(repo, "@")
    if #items == 1 then
        ref = "master"
    elseif #items > 2 then
        error("Bad repo: " .. repo)
    else
        repo = items[0]
        ref = items[1]
    end

    if path == nil then
        path = "/ghu/" .. repo
    end
    local baseURL = "https://raw.githubusercontent.com/" .. repo .."/" .. ref .. "/"
    local manifest = ghu.getJSON(baseURL .. "manifest.json")

    for path, checksum in pairs(manifest) do
        print(path)
    end
end

print("Updating core repo...")
updateRepo(settings.get(ghu.s.coreRepo.name), "core")
