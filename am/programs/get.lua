--am/programs/get.lua
version = "1.021"

local args = { ... }
local function main()
    math.randomseed(os.time() * 1024 % 46)
	if args[1] == nil then
		print("Usage: get <file> [destination] [url]")
	else
		local down = args[1]
		local file = args[2] or (shell.dir() .. "/" .. down)
		local url = args[3] or (core.url .. "")

		down = shell.dir():gsub("disk/", "") .. "/" .. down
		term.write("Downloading...")
		local response = http.get(url .. down .. ".lua?random=" .. math.random(1, 1000000))
		if response then
			print("completed")
			term.write("Writing...")
			shell.run("rm", file)
			local handle = fs.open(file, "w")
			handle.write(response.readAll())
			handle.close()
			print("done")
		else
			print("failed")
		end
	end
end

main()
