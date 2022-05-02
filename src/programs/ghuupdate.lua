local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")

print("Updating repos...")
ghu.updateRepo(ghu.s.coreRepo.get(), true)
for _, repoString in pairs(ghu.s.extraRepos.get()) do
    ghu.updateRepo(repoString)
end
