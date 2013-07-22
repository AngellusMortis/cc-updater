--am/programs/update.lua
local version = "4.135"

local args = { ... }
local updateSelf = false
local updateShell = false

local old = shell.dir()
shell.setDir("/")
local path = "/"
if fs.exists("/disk/am") then
	path = "/disk/"
end

local function getInfo(pathToFile)
	local h = fs.open(pathToFile, "r")
	local pid = (h.readLine()):sub(3)
	loadstring(h.readLine())()
	h.close()
	return pid, version
end

local function getFiles(filters)
	local paths = { path, path .. "am/core/", path .. "am/programs/", path .. "am/turtle/"}
	local fileList = {}
	local toCheck = {}
	local found = {}
	for z, filter in pairs(filters) do
		table.insert(found, false)
	end

	if (tonumber(table.getn(filters)) == 0) then
		fileList = core.getFileList("")
	end

	for x, cPath in pairs(paths) do
		local files
		if (cPath == path) then
			files = { "startup" }
		else
			files = fs.list(cPath)
		end

		for y, file in pairs(files) do
			local check = true
			for z, filter in pairs(filters) do
				if filter == file then
					found[z] = true
				else
					check = false
				end
			end

			if check and not (fs.isDir(cPath .. file)) then
				table.insert(toCheck, cPath .. file)
			end
		end
	end

	for z, filter in pairs(filters) do
		if not found[z] then
			found[z] = filter
		else
			table.remove(found, z)
		end
	end

	return toCheck, fileList, found
end

function main()
    math.randomseed(os.time() * 1024 % 46)
    local updated = 0
    local failed = 0
    local skipped = 0
    local gotten = 0
	local files, new, found = getFiles(args)
	for x, value in pairs(found) do
		if not found then
			core.cPrint("&e" .. tostring(found[x]) .. " &7not found.")
		end
	end
	core.cPrint()
	core.cPrint("&5Updating&e " .. table.getn(files) .. " &5files...")
	core.cPrint()

	for key, file in pairs(files) do
		local pid, version = getInfo(file)
		version = tonumber(version)
		local dVersion = 100
		if not (pid == "NaN") then
			core.cPrint("&1" .. file .. ":&2 " .. pid)
			for x, item in pairs(new) do
				if (path .. item[1] .. item[2]) == file then
					dVersion = item[3]
					table.remove(new, x)
					break
				end
			end
			if dVersion == nil then dVersion = 100 end
			if dVersion > version then
				if (file ~= (path .. "am/programs/update")) and (file ~= (path .. "am/core/shell"))  then
					core.cWrite("&6Updating...")
					local response = http.get(core.url .. pid .."?random=" .. math.random(1, 1000000))
					if response then
						local handle = fs.open(file, "w")
						handle.write(response.readAll())
						handle.close()
						core.cPrint("done&0")
						updated = updated + 1
					else
						core.cPrint("failed&0")
						failed = failed + 1
					end
				elseif file == (path .. "am/programs/update") then
					updateSelf = true
				elseif file == (path .. "am/core/shell") then
				    updateShell = true
				end
			else
				core.cPrint("&6Upto date already. &aSkipping...&0")
				skipped = skipped + 1
			end
		else
			core.cPrint("&bSkipping " .. file .. "...&0")
			skipped = skipped + 1
		end
	end

	for x, item in pairs(new) do
		core.cPrint("&5New file found: &4" .. item[1] .. item[2])
		core.cWrite("&6Downloading...")
		local response = http.get(core.url .. "" .. item[1] .. item[2] .. ".lua")
		if response ~= nil then
			local handle = fs.open(path .. item[1] .. item[2], "w")
			handle.write(response.readAll())
			handle.close()
			core.cPrint("done&0")
			gotten = gotten + 1
		else
			core.cPrint("failed&0")
			failed = failed + 1
		end
	end
	
	core.cPrint()
	core.cPrint("&0Updated: &5" .. updated)
	core.cPrint("&0Failed: &e" .. failed)
	core.cPrint("&0Skipped: &b" .. skipped)
	core.cPrint("&0New: &5" .. gotten)
	core.cPrint("&2Total: &0" .. updated + failed + skipped + gotten)

	if updateSelf then
		core.cPrint("Updating updater...")
		shell.run("get", path .. "am/programs/update")
	end
	
	if updateShell then
	    core.cPrint("Updating shell...")
	    shell.run("get", path .. "am/core/shell")
	end
	
	if updateSelf or updateShell then
	    core.cPrint("Rebooting...")
		sleep(1)
		os.reboot()
    end
end

main()
shell.setDir(old)
