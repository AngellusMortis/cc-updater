local self = {
    --[[
    ##name: ]]--
    name = "Startup",
    --[[
    ##file:
    startup.lua
    ##version: ]]--
    version = "1.0.1.0"
    --[[

    ##type:
    startup
    ##desc:
    startup program

    ##detailed:
    Sets up the path variables and everything else nessecary, including checking
    for updates if settings allow for it.

    ##images:
    None

    ##planned:
    - Make loading screen nicer

    ##issues:
    - Does not handle errors in updater

    ##parameters:
    None

    ##usage:
    None (autoruns on boot)

    --]]
}

local base_path = "/"

if (fs.exists("/disk/am-cc")) then
    base_path = "/disk/"
end

local main = function()
    assert(os.loadAPI("am-cc/core/core"))

    -- some fun text
    term.clear()
    core.text.print_title(self)

    -- "Finding Gnomes" (path)
    term.setCursorPos(1, 3)
    core.text.color_write("Finding Gnomes.", colors.cyan)
    for i=1,5 do
        os.sleep(0.20)
        core.text.color_write(".", colors.cyan)
    end
    core.text.color_write("done :D", colors.cyan)

    local new_path = shell.path()..":"..base_path.."am-cc/programs"

    if (turtle == nil) then
        new_path = new_path..":"..base_path.."am-cc/programs/computer"
    else
        new_path = new_path..":"..base_path.."am-cc/programs/turtle"
    end

    shell.setPath(new_path)

    -- "Updating Gnomes" (update)
    term.setCursorPos(1, 5)
    core.text.color_write("Updating Gnomes.", colors.cyan)

    local loop = function()
        local start_time = os.time()
        for i=1,5 do
            local temp = 1
            os.sleep(0.20)
            term.setCursorPos(16+i, 5)
            core.text.color_write(".", colors.cyan)
        end
    end
    local update = function()
        shell.run("update", "4", "6")
        term.setCursorPos(22, 5)
    end

    if (core.settings["update_on_boot"]) then
        parallel.waitForAll(loop, update)
        core.text.color_write("done :D", colors.cyan)
    else
        loop()
        core.text.color_write("skipping :(", colors.cyan)
    end

    os.sleep(1.5)

    -- top line
    term.clear()
    core.text.print_title(core)
end

main()