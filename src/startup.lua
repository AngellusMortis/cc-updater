local root = "/"
if fs.exists("/disk/ghu") then
    root = "/disk/"
end
local ghu = require(root .. "ghu/core/apis/ghu")
ghu.initShellPaths()

if ghu.autoUpdate then
    shell.run("ghuupdate")
end
