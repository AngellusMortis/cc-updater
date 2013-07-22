--amShell/am/core/core.lua
local version = "3.020"

url = "http://tundrasofangmar.net/"

function max(tPar) --find the highest numeric index
  local count=0
  for k,v in pairs(tPar) do
    if (tonumber(k) or 0)>(tonumber(count) or 0) then count=k end
  end
  return count
end

function min(tPar) --find the lowest numeric index
  local count=1/0
  for k,v in pairs(tPar) do
    count=math.min(tonumber(k) or count,count)
  end
  return count
end

function sc(x, y, termObj)
  termObj = termObj or term
  termObj.setCursorPos(x, y)
end

function clear(move, termObj)
	termObj = termObj or term
  sb(colors.black)
  termObj.clear()
  if move ~= false then sc(1,1) end
end

function sb(color, termObj)
	termObj = termObj or term
  termObj.setBackgroundColor(color) 
end

function st(color, termObj)
  termObj = termObj or term
  termObj.setTextColor(color)
end

function cCode(h, termObj)
  termObj = termObj or term
	if termObj.isColor() and termObj.isColor then
		return 2 ^ (tonumber(h, 16) or 0)
	else
		if h == "f" then
			return colors.black
		else
			return colors.white
		end
	end
end

function toCode(n)
	return string.format('%x', n)
end

function cWrite(text, termObj)
  termObj = termObj or term
	text = tostring(text)
	
	local i = 0
    while true  do
		i = i + 1
		if i > #text then break end
		
        local c = text:sub(i, i)

		if c == "\\" then
            if text:sub(i+1, i+1) == "&" then
                termObj.write("&")
                i = i + 1
            elseif text:sub(i+1, i+1) == "$" then
                termObj.write("$")
                i = i + 1
			else
				termObj.write(c)
            end
        elseif c == "&" then
            st(cCode(text:sub(i+1, i+1)))
            i = i + 1
        elseif c == "$" then
            sb(cCode(text:sub(i+1, i+1)))
            i = i + 1
        else
            termObj.write(c)
        end
    end
	
	return
end

function cPrint(text)
  if not (text == nil) then
    cWrite(tostring(text))
  end
	print()
end

function error(message, errorColor, termObj)
  termObj = termObj or term
	if errorColor == nil then
		errorColor = "f"
	end
	if termObj.isColor() then
		termObj.setTextColor()
	end

	cPrint("&" .. errorColor .. "Error: &1" .. message)
end

function tPrint (tt, indent, done, termObj)
  termObj = termObj or term
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write("(\n");
        tPrint (value, indent + 1, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    io.write(tt .. "\n")
  end
end

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function intString(num)
	return string.format("%i", num)
end

function getSideOfPeripheral(type)
    local sides = {"top", "bottom", "left", "right", "back", "front"}
    local i = 1
    repeat
        if (peripheral.getType(sides[i]) == type) then
            return sides[i]
        end
        i = i + 1
    until i == 7
    return nil
end

function listPeripherals()
	local sides = {"top", "bottom", "left", "right", "back", "front"}
    local i = 1
    repeat
    	local side = peripheral.getType(sides[i])
        if (side) then
            print(sides[i] .. ": \"" .. side .. "\"")
        end
        i = i + 1
    until i == 7
    return nil
end

function getFileList(path)
    math.randomseed(os.time() * 1024 % 46)
	local response = http.get(url .. path .."/?random=" .. math.random(1, 1000000))
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

debug = false
dInfo = {{1,1},{1,1,1},{1,1,1}}