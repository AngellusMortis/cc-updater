local function getAndCheck(url)
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

    download(
        "https://raw.githubusercontent.com/AngellusMortis/cc-updater/v1/src/apis/ghu.lua",
        root .. "ghu/core/apis/ghu.lua"
    )
    download(
        "https://raw.githubusercontent.com/AngellusMortis/cc-updater/v1/src/programs/ghuupdate.lua",
        root .. "ghu/core/programs/ghuupdate.lua"
    )

    settings.set("ghu.base", root .. "ghu/")
    settings.save()
    shell.run(root .. "ghu/core/programs/ghuupdate.lua")
    print("Install complete")
end

local root = arg[1]
if root == "run" then
    root = arg[3]
end
main(root)