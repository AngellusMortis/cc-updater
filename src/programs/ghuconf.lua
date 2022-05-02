local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.core")

local function printValue(name)
    local value = ghu.s[name].get()
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
    local usage = " <list|get|help|set|add|remove> [name] [value]"

    if op == "list" then
        usage = " list"
    elseif op == "get" then
        usage = " get <name>"
    elseif op == "help" then
        usage = " help <name>"
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
    elseif op == "help" then
        print(ghu.s[settingName].description)
        return
    end

    if value == nil then
        printUsage(op)
        return
    end

    if op == "set" then
        if value == "default" then
            value = core.copy(ghu.s[settingName].default)
        elseif ghu.s[settingName].type == "table" then
            value = core.split(value)
        elseif ghu.s[settingName].type == "boolean" then
            value = core.strBool(value)
        end

        ghu.s[settingName].set(value)
        printValue(settingName)
        return
    end

    if op == "add" or op == "remove" then
        if ghu.s[settingName].type ~= "table" then
            printError("Only supported on table settings")
            return
        end

        settingValue = ghu.s[settingName].get()
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
        ghu.s[settingName].set(settingValue)
        printValue(settingName)
    end
end

main(arg[1], arg[2], arg[3])
