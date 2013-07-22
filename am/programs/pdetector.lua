--am/programs/pdetector.lua
local version = "1.000"

if not fs.exists("/ocs") then
    error("OpenCCSensors not installed.")
end

os.loadAPI("ocs/apis/sensor")

local retestInterval = 3
local doMonitor = true
local maxLineCount = 14
local timeURL = "http://www.timeapi.org/utc/now?\\a%20\\b%20\\d%20\\I:\\M:\\S"
local doLog = true
local doSignal = true
local signalSide = "top"
local signalOn = false

local function countdown(time) 
	while (time > 0) do
		term.write(time .. "...")
		time = time - 1
		sleep(1)
	end
end

local function writeMontiorHeader(mon)
	mon.clear()
	mon.setCursorPos(1,1)
	mon.write ("@ Latest Vistors")
	mon.setCursorPos(1,2)
	return 2
end

local function main() 
	local sensorSide = core.getSideOfPeripheral("sensor")
	local monitorSide = core.getSideOfPeripheral("monitor")
	local mon
	local nCursor
	local lastTargets = {}

	if (doMonitor and monitorSide == nil) then
		print("No montior connected, not using one")
		doMonitor = false
	end

	if (sensorSide == nil) then
		error("No sensor connected")
	else 
		local prox = sensor.wrap(sensorSide)
		if (doMonitor) then
			mon = peripheral.wrap(monitorSide)
			nCursor = writeMontiorHeader(mon)
		end		

		while true do
			term.clear()
			term.setCursorPos(1, 1)
			print("Player Detector")
			print("")

			local targets = prox.getTargets()

			local entitiesFound = false
			print("Players in range:")
			for name, basicDetails in pairs(targets) do
				if (targets[name]["Name"] == "Player") then
					if (doSignal) then
						redstone.setOutput(signalSide, signalOn)
					end
					entitiesFound = true
					print("  " ..name)
					if (doMonitor and lastTargets[name] == nil) then
						local timeString = http.get(timeURL).readAll()
						nCursor = nCursor + 1
						if nCursor > maxLineCount then
							nCursor = writeMontiorHeader(mon)
						end
						mon.setCursorPos(1, nCursor)
						mon.write("<" .. timeString:sub(-8) .. "> " .. name)
						if (doLog) then
							h = fs.open("log", "a")
							h.writeLine("<" .. timeString .. "> " .. name)
          					h.close()
						end
					end
				end
				lastTargets = targets
			end

			if (not entitiesFound) then
				if (doSignal) then
					redstone.setOutput(signalSide, not signalOn)
				end
				print("  None")
			end

			term.write("Re-testing in ")
			countdown(retestInterval)
		end
	end
end

main()