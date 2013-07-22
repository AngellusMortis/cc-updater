--amShell/am/turtle/dig.lua
local version = "1.101"

local args = { ... }

local function checkFuelNeeds(height, size)
	--requires (size x (size-1) + (size-1) + 2)
	local setOf2 = math.floor(height / 2)
	--requires (size x (size-1) + (size-1))
	local setOf1 = height % 2
	--requires (size x (size-1) + (size-1) + 1)
	local last2 = 0

	if (setOf2 > 0) then
		setOf2 = setOf2 - 1
		last2 = 1
	end

	local requiredFuel = setOf2 * (size * (size-1) + (size-1) + 2) + setOf1 * (size * (size-1) + (size-1)) + last2 * (size * (size-1) + (size-1) + 1)
	while (turtle.getFuelLevel() < requiredFuel) do
		print("Not enough Fuel!")
		print("Need at least " .. requiredFuel - turtle.getFuelLevel() .. " more.")
		print("Put in more fuel and press ENTER")
		local event, param1
		repeat
			event, param1 = os.pullEvent ("key")
		until param1 == 28
		for x = 1, 16 do
			turtle.select(x)
			turtle.refuel()
		end
		turtle.select(1)
	end
	return true
end

local function clearChunk(height, size)
	if height == nil then
		height = 10
	end
	
	if size == nil then
	    size = 16
	end

	if (checkFuelNeeds(height, size)) then
		while (height > 0) do
			for x = 1, (size/2) do
				for y = 1, 2 do
					for z = 1, (size-1) do
						if (height > 1) then
							turtle.digDown()
						end
						while (not turtle.forward()) do
							turtle.dig()
						end
					end

					if (height > 1) then
						turtle.digDown()
					end
					if (y == 1) then
						turtle.turnLeft()
						while (not turtle.forward()) do
							turtle.dig()
						end
						turtle.turnLeft()
					elseif not (x == (size/2)) then
						turtle.turnRight()
						while (not turtle.forward()) do
							turtle.dig()
						end
						turtle.turnRight()
					end
				end
			end
			height = height - 1
			if (height > 0) then
				turtle.digDown()
				turtle.down()
				height = height - 1
			end
			if (height > 0) then
				turtle.turnLeft()
				turtle.digDown()
				turtle.down()
			end
		end
	end
end

clearChunk(tonumber(args[1]), tonumber(args[2]))