--am/programs/copy.lua
version = "1.001"

local args = { ... }

local function doCopy(from, to)

	local path1 = fs.list(args[1])
	local path2 = fs.list(args[2])

	for x = 1, #path2 do
		fs.delete(to .. "/" .. path2[x])
	end
	for x = 1, #path1 do
		if (fs.isDir(from .. "/" .. path1[x])) then
			fs.makeDir(to .. "/" .. path1[x])
			doCopy(from .. "/" ..path1[x], to .. "/" .. path1[x])
		end
		fs.copy(from .. "/" .. path1[x], to .. "/" .. path1[x])
	end
end

if (args[1] == nil or args[2] == nil) then
	print("Invalid path supplied")
else
	doCopy(args[1], args[2])
end
