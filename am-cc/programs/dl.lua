--[[
##name: ]]--
name = "downloader"
--[[
##file:
am-cc/programs/dl
##version: ]]--
version = "1.0.0.0"
--[[

##type:
program
##desc:
downloads file

##detailed:
downloads file from URL or pastebin

##images:
None

##planned:
None

##issues:
None

##parameters:
None

##usage:
dl <pastebin-or-url>

--]]

local args = { ... }
local path = '.tmp_dl'
local dest = ''

if (fs.exists(path)) then
    fs.delete(path)
end

if (args[1]:find('http') == nil) then
    shell.run('pastebin', 'get', args[1], path)
else
    r = http.get(args[1])
    f = fs.open(path, 'w')
    f.write(r.readAll())
    f.close()
end

f = fs.open(path, 'r')
local line = f.readLine()
while (dest == '' and not (line == nil)) do
    if (not (line:find('##file') == nil)) then
        line = f.readLine()
        dest = (line:gsub('^%s*(.-)%s*$', '%1'))
    end
    line = f.readLine()
end

if (not (dest == '')) then
    if (fs.exists(dest)) then
        fs.delete(dest)
    end
    fs.move(path, dest)
else
    print('could not download file\n')
end

if (fs.exists(path)) then
    fs.delete(path)
end