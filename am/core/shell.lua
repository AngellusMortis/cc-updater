--am/core/shell.lua
local version = "0.814"

local parentShell = shell

if not shell.getVersion then
	parentShell = nil
end

local bExit = false
local sDir = (parentShell and parentShell.dir()) or ""
local sPath = (parentShell and parentShell.path()) or ".:/rom/programs"
local tAliases = (parentShell and parentShell.aliases()) or {}
local tProgramStack = {}
local tArgs = { ... }
local sLayerIndex
local processes = {}
local active = { 1, 1 }

local shell = {}
local tEnv = {
	["shell"] = shell,
}

-- Colours
local prompt = "&a`h&5`w&4\\$ "
local titleColor, textColour, bgColour, barColor
if term.isColour() then
	titleColor = colors.cyan
	textColour = colours.white
	bgColour = colours.black
	barColor = colours.lime
else
	titleColor = colours.white
	textColour = colours.white
	bgColour = colours.black
	barColor = colours.white
end


local oldRead=read
read = function( _sReplaceChar, _tHistory )
	term.setCursorBlink( true )

    local sLine = ""
	local nHistoryPos = nil
	local nPos = 0
    if _sReplaceChar then
		_sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
	end
	
	local w, h = term.getSize()
	local sx, sy = term.getCursorPos()	
	
	local function redraw( _sCustomReplaceChar )
		local nScroll = 0
		if sx + nPos >= w then
			nScroll = (sx + nPos) - w
		end
			
		term.setCursorPos( sx, sy )
		local sReplace = _sCustomReplaceChar or _sReplaceChar
		if sReplace then
			term.write( string.rep(sReplace, string.len(sLine) - nScroll) )
		else
			term.write( string.sub( sLine, nScroll + 1 ) )
		end
		term.setCursorPos( sx + nPos - nScroll, sy )
	end
	
	while true do
		local sEvent, param = os.pullEvent()
		if sEvent == "char" then
			local maxScroll = core.max(term.record.text) - ({term.getSize()})[2]
			if (term.scrolled < maxScroll) then
				term.scroll(maxScroll-term.scrolled)
			end
			sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
			nPos = nPos + 1
			redraw()
			
		elseif sEvent == "key" then
		    if param == keys.enter then
				-- Enter
				break
				
			elseif param == keys.left then
				-- Left
				if nPos > 0 then
					nPos = nPos - 1
					redraw()
				end
				
			elseif param == keys.right then
				-- Right				
				if nPos < string.len(sLine) then
					nPos = nPos + 1
					redraw()
				end
			
			elseif param == keys.up or param == keys.down then
                -- Up or down
				if _tHistory then
					redraw(" ");
					if param == keys.up then
						-- Up
						if nHistoryPos == nil then
							if #_tHistory > 0 then
								nHistoryPos = #_tHistory
							end
						elseif nHistoryPos > 1 then
							nHistoryPos = nHistoryPos - 1
						end
					else
						-- Down
						if nHistoryPos == #_tHistory then
							nHistoryPos = nil
						elseif nHistoryPos ~= nil then
							nHistoryPos = nHistoryPos + 1
						end						
					end
					
					if nHistoryPos then
                    	sLine = _tHistory[nHistoryPos]
                    	nPos = string.len( sLine ) 
                    else
						sLine = ""
						nPos = 0
					end
					redraw()
                end
			elseif param == keys.backspace then
				-- Backspace
				if nPos > 0 then
					redraw(" ");
					sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
					nPos = nPos - 1					
					redraw()
				end
			elseif param == keys.home then
				-- Home
				nPos = 0
				redraw()		
			elseif param == keys.delete then
				if nPos < string.len(sLine) then
					redraw(" ");
					sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )				
					redraw()
				end
			elseif param == keys["end"] then
				-- End
				nPos = string.len(sLine)
				redraw()
			end
		end
	end
	
	term.setCursorBlink( false )
	term.setCursorPos( w + 1, sy )
	print()
	
	return sLine
end

local function run( _sCommand, ... )
	local sPath = shell.resolveProgram( _sCommand )
	local args = { ... }
	if sPath ~= nil and not (_sCommand == "shell") and not (_sCommand == "bg") then
		tProgramStack[#tProgramStack + 1] = sPath
   		local result = os.run( tEnv, sPath, ... )
		tProgramStack[#tProgramStack] = nil
		return result
   	elseif (_sCommand == "bg") then
   		if (args[1] ~= nil) then
	   		sPath = shell.resolveProgram( args[1] )
	   		if sPath ~= nil then 
	   			local bgArgs = {}
	   			for x, arg in pairs(args) do
	   				if x ~= 1 then
	   					table.insert(bgArgs, arg)
	   				end
	   			end
	   			local someLayer = term.newLayer(2,{linked=false,showscroll=true,cBar=barColor,cTitle=titleColor,short=sName})
				term.native.clear()
				term.redirect(someLayer)
	   			processes[#processes+1] = coroutine.create(os.run)
	   			active[1] = someLayer.getIndex()
	   			active[2] = #processes
	   			coroutine.yield(processes[1])
	   			coroutine.resume(processes[#processes], tEnv, sPath, bgArgs, args[1])
	   			os.layers.render()
			else
				printError( "No such program" )
				return false
			end
		else
			print( "Usage: bg <program> [args]")
		end
   	else
    	printError( "No such program" )
    	return false
    end
end

local function runLine( _sLine )
	local tWords = {}
	for match in string.gmatch( _sLine, "[^ \t]+" ) do
		table.insert( tWords, match )
	end

	local sCommand = tWords[1]
	if sCommand then
		return run( sCommand, unpack( tWords, 2 ) )
	end
	return false
end

-- Install shell API
function shell.getVersion()
	return "amShell v" .. version
end

function shell.run( ... )
	return runLine( table.concat( { ... }, " " ) )
end

function shell.exit()
    bExit = true
end

function shell.dir()
	return sDir
end

function shell.setDir( _sDir )
	sDir = _sDir
end

function shell.path()
	return sPath
end

function shell.setPath( _sPath )
	sPath = _sPath
end

function shell.resolve( _sPath )
	local sStartChar = string.sub( _sPath, 1, 1 )
	if sStartChar == "/" or sStartChar == "\\" then
		return fs.combine( "", _sPath )
	else
		return fs.combine( sDir, _sPath )
	end
end

function shell.resolveProgram( _sCommand )
	-- Substitute aliases firsts
	if tAliases[ _sCommand ] ~= nil then
		_sCommand = tAliases[ _sCommand ]
	end

    -- If the path is a global path, use it directly
    local sStartChar = string.sub( _sCommand, 1, 1 )
    if sStartChar == "/" or sStartChar == "\\" then
    	local sPath = fs.combine( "", _sCommand )
    	if fs.exists( sPath ) and not fs.isDir( sPath ) then
			return sPath
    	end
		return nil
    end
    
 	-- Otherwise, look on the path variable
    for sPath in string.gmatch(sPath, "[^:]+") do
    	sPath = fs.combine( shell.resolve( sPath ), _sCommand )
    	if fs.exists( sPath ) and not fs.isDir( sPath ) then
			return sPath
    	end
    end
	
	-- Not found
	return nil
end

function shell.programs( _bIncludeHidden )
	local tItems = {}
	
	-- Add programs from the path
    for sPath in string.gmatch(sPath, "[^:]+") do
    	sPath = shell.resolve( sPath )
		if fs.isDir( sPath ) then
			local tList = fs.list( sPath )
			for n,sFile in pairs( tList ) do
				if not fs.isDir( fs.combine( sPath, sFile ) ) and
				   (_bIncludeHidden or string.sub( sFile, 1, 1 ) ~= ".") then
					tItems[ sFile ] = true
				end
			end
		end
    end	

	-- Sort and return
	local tItemList = {}
	for sItem, b in pairs( tItems ) do
		if not (sItem == "shell") then
			table.insert( tItemList, sItem )
		end
	end
	table.sort( tItemList )
	return tItemList
end

function shell.getRunningProgram()
	if #tProgramStack > 0 then
		return tProgramStack[#tProgramStack]
	end
	return nil
end

function shell.setAlias( _sCommand, _sProgram )
	tAliases[ _sCommand ] = _sProgram
end

function shell.clearAlias( _sCommand )
	tAliases[ _sCommand ] = nil
end

function shell.aliases()
	-- Add aliases
	local tCopy = {}
	for sAlias, sCommand in pairs( tAliases ) do
		tCopy[sAlias] = sCommand
	end
	return tCopy
end

local function routines_start(...)
	local args = { ... }
	active[2] = 1
	for x,func in pairs(args) do
		processes[#processes+1] = coroutine.create(func)
	end
    
    local tFilters = {}
    local eventData = {}
    while true do
    	local count = #processes
    	local start = 1

    	if active[1] ~= term.getIndex() then
    		term.redirect(layers[active[1]])
    	end
    	if active[2] ~= 1 then
    		start = 2
    		if coroutine.status(processes[1]) ~= "suspended" then
    			coroutine.yield(processes[1])
    		end
    	end

    	for n=start,count do
    		local r = processes[n]
    		if r then
    			if tFilters[r] == nil or tFilters[r] == eventData[1] or eventData[1] == "terminate" then
	    			local ok, param = coroutine.resume( r, unpack(eventData) )
					if not ok then
						error( tostring(param) )
					else
						tFilters[r] = param
					end
					if coroutine.status( r ) == "dead" then
						processes[n] = nil
					end
				end
    		end
    	end
		for n=1,count do
			if processes[n] == nil then
				if n == 1 then
					return
				end
				table.remove(processes, active[2])
				term.redirect()
				os.layers[active[1]].delete()
				active[1] = term.getIndex()
				active[2] = #processes
				if active[1] == 1 and active[2] ~= 1 then
					active[2] = 1
				end
				break
			end
		end
    	eventData = { os.pullEventRaw() }
    end
end

local reader = function()
	-- Read commands and execute them
	local tCommandHistory = {}
	while not bExit do
		term.setBackgroundColor( bgColour )
		local dir = shell.dir() .. "/"
		if not (dir == "/") then 
			dir = "/" .. dir
		end
		local temp = prompt:gsub("`h", os.getComputerLabel() or os.getComputerID()):gsub("`w", dir)
		core.cWrite(temp)
		term.setTextColour( textColour )

		local sLine = read( nil, tCommandHistory )
		table.insert( tCommandHistory, sLine )
		runLine( sLine )
	end
end

local mouse_click = function()
	while not bExit do
		local event, button, x, y = os.pullEvent("mouse_click")
		local size = {term.getSize()}
		local maxScroll = core.max(term.record.text) - ({term.getSize()})[2]

		if core.debug then
			core.dInfo[2] = {button, x, y}
		end

		if x ~= nil then
			if ((x-1) == size[1]) and button == 1 then
				if y == 2 then
					term.scroll(-1)
				elseif ((y-1) == size[2]) and (term.scrolled < maxScroll) then
					term.scroll(1)
				elseif (term.scrolled >= maxScroll) then
					term.scrolled = maxScroll
				end

				if (maxScroll > 0) and (term.scrolled > maxScroll) then
					term.scrolled = maxScroll
				end
			end
		end
	end
end

local mouse_scroll = function()
	while not bExit do
		local event, direction, x, y = os.pullEvent("mouse_scroll")
		local size = {term.getSize()}
		local maxScroll = core.max(term.record.text) - ({term.getSize()})[2]

		if core.debug then
			core.dInfo[3] = {direction, x, y}
		end

		if direction==-1 then
			term.scroll(-1)
		elseif (term.scrolled < maxScroll) then
			term.scroll(1)
		elseif (term.scrolled >= maxScroll) then
			term.scrolled = maxScroll
		end

		if (maxScroll > 0) and (term.scrolled > maxScroll) then
			term.scrolled = maxScroll
		end
	end
end

local key = function()
	while not bExit do
		local event, key = os.pullEvent("key")
		if key == 62 then
			core.debug = not core.debug
			term.render()
		end
	end
end

local terminating = false
local basePath = "/"
if fs.exists("/disk/am") then
	basePath = "/disk/"
end
local function main()
	

	bExit = false
	----------------------------- Config stuff ---------------------------------------
	local sPath = ".:/rom/programs"
	if turtle then
		sPath = sPath .. ":/rom/programs/turtle"
	else
		sPath = sPath .. ":/rom/programs/computer"
	end
	if http then
		sPath = sPath .. ":/rom/programs/http"
	end
	if term.isColor() then
		sPath = sPath .. ":/rom/programs/color"
	end

	sPath = sPath .. ":" .. basePath .. "am/programs"

	shell.setPath( sPath )
	help.setPath( "/rom/help" )

	shell.setAlias( "ls", "list" )
	shell.setAlias( "dir", "list" )
	shell.setAlias( "cp", "copy" )
	shell.setAlias( "mv", "move" )
	shell.setAlias( "rm", "delete" )

	------------------------------ Initalize Shell -----------------------------------
	os.version = shell.getVersion

	local shellLayer=term.newLayer(1,{linked=true,showscroll=true,cBar=barColor,cTitle=titleColor,title=os.version(),short="shell"})
	term.redirect(shellLayer)
	active[1] = shellLayer.getIndex()

	core.clear()
	term.setBackgroundColor( bgColour )
	term.setTextColour( promptColour )
	term.setTextColour( textColour )

	-- Run any programs passed in as arguments
	if #tArgs > 0 then
		shell.run(tArgs)
	end

	routines_start(reader, mouse_click, mouse_scroll, key)

	-- If this is the toplevel shell, run the shutdown program
	if parentShell == nil then
		if shell.resolveProgram( "shutdown" ) then
			shell.run( "shutdown" )
		end
		os.shutdown() -- just in case
	end
end

function os.pullEvent(_sFilter)
	local event = { os.pullEventRaw(_sFilter) }
	if event[1] == "terminate" then
        if (shell.getRunningProgram() ~= nil) or (parentShell ~= nil) then
		    core.cPrint("&eTerminate Event Found.")
		    error()
		end
	end
	return unpack(event)
end

main()