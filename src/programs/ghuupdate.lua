local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")

if ghu.s.minified.get() then
    print("Updating repos (min)...")
else
    print("Updating repos (full)...")
end
local count, repoCount = ghu.updateRepo("core")
for _, repoString in pairs(ghu.s.extraRepos.get()) do
    local subCount, subRepo = ghu.updateRepo(repoString)
    count = count + subCount
    repoCount = repoCount + subRepo
end
print(string.format(
    "Updated %s file%s from %s repo%s",
    count, count ~= 1 and "s" or "",
    repoCount, repoCount ~= 1 and "s" or ""
))
if count > 1 then
    local oldAutoUpdate = ghu.s.autoUpdate.get()
    ghu.s.autoUpdate.set(false)
    shell.run(settings.get("ghu.base") .. "core/programs/ghureload")
    ghu.s.autoUpdate.set(oldAutoUpdate)
end
