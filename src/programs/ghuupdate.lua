local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")

print("Updating repos...")
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
