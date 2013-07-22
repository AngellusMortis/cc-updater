--am/turtle/branch.lua
local version = "2.002"

local args = { ... }

local progressFile = "amBranch.progress"
local fuelSafeLevels = { 1000, 10000 }
local numberOfBranches  = 10
local lengthOfBranches = 52
local distanceBetweenBranches = 4
local distanceBetweenPaths = 26
local distanceBetweenTorches = 10

local torchSlot = 16
local itemSlotsRange = { 1, 15 }

local position = { 0 , 0 }
local facing = 0
local chestPosition = { 0, 0 }

local function readSettings() 
	handle = fs.open("amTurtle.settings", "rb")

	distanceIntoBranch = handle.read()
	sideOffset = handle.read()
	currentBranch = handle.read()
	facing = handle.read()

	handle.close()
end

local function writeSettings()
	handle = fs.open(settingsFile, "wb")

	handle.write(distanceIntoBranch)
	handle.write(sideOffset)
	handle.write(math.floor(currentBranch))
	handle.write(facing)

	handle.close()
end

local function rotate(direction)
	if not (facing == direction) then
		local offset = direction - facing
		local rotateDirection = "left"
		if (offset == -1 or offset == 3) then
			rotateDirection = "right"
		end

		if (rotateDirection == "left") then
			while not (facing == direction) do
				turtle.turnLeft()
				facing = facing + 1
				if (facing > 3) then
					facing = facing - 4
				end
			end
		else
			while not (facing == direction) do
				turtle.turnRight()
				facing = facing - 1
				if (facing < 0) then
					facing = facing + 4
				end
			end
		end
	end
end

local function goTo(position1, position2)
	local destinationPosition = { position1, position2 }

	rotate(2)
	while (position[2] > 0) do
		while not (turtle.forward()) do
			turtle.dig()
			turtle.attack()
			sleep(2)
		end
		position[2] = position[2] - 1
	end


	if (position[1] < destinationPosition[1]) then
		rotate(3)
	else
		rotate(1)
	end
	while not (position[1] == destinationPosition[1]) do
		while not (turtle.forward()) do
			turtle.dig()
			turtle.attack()
			sleep(2)
		end
		if (facing == 3) then
			position[1] = position[1] + 1
		else
			position[1] = position[1] - 1
		end
	end

	if (position[2] < destinationPosition[2]) then
		rotate(0)
	else
		rotate(2)
	end
	while not (position[2] == destinationPosition[2]) do
		while not (turtle.forward()) do
			turtle.dig()
			turtle.attack()
			sleep(2)
		end
		if (facing == 0) then
			position[2] = position[2] + 1
		else
			position[2] = position[2] - 1
		end
	end
end

local function checkTorches()
	while (turtle.getItemCount(torchSlot) == nil) or (turtle.getItemCount(torchSlot) == 0) or (turtle.getItemCount(torchSlot) < math.floor(lengthOfBranches/distanceBetweenTorches)) do
		print("WARNING: Not enough torches! Put more torches in " .. core.intString(torchSlot) .. " and press ENTER")
		repeat
	    	event, param1 = os.pullEvent ("key")
	    until param1 == 28
	end
end

local function checkFuel()
	for x = itemSlotsRange[1], itemSlotsRange[2] do
		turtle.select(x)
		turtle.refuel()
	end
	if (turtle.getFuelLevel() < fuelSafeLevels[1]) then
		print("Need more fuel (" .. core.intString(turtle.getFuelLevel()) .. "). Returning...")
		local oldPosition = { position[1], position[2] }
		local oldFacing = facing
		goTo(chestPosition[1], chestPosition[2])
		print("Empting inventory...")
		turtle.rotate(1)
		for x = itemSlotsRange[1], itemSlotsRange[2] do 
			turtle.select(2)
			turtle.drop()
		end
		rotate(1)
		turtle.select(1)
		while (turtle.getFuelLevel() < fuelSafeLevels[2]) do
			while not (turtle.suckDown()) do
				print("IMPORTANT: Not enough fuel! Press ENTER when more fuel added.")
				repeat
			    	event, param1 = os.pullEvent ("key")
			    until param1 == 28
			end
			turtle.refuel()
		end
		print("New fuel level: " .. core.intString(turtle.getFuelLevel()))

		print("Returning to old position...")
		goTo(oldPosition[1], oldPosition[2])
		rotate(oldFacing)
	end
end

local function checkInventory()
	for x = itemSlotsRange[1], itemSlotsRange[2] do
		turtle.select(x)
		turtle.refuel()
		if (turtle.getItemCount(x) == 0 or turtle.getItemCount(x) == nil) then
			return true
		end
	end
	print("Inventory full! Returning...")
	local oldPosition = { position[1], position[2] }
	local oldFacing = facing
	goTo(chestPosition[1], chestPosition[2])
	print("Empting inventory...")
	rotate(1)
	for x = itemSlotsRange[1], itemSlotsRange[2] do 
		turtle.select(x)
		turtle.drop()
	end
	checkFuel()
	print("Returning to old position...")
	goTo(oldPosition[1], oldPosition[2])
	rotate(oldFacing)
end

local function mineBranch()
	checkFuel()
	checkTorches()
	rotate(0)
	while (position[2] < lengthOfBranches) do
		checkInventory()

		turtle.select(1)

		if (position[2] % distanceBetweenPaths == 0 and not (position[2] == 0)) then
			print("Mining path...")
			rotate(3)
			for x = 1, 3 do
				turtle.select(1)
				while not (turtle.forward()) do
					turtle.dig()
				end
				turtle.digUp()
			end
			rotate(1)
			for x = 1, 3 do
				turtle.select(1)
				while not (turtle.forward()) do
					turtle.dig()
					turtle.attack()
					sleep(1)
				end
				if (x == 1) then
					turtle.select(torchSlot)
					turtle.placeUp()
				end
			end
			rotate(0)
		end
		
		while not (turtle.forward()) do
			turtle.dig()
			turtle.attack()
		end
		turtle.digUp()
		position[2] = position[2] + 1
	end

	print("Returning...")
	rotate(2)
	while (position[2] > chestPosition[2]) do
		if (position[2] % distanceBetweenTorches == 1) then
			print("Placing Torch...")
			turtle.select(torchSlot)
			turtle.placeUp()
		end
		while not (turtle.forward()) do
			turtle.select(1)
			turtle.dig()
			turtle.attack()
			sleep(2)
		end
		position[2] = position[2] - 1
	end

	print("Mining to next branch...")
	rotate(3)
	turtle.up()
	for y = 1, distanceBetweenBranches do
		turtle.select(1)
		while not (turtle.forward()) do
			turtle.dig()
		end
		turtle.digUp()
		turtle.digDown()
	end
	while not (turtle.down()) do
		turtle.digDown()
	end
	position[1] = position[1] + distanceBetweenBranches
	position[2] = 0
end

function main(currentBranch, numBranches, lenBranches)
	if not (currentBranch == nil) then
		currentBranch = tonumber(currentBranch)
		position[1] = (currentBranch - 1) * distanceBetweenBranches
		position[2] = 0
	else
		currentBranch = (position[1] / distanceBetweenBranches) + 1
	end
	if not (numBranches == nil) then
		numberOfBranches = tonumber(numBranches)
	end
	if not (lenBranches == nil) then
		lengthOfBranches = tonumber(lenBranches)
	end

	goTo(position[1], 0)
	for x = currentBranch, numberOfBranches do
		print("Mining branch #" .. currentBranch .. " of " .. numberOfBranches .. "...")
		mineBranch()
	end
	print("Going back to chest...")
	goTo(chestPosition[1], chestPosition[2])
end

main(args[1], args[2], args[3])
