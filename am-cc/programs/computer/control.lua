assert(not (core == nil))
local self = {
    --[[
    ##name: ]]--
    name = "Base Controller",
    --[[
    ##file:
    am-cc/programs/computer/control
    ##version: ]]--
    version = "0.1.0.0",
    --[[

    ##type:
    program
    ##desc:
    Base monitor/controller program

    ##detailed:
    Controllers farms, power generation and reports back on all of it

    ##images:
    None

    ##planned:
    None

    ##issues:
    None

    ##parameters:
    None

    ##usage:
    cmd: monitor

    --]]

    -- hardcoded default settings
    settings_file = core.settings_base.."/monitor",
    log_file = core.log_base.."/monitor",

    default_settings = {
        display_data = true
    },

    settings = nil
}

local main = function()
    core.init_settings(branch)
    echo 'success'
end

main()
