--amShell/am/turtle/place.lua
version = "1.111"

local args = { ... }

local function checkFuelNeeds(size)
    if size == nil then
        size = 16
    end
	local requiredFuel = (size * size) - 1
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

local function tryPlace(slot)
	if not (turtle.detectUp()) then
		while (turtle.getItemCount(slot) == 0 or turtle.getItemCount(slot) == nil) do
			if (slot < 16) then
				slot = slot + 1
			else
				print("Not enough items!")
				print("Put in more items and press ENTER")
				local event, param1
				repeat
					event, param1 = os.pullEvent ("key")
				until param1 == 28
				slot = 1
			end
		end
		turtle.select(slot)
		turtle.placeUp()
	end
	return slot
end

local function doPlace(size)
	checkFuelNeeds(size)
	local odd = ((size % 2) == 1)
	local runs = math.floor(size / 2)
	local slot = 1
	turtle.select(slot)
	for x = 1, runs do
		local secondRun = 2
		if (odd and x == runs) then
			secondRun = 1
		end 
		for y = 1, secondRun do
			tryPlace(slot)
			slot = tryPlace(slot)
			for z = 1, (size - 1) do
				while not (turtle.forward()) do end
				slot = tryPlace(slot)
			end
			if (y == 1) then
				turtle.turnLeft()
				while not (turtle.forward()) do end
				turtle.turnLeft()
			else
				turtle.turnRight()
				while not (turtle.forward()) do end
				turtle.turnRight()
			end
		end
	end
end

doPlace(tonumber(args[1]))
