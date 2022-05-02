local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")

print("Updating repos...")
local repoCount = 1
local count = ghu.updateRepo(ghu.s.coreRepo.get(), true)
for _, repoString in pairs(ghu.s.extraRepos.get()) do
    count = count + ghu.updateRepo(repoString)
    repoCount = repoCount + 1
end
print(string.format(
    "Updated %s file%s from %s repo%s",
    count, count ~= 1 and "s" or "",
    repoCount, repoCount ~= 1 and "s" or ""
))
