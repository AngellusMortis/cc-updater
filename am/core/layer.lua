--am/core/layer.lua
version = "1.001"

--branch from Kaos' Layer API: http://pastebin.com/ZPqJFjDy
bWritten=true
local tsym={w=1,o=2,m=4,B=8,y=16,l=32,P=64,g=128,G=256,c=512,p=1024,b=2048,z=4096,q=8192,r=16384,a=32768}
os.layers={render=function()
	term.native.setBackgroundColor(os.layers[core.min(os.layers)].getBackgroundColor())
	term.native.clear()
	local pos={term.native.getCursorPos()}
	local count = 0
	local size= {term.native.getSize()}
	for k,v in pairs(os.layers) do
		if type(v)=="table" then
			v.render()
		end
	end
	for k,v in pairs(os.layers) do
		if type(v)=="table" then
			term.native.setCursorPos(count*8+2, size[2])
			term.native.setBackgroundColor(v.cTabs[(count+1)%table.getn(v.cTabs)])
			term.native.setTextColor(colors.black)
			term.native.write("       ")
			term.native.setCursorPos(count*8+3, size[2])
			term.native.write(v.short)
			count = count+1
		end
	end
	if (core.debug) then
		term.native.setCursorPos(1, size[2])
		term.native.setBackgroundColor(colors.lime)
		term.native.setTextColor(colors.white)
		term.native.write(core.dInfo[1][1]..":"..core.dInfo[1][2].." "..core.dInfo[2][1]..":("..core.dInfo[2][2]..","..core.dInfo[2][3]..") "..core.dInfo[3][1]..":("..core.dInfo[3][2]..","..core.dInfo[3][3]..")    ")
	end
	term.native.setCursorPos(pos[1], pos[2] + 1)
	term.native.setBackgroundColor(colors.black)
	term.native.setTextColor(colors.white)
end,scroll=function(nLines)
	for k,v in pairs(os.layers) do
		if type(v)=="table" and v.linked then
			v.scroll(nLines,true)
		end
	end
end}

term.newLayer=function(index,tParams)
	local redirected=false
	tParams=tParams or {}
	local layer=setmetatable({},{__index=term.native,__type="layer"})
	table.insert(os.layers,index or #os.layers+1,layer)
	layer.active = false
	layer.linked=tParams.linked or false
	layer.showscroll=tParams.showscroll or false
	layer.scrolling=tParams.scrolling or true
	layer.scrolled=layer.linked and term.scrolled or 1
	layer.cBar = tParams.cBar or colors.white
	layer.cTitle = tParams.cTitle or colors.cyan
	layer.title = tParams.title or "unnammed layer"
	layer.short = tParams.short or layer.title
	layer.cTabs = tParams.cTabs or {colors.red,colors.blue,colors.lime}

	local record=setmetatable({text={},tcol={},tback={}},{__call=function(self)
		for k,v in pairs(self) do
			local rem={}
			for row,tLine in pairs(v) do
				local cont=false
				for a,b in pairs(tLine) do
					cont=true
				end
				if not cont then
					table.insert(rem,row)
				end
			end
			for a,b in pairs(rem) do
				v[a]=nil
			end
		end
	end})

	for k,v in pairs(record) do setmetatable(v,{__index=function(self,index) if (tonumber(index) or 1)<=1 then return nil end self[index]={} return self[index] end,__newindex=function(self,index,value) if (tonumber(index) or 1)<=1 then return nil end rawset(self,index,value) end}) end
	layer.record=record
	layer.native={}
	layer.native.getSize=term.native.getSize		

	layer.getSize=function()
		local size={term.native.getSize()}
		return size[1]-(layer.showscroll and 1 or 0),size[2]-2
	end	

	local lX,lY=1,1
	layer.setCursorPos=function(x,y)
		if type(x)=="number" and type(y)=="number" then
			lX=math.floor(x)
			lY=math.floor(y)
			if redirected then
				if lX>0 and lY>0 then
					layer.setCursorBlink(nil,false)
				else
					layer.setCursorBlink(nil,true)
				end
				term.native.setCursorPos(lX,lY)
			end
			return true
		end
		return false
	end	

	layer.getCursorPos=function()
		return lX,lY
	end

	local gcp=layer.getCursorPos
	local tCol=colors.white
	local tCols={}
	for k,v in pairs(colors) do if type(v)=="number" then tCols[v]=k end end
	
	colors.isColor=function(num)
		return tCols[num]~=nil
	end	
	
	layer.setTextColor=function(col)
		if colors.isColor(col) then
			tCol=col
			return true
		end
		return false
	end
	layer.setTextColour=layer.setTextColor
	local tBack=colors.black
	
	layer.setBackgroundColor=function(col)
		if colors.isColor(col) then
			tBack=col
			return true
		end
		return false
	end
	layer.setBackgroundColour=layer.setBackgroundColor
	
	layer.getTextColor=function()
		return tCol
	end
	layer.getTextColour=layer.getTextColor
	
	layer.getBackgroundColor=function()
		return tBack
	end
	layer.getBackgroundColour=layer.getBackgroundColor
	
	layer.clear=function()
		for _,tRec in pairs(record) do
			local t={}
			for index,_ in pairs(tRec) do
				t[index]=true
			end
			for k,v in pairs(t) do
				tRec[k]=nil
			end
		end
		if not layer.linked then
			layer.scrolled=1
		end
		layer.render()
	end	

	layer.clearLine=function()
		for _,tRec in pairs(record) do
			tRec[lY+layer.scrolled]=nil
		end
	end	

	layer.write=function(sText,bScroll,bIndent)
		if lY<1 then return 0 end
		local size={layer.getSize()}
		local pos={gcp()}
		local fPos={layer.getCursorPos()}
		local nLinesPrinted=0
		sText=tostring(sText)
		local tS="w"
		local bS="a"
		for k,v in pairs(tsym) do
			if v==layer.getTextColor() then tS=k end
			if v==layer.getBackgroundColor() then bS=k end
		end
		local function isrt(t,tex,len)
			for x=lX,lX+len-1 do
				t[lY+layer.scrolled][x]=tex:sub(x-lX+1,x-lX+1)
			end
		end
		while #sText~=0 do
			local cPos={layer.getCursorPos()}
			if cPos[1]>size[1] then --goto next line if current cursor is past the end if the screen and refresh current pos
				layer.setCursorPos(bIndent and cPos[1] or 1,cPos[2]+1)
				cPos={layer.getCursorPos()}
			end
			if cPos[2]>size[2] then --if cursor is past the end of the screen then scroll down until that line is the bottom and set cursorpos to be the last line
				layer.scroll(cPos[2]-size[2])
				cPos={cPos[1],size[2]}
				layer.setCursorPos(cPos[1],size[2])
			elseif cPos[2]<1 then
				local offset=math.min(1-cPos[2],layer.scrolled-1)
				layer.scroll(-offset)
				layer.setCursorPos(cPos[1],cPos[2]+offset)
				cPos={cPos[1],cPos[2]+offset}
			end
			local len=math.min(bScroll and size[1]-cPos[1]+1 or #sText,sText:find("\n") or #sText) --get the length of the string to be printed, the length to the end of the line, the length to the next \n or the length of the entire string
			local str=sText:sub(1,len):gsub("\n","") --the actual string to be printed
			isrt(record.text,str,len)
			isrt(record.tcol,string.rep(tS,#str),len)
			isrt(record.tback,string.rep(bS,#str),len)
			sText=sText:sub(len+1)
			nLinesPrinted=nLinesPrinted+1
			if #sText~=0 then
				layer.setCursorPos(bIndent and fPos[1] or 1,cPos[2]+1)
			else
				layer.setCursorPos(((nLinesPrinted==1 or bIndent) and cPos[1] or 1)+len,cPos[2])
			end
		end
		bWritten=true
		--os.layers.render()
		return nLinesPrinted
	end

	layer.getIndex=function()
		for k,v in pairs(os.layers) do
			if layer==v then
				return k
			end
		end
	end	

	layer.render=function(offsetX,offsetY,limX,limY)
		if layer.active then
			local pos={term.native.getCursorPos()}
			local col=term.getTextColor()
			local back=term.getBackgroundColor()
			local size={layer.native.getSize()}
			term.native.setCursorPos(1, 1)
			term.native.setTextColor(layer.cTitle)
			term.native.write(layer.title)
			if core.debug then
				core.dInfo[1] = {layer.scrolled, core.max(term.record.text) - ({term.getSize()})[2]}
			end
			for y,tLine in pairs(record.text) do
				local newy=y+(offsetY or 1)-1
				if newy<=(limY or y) then
					for x=1,math.min(core.max(tLine),({term.native.getSize()})[1]) do
						local newx=x+(offsetX or 1)-1
						if newx<=(limX or x) then
							if tsym[record.tback[y][x]] and newy-layer.scrolled>0 then
								term.native.setCursorPos(newx,newy-layer.scrolled+1)
								term.native.setTextColor(tsym[record.tcol[y][x]])
								term.native.setBackgroundColor(tsym[record.tback[y][x]])
								term.native.write(record.text[y][x])
							end
						end
					end
				end
			end
			if layer.showscroll then
				local barSpace=size[2]-3
				local sizeY=math.max((core.max(layer.record.text)-1),layer.scrolled+size[2]-3)
				local nBarSize=math.max(math.floor(barSpace*(size[2]-2)/sizeY), 1)
				local nBarPos=math.min(math.min(math.ceil((barSpace)*(layer.scrolled-1)/sizeY),barSpace)+2, barSpace)
				for y=1,size[2] do
					term.native.setCursorPos(size[1],y)
					term.native.setBackgroundColor(y>=nBarPos and y<=nBarPos+nBarSize and layer.cBar or colors.black)
					term.native.write(" ")
				end
				term.native.setTextColor(layer.cBar)
				term.native.setBackgroundColor(colors.black)
				term.native.setCursorPos(size[1],2)
				term.native.write("^")
				term.native.setCursorPos(size[1],size[2]-1)
				term.native.write("v")
			end
			term.native.setTextColor(col)
			term.native.setBackgroundColor(back)
			term.native.setCursorPos(1, size[2])
			for x=1,size[1] do
				term.native.write(" ")
			end
			term.native.setTextColor(col)
			term.native.setBackgroundColor(back)
			term.native.setCursorPos(unpack(pos))
		end
	end

	layer.scroll=function(nLines,bFromTop)
		if layer.scrolling then
			if layer.linked and not bFromTop then
				os.layers.scroll(nLines)
			else
				layer.scrolled=layer.scrolled+(tonumber(nLines) or 1)
				if layer.scrolled<1 then
					layer.scrolled=1
				end
			end
			bWritten=true
		end
	end

	layer.delete=function()
		for k,v in pairs(os.layers) do
			if layer==v then
				table.remove(os.layers,k)
				break
			end
		end
		local tIndexes={}
		for k,v in pairs(layer) do
			tIndexes[k]=true
		end
		for k,v in pairs(tIndexes) do
			layer[k]=nil
		end
	end

	layer.getTextAt=function(x,y,len)
		if rawget(record.text,y+layer.scrolled) then
			local str=""
			for cx=x,x+(len or 1)-1 do
				str=str..(record.text[y+layer.scrolled][cx] or " ")
			end
			return str,tsym[record.tcol[y+layer.scrolled][x]],tsym[record.tback[y+layer.scrolled][x]]
		end
		return string.rep(" ",x+(len or 1)-1)
	end

	local scb=term.native.setCursorBlink
	local cb=true
	local disableBlink=false
	layer.setCursorBlink=function(bOn,bDisable)
		if bDisable~=nil then
			disableBlink=bDisable
			if not bDisable then
				scb(cb)
			else
				scb(false)
			end
		else
			cb=bOn
			if not bOn or not disableBlink then
				scb(bOn)
			end
		end
	end

	layer.getCursorBlink=function(bOn,bDisable)
		return cb
	end

	layer.redirect=function()
		layer.active = true
		redirected=true
	end

	layer.restore=function()
		layer.active = false
		redirected=false
	end
	return layer
end

term.newWindow=function(x1,y1,x2,y2,index)
	local window=term.newLayer(index)
	local rd=window.render
	window.render=function()
		return rd(x1,y1,x2,y2)
	end
	local gs=window.getSize
	window.getSize=function()
		return x2-x1,y2-y1
	end
	return window
end

local rd=term.redirect
setfenv(rd,setmetatable({type=nativeType},{__index=getfenv(rd)}))
setmetatable(term,{__index=term.native})
local tRedirectStack={}
term.redirect=function(tRedirectTarget)
	if type(tRedirectTarget)=="table" then
		for k,v in pairs(term.native) do
			if not tRedirectTarget[k] then
				error("cannot redirect. missing function "..k,2)
			end
		end
		getmetatable(term).__index=tRedirectTarget
		if tRedirectTarget.redirect and type(tRedirectTarget.redirect)=="function" then
			tRedirectTarget.redirect()
		end
		rd(tRedirectTarget)
		if #tRedirectStack>=1 and type(tRedirectStack[1].restore)=="function" then
			tRedirectStack[1].restore()
		end
		table.insert(tRedirectStack,1,tRedirectTarget)
	end
end

local rstre=term.restore
term.restore=function()
	if #tRedirectStack>1 then
		rstre()
		if tRedirectStack[1].restore then tRedirectStack[1].restore() end
		table.remove(tRedirectStack,1)
		getmetatable(term).__index=tRedirectStack[1]
		if tRedirectStack[1].redirect and type(tRedirectStack[1].redirect)=="function" then
			tRedirectStack[1].redirect()
		end
	end
end

local yld=coroutine.yield
coroutine.yield=function(...)
	if bWritten then
		os.layers.render()
		bWritten=false
	end
	return yld(...)
end
