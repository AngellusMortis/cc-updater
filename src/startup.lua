local completion = require("cc.shell.completion")
local root = "/"
if fs.exists("/disk/ghu") then
    root = "/disk/"
end
local ghu = require(root .. "ghu/core/apis/ghu")
ghu.initShellPaths()

if ghu.autoUpdate then
    shell.run("ghuupdate")
end

if ghu.autoRun then
    for _, autorun in ipairs(ghu.getAutoruns()) do
        shell.run(autorun)
    end
end

local shellBase = string.sub(ghu.base .. "core/", 2)
local compSettings = function(shell, text, previous)
    if previous[2] == "list" then
        return nil
    end

    local ghuSettings = {}
    for key, _ in pairs(ghu.s) do
        ghuSettings[#ghuSettings + 1] = key
    end
    local addSpace = true
    if previous[2] == "get" then
        addSpace = false
    elseif previous[2] == "add" or previous[2] == "remove" then
        ghuSettings = {"extraRepos"}
    end
    return completion.choice(shell, text, previous, ghuSettings, addSpace)
end
local compValue = function(shell, text, previous)
    if previous[2] ~= "set" and previous[2] ~= "remove" then
        return nil
    end

    if previous[2] == "remove" then
        if previous[3] ~= "extraRepos" then
            return nil
        end
        return completion.choice(shell, text, previous, ghu.extraRepos, false)
    end

    local choices = {"default"}
    if previous[3] == "autoUpdate" or previous[3] == "autoRun" then
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
