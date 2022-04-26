local basePath = settings.get("ghu.base")
local ghu = require(basePath .. "core/apis/ghu")

local function printValue(name)
    local value = settings.get(ghu.s[name].name)
    if name == "extraRepos" then
        print(#value .. " Extra Repo(s):")
        for i, repo in ipairs(value) do
            print(i .. ": " .. repo)
        end
    else
        print(value)
    end
end

local function printUsage(op)
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    local usage = " <list|get|set|add|remove> [name] [value]"

    if op == "list" then
        usage = " list"
    elseif op == "get" then
        usage = " get <name>"
    elseif op == "set" then
        usage = " set <name> <value>"
    elseif op == "add" then
        usage = " add <name> <value>"
    elseif op == "remove" then
        usage = " remove <name> <value>"
    end

    print("Usage: " .. programName .. usage)
end


local function main(op, settingName, value)
    if op == nil then
        printUsage()
        return
    end

    if op == "list" then
        print(#(ghu.s) .. " Settings:")
        for key, _ in pairs(ghu.s) do
            print(key)
        end
        return
    end

    if settingName == nil then
        printUsage(op)
        return
    end
    if (ghu.s[settingName] == nil) then
        printError("Unexpected setting name: " .. settingName)
        return
    end

    if op == "get" then
        printValue(settingName)
        return
    end

    if value == nil then
        printUsage(op)
        return
    end

    if op == "set" then
        if settingName == "extraRepos" then
            value = ghu.split(value)
        elseif settingName == "autoUpdate" then
            value = ghu.strBool(value)
        end

        settings.set(ghu.s[settingName].name, value)
        settings.save()
        printValue(settingName)
        return
    end

    if op == "add" or op == "remove" then
        if settingName ~= "extraRepos" then
            printError("Only supported on extraRepos setting")
            return
        end

        settingValue = settings.get(ghu.s[settingName].name)
        if op == "add" then
            settingValue[#settingValue+1] = value
        else
            for i=#settingValue, 1, -1 do
                if settingValue[i] == value then
                    table.remove(settingValue, i)
                    break
                end
            end
        end
        settings.set(ghu.s[settingName].name, settingValue)
        settings.save()
        printValue(settingName)
    end
end

main(arg[1], arg[2], arg[3])
