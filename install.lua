local v = require("cc.expect")

local ghBase = "https://raw.githubusercontent.com/"
local coreRepo = "AngellusMortis/cc-updater"
local ref = "v2"
local baseUrl = ghBase .. coreRepo .. "/" .. ref .. "/src/"
local requiredFiles = {
    "apis/am/core.lua",
    "apis/ghu.lua",
    "programs/ghuupdate.lua"
}

local function getAndCheck(url)
    v.expect(1, url, "string")

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

local function main(root)
    if root == nil then
        root = "/"
    end
    v.expect(1, root, "string")

    local basePath = root .. "ghu/"
    for _, file in ipairs(requiredFiles) do
        download(
            baseUrl .. file,
            basePath .. "core/" .. file
        )
    end

    settings.set("ghu.base", basePath)
    settings.set("ghu.coreRepo", coreRepo .. "@" .. ref)
    settings.save()
    if shell.run(basePath .. "core/programs/ghuupdate.lua") then
        print("Install complete")
    else
        error("Error installing")
    end
end

local root = arg[1]
if root == "run" then
    root = arg[3]
end
main(root)
