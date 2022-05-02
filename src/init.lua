if _G.ghuStartupRan then
    return
end

local completion = require("cc.shell.completion")

local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")

if ghu.s.autoUpdate.get() then
    shell.run("ghuupdate")
end

if ghu.s.autoRun.get() then
    for _, autorun in ipairs(ghu.getAutoruns()) do
        shell.run(autorun)
    end
end

local settingNames = {}
local tableSettingNames = {}
local tableSettingLookup = {}
for key, _ in pairs(ghu.s) do
    settingNames[#settingNames + 1] = key
    if ghu.s[key].type == "table" then
        tableSettingNames[#tableSettingNames + 1] = key
        tableSettingLookup[key] = true
    end
end

local shellBase = string.sub(ghu.p.core, 2)
local compSettings = function(shell, text, previous)
    if previous[2] == "list" then
        return nil
    end

    if previous[2] == "add" or previous[2] == "remove" then
        return completion.choice(shell, text, previous, tableSettingNames, true)
    end
    return completion.choice(shell, text, previous, settingNames, previous[2] ~= "get")
end

local compValue = function(shell, text, previous)
    if previous[2] ~= "set" and previous[2] ~= "remove" then
        return nil
    end

    if previous[2] == "remove" then
        if not tableSettingLookup[previous[3]] then
            return nil
        end
        return completion.choice(shell, text, previous, ghu.s[previous[3]].get(), false)
    end

    local choices = {"default"}
    if ghu.s[previous[3]].type == "boolean" then
        choices = {"default", "true", "false"}
    elseif previous[3] == "base" then
        return completion.dir(shell, text)
    end
    return completion.choice(shell, text, previous, choices, false)
end
shell.setCompletionFunction(
    shellBase .. "programs/ghuconf.lua",
    completion.build(
        { completion.choice, { "list", "help ", "get ", "set ", "add ", "remove " }, false},
        compSettings,
        compValue
    )
)

_G.ghuStartupRan = true
