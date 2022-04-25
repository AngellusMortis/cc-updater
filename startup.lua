local ghu = require("/ghu/core/apis/ghu")
ghu.initShellPaths()

if ghu.autoUpdate then
    shell.run("ghuupdate")
end
