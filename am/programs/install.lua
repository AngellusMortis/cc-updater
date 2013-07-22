--am/programs/install.lua
version = "1.124"

local url = nil
if core == nil then
    core = {}
    url = "http://tundrasofangmar.net/static/cc/"
    core.getFileList = function(path)
    	local response = http.get(url .. path)
    	local files = {}
    	local line = response.readLine()
    	while line ~= nil do
    	  local path = line
    	  local fileName = response.readLine()
    	  local version = response.readLine()
    	  if (version ~= nil) and (fileName ~= nil) then
    	    table.insert(files, {path, fileName, tonumber(version)})
    	    line = response.readLine()
    	  end
    	end
    	return files
    end
end

local urlPath = ""
local files = core.getFileList(urlPath .. "index.php")


local function header()
	term.clear()
	term.setCursorPos(1, 1)
	if term.isColor() then
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.cyan)
	end
	print("amShell Installer v" .. version)
	term.setTextColor(colors.white)
end

local function rename()
	local sides = {"left", "right", "top", "bottom", "front", "back"}
	for x, side in pairs(sides) do
		if disk.getMountPath(side) == "disk" then
			disk.setLabel(side, "amShell")
			break
		end
	end
end

local function main()
    math.randomseed(os.time() * 1024 % 46)
	local installPath = "/"	

	if fs.exists("/disk/") then
		local answer = ""
		while not (answer == "n" or answer == "y") do
			header()
			print("You have a disk inserted. Do you want to")
			term.write(" install to the disk? ")
			answer = read()
			answer = (answer:sub(1, 1)):lower()
		end	

		if answer == "y" then
			installPath = "/disk/"
		end
	end

	header()
	term.write("Making directories...")
	for x,file in pairs(files) do
	    if (file[1] ~= "") and not (fs.isDir(installPath .. file[1])) then
	        fs.makeDir(installPath .. file[1])
	    end
	end
	print("done")
	term.write("Downloading files...")
	for x, file in pairs(files) do
		local response = http.get((core.url or url) .. urlPath .. file[1] .. file[2] .. ".lua?random=" .. math.random(1, 1000000))
		if response then
		    local handle = fs.open(installPath .. file[1] .. file[2], "w")
		    handle.write(response.readAll())
		    handle.close()
		end
	end
	print("done")
	if installPath == "/disk/" then
		rename()
	end
	print("Installation complete. Removing installer file...")
	shell.run("rm", shell.getRunningProgram())
	print("Press ENTER to reboot")
	local event, key = os.pullEvent("key")
	while not (key == 28) do
		event, key = os.pullEvent("key")
	end
	print("Rebooting...")
	sleep(1)
	os.reboot()
end

main()
