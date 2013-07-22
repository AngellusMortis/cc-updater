--amShell/startup.lua
local version = "1.540"

local path = "/"
if fs.exists("/disk/am") then
	path = "/disk/"
end

if not os.loadAPI(path .. "am/core/core") then
    error("amCore was not able to be loaded.")
end

if not turtle then
	shell.run(path .. "am/core/layer")
	shell.run(path .. "am/core/shell")
elseif path == "/disk/" then
	shell.run(path .. "am/programs/update")
	print("Removing old files...")
	shell.run("rm", "/am")
	shell.run("rm", "/startup")
	print("Remaking directories...")
	fs.makeDir("/am")
	fs.makeDir("/am/core")
	print("Copying over new files...")
	shell.run("cp", path .. "am/turtle", "/am/programs")
	shell.run("mv", "/am/programs/startup", "/startup")
	shell.run("cp", path .. "am/core/core", "/am/core/core")
end