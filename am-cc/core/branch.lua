--[[
##name: ]]--
program_name = "am-cc Branch"
--[[
##file: am-cc/core/branch.lua
##version: ]]--
program_version = "3.7.0.0"
--[[

##type: core
##desc: Shared code for branch mining program (see am-cc/programs/turtle/branch.lua)

##images:

##detailed:

##planned:

##issues:

##parameters:

--]]

log_file = ".branch.log"

settings_file = ".branch.settings"
settings = nil

progress_file = ".branch.progress"
progress = nil

-- used for testing for ores (anything not in this list is considered an "ore")
-- by default should be cobblestone, dirt, stone, and gravel
test_slots = {}

-- variable to hold wireless modem
transmitter = nil

-- random variables
ids_line = 1

-- error messages
has_error = false
message_press_enter = "Press ENTER to continue..."
message_error_clear = "__clear"
message_error_file = "File could not be opened"
message_error_move = "Cannot move"
message_error_dig = "Cannot dig"
message_error_fuel = "Out of fuel"
message_error_chest = "Out of chests"
message_error_no_chest = "No chest to put items in"
message_error_torch = "Out of torches"
message_error_cobble = "Not enough cobblestone"
message_error_modem = "No modem connected"
message_error_modem_side = nil -- see init_settings
message_error_modem_wireless = "Modem cannot do wireless"
message_error_failed_to_place_chest = "Could not place chest"
message_error_failed_to_place_torch = "Could not place torch"
message_error_failed_to_place_torch_wall = "Could not place wall for torch"
message_error_failed_to_send_message = "Failed to send message"
message_error_display_width = "Display is not wide enough"
message_error_display_height = "Display is not tall enough"
message_error_trunk = "trunk_height must be 2 or 3"
message_error_liquids = "Encountered liquids"


-- function prototypes (only as needed)
print_error = nil
log = nil
init_settings = nil
read_settings = nil
write_settings = nil
init_progress = nil
read_progress = nil
write_progress = nil
update_progress = nil

-- functions
-- need this function for bools
function setting_or_default(setting_value, default)
    if (settings[setting_value] == nil) then
        return default
    end
    return settings[setting_value]
end
-- init settings variable
init_settings = function()
    read_settings()

    settings = settings or {}

    -- debug settings
    settings["debug"] = setting_or_default("debug", false)

    -- mine config
    settings["use_coal"] = setting_or_default("use_coal", false)
    settings["number_of_branches"] = settings["number_of_branches"] or 5
    settings["branch_between_distance"] = settings["branch_between_distance"] or 2
    settings["branch_length"] = settings["branch_length"] or 52
    settings["torch_distance"] = settings["torch_distance"] or 10
    settings["branch_connector_distance"] = settings["branch_connector_distance"] or 26
    settings["trunk_width"] = settings["trunk_width"] or 2
    settings["trunk_height"] = settings["trunk_height"] or 3

    -- turtle(slots) config
    -- chest and torch slots are to keep track of supplies
    settings["torch_slot"] = settings["torch_slot"] or 1
    settings["chest_slot"] = settings["chest_slot"] or 2
    -- cobblestone slot use to place so torch can be placed
    settings["cobblestone_slot"] = settings["cobblestone_slot"] or 3

    -- level of coal to reach when refueling
    settings["min_continue_fuel_level"] = settings["min_continue_fuel_level"] or 500
    -- ticks between attempts to move (see force_forward, force_up, and force_down)
    settings["tick_delay"] = settings["tick_delay"] or 2

    -- wireless broadcast settings
    -- do broadcast
    -- on receiver will determine wether or not to retransmit (range extension)
    settings["transmit_progress"] = setting_or_default("transmit_progress", true)
    -- if you have multiple modems (wired and wireless), set this to force
    --  side of modem if perhiperal.find() is picking the wired one
    settings["transmitter_side"] = setting_or_default("transmitter_side", nil)
    -- should not need to change these
    settings["transmit_channel"] = settings["transmit_channel"] or 60000
    settings["receive_channel"] = settings["receive_channel"] or 60001

    -- attempt to redirect to monitor for receiver?
    --  side monitor if perhiperal.find() is picking an undesired one (works with networked monitors)
    settings["redirect_to_monitor"] = setting_or_default("redirect_to_monitor", true)
    settings["monitor_side"] = setting_or_default("monitor_side", nil)

    --save/load functionaility
    -- WIP, do NOT use
    settings["allow_resume"] = setting_or_default("allow_resume", false)

    -- multitask stuff
    settings["do_multitask"] = setting_or_default("do_multitask", not (shell.openTab == nil))

    write_settings()

    message_error_modem_side = "No modem connected ("..tostring(settings["transmitter_side"])..")"
end
-- writes current progress to progress file
write_settings = function()
    temp_seralized = textutils.serialize(settings)
    handle = fs.open(settings_file, "w")

    if (handle == nil) then
        print_error(message_error_file, true)
    else
        handle.write(temp_seralized)
        handle.close()
    end
    temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
    log("write: settings: "..temp_seralized)
end
-- reads progress from progress file
read_settings = function()
    handle = fs.open(settings_file, "r")

    if not (handle == nil) then
        temp_seralized = handle.readAll()
        if (string.len(temp_seralized) > 5) then
            settings = textutils.unserialize(temp_seralized)
            temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
            log("read: settings: "..temp_seralized)
            handle.close()
        end
    end
end
-- init progress variable
init_progress = function()
    if not (turtle == nil) then
        read_progress()
    end
    if (progress == nil) then
        progress = {}
        progress["task"] = nil
        progress["position"] = {{0, 0, 0}, 2}
        progress["branch"] = {}
        progress["branch"]["current"] = 1
        progress["branch"]["progress"] = nil
        progress["branch"]["side"] = nil
        progress["branch"]["height"] = 1
        progress["trunk"] = {}
        progress["trunk"]["remaining"] = nil
        if (turtle == nil) then
            progress["paired_id"] = nil
            progress["retransmit_id"] = nil
        end
    end

    if (settings["allow_resume"]) then
        write_progress()
    end
end
-- writes current progress to progress file
write_progress = function()
    temp_seralized = textutils.serialize(progress)
    handle = fs.open(progress_file, "w")

    if (handle == nil) then
        print_error(message_error_file, true)
    else
        handle.write(temp_seralized)
        handle.close()
    end
    temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
    log("write: progress: "..temp_seralized)
end
-- reads progress from progress file
read_progress = function()
    handle = fs.open(progress_file, "r")

    if not (handle == nil) then
        temp_seralized = handle.readAll()
        if (string.len(temp_seralized) > 5) then
            progress = textutils.unserialize(temp_seralized)
            temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
            log("read: progress: "..temp_seralized)
            handle.close()
        end
    end
end
-- updates value in progress variable (DO NOT DO IT MANUALLY)
update_progress = function(progress_item, new_value, index_1, index_2)
    log("update: "..tostring(progress_item).."["..tostring(index_1).."]["..tostring(index_2).."] "..tostring(new_value))
    if (progress_item == "position") and (index_2 == nil) then
        progress[progress_item][index_1] = new_value
    elseif (progress_item == "position") then
        progress[progress_item][index_1][index_2] = new_value
    elseif (progress_item == "branch") then
        progress[progress_item][index_1] = new_value
    else
        progress[progress_item] = new_value
    end
    if not (turtle == nil) and (settings["allow_resume"]) then
        write_progress()
    end
end
-- if debug, logs message to file
log = function(message)
    if (settings["debug"]) then
        handle = nil
        if (fs.exists(log_file)) then
            handle = fs.open(log_file, "a")
        else
            handle = fs.open(log_file, "w")
        end
        if (handle == nil) then
            settings["debug"] = false
            print_error(message_error_file)
        else
            handle.writeLine("["..tostring(os.time()).."]: "..tostring(message))
            handle.close()
        end
    end
end
-- send message to receiver
local function send_message(message_type, message_data)
    message_data = message_data or {}
    if (message_data["turtle_id"] == nil) and not (turtle == nil) then
        message_data["turtle_id"] = os.computerID()
    elseif (message_data["turtle_id"] == nil) then
        message_data["turtle_id"] = progress["paired_id"]
    end
    if (message_data["type"] == nil) then
        message_data["type"] = message_type
    end
    if (turtle == nil) then
        message_data["retransmit_id"] = os.computerID()
    end

    if (message_data["type"] == nil) or (message_data["turtle_id"] == nil) then
        temp_seralized = string.gsub(textutils.serialize(message_data), "[\n ]", "")
        log("send: "..temp_seralized)
        print_error(message_error_failed_to_send_message, false, false)
        return
    end
    temp_seralized = string.gsub(textutils.serialize(message_data), "[\n ]", "")
    log("send: "..temp_seralized)
    transmitter.transmit(settings["transmit_channel"], settings["receive_channel"], textutils.serialize(message_data))

    if (message_type == "check") or (message_type == "branch_update") then
        os.startTimer(3)
        local do_loop = true
        -- open channel for listening
        if (turtle == nil) then
            transmitter.close(settings["transmit_channel"])
        end
        transmitter.open(settings["receive_channel"])
        while (do_loop) do
            local event, modemSide, senderChannel,
                replyChannel, message, senderDistance = os.pullEvent()

            temp_seralized = string.gsub(tostring(message), "[\n ]", "")
            log("pull: "..event..": "..temp_seralized)
            if (event == "modem_message") then
                message_data = textutils.unserialize(message)

                -- confrim event
                if (message_data["type"] == "confrim") and
                  ((not (turtle == nil) and (message_data["turtle_id"] == os.computerID())) or
                   ((turtle == nil) and (message_data["turtle_id"] == progress["paired_id"]) and (message_data["retransmit_id"] == os.computerID()))) then
                    do_loop = false
                end
            elseif (event == "timer") then
                log("timer")
                do_loop = false
                message_data = {}
                message_data["number_of_branches"] = settings["number_of_branches"]
                message_data["branch"] = progress["branch"]["current"]
                send_message("start", message_data)
            end
        end
        transmitter.close(settings["receive_channel"])
        if (turtle == nil) then
            transmitter.open(settings["transmit_channel"])
        end
    end
end
-- Force clears the current terminal line and then
--  sets it to first positions (was having trouble with term.clearLine())
local function clear_line()
    pos = {term.getCursorPos()}
    term_size = {term.getSize()}
    term.setCursorPos(1, pos[2])
    term.write(string.rep(" ",term_size[1]))
    term.setCursorPos(1, pos[2])
end
-- used by receiver to confrim request
local function send_confrim(id)
    local confrim_data = {}
    confrim_data["type"] = "confrim"
    confrim_data["turtle_id"] = id
    if not (progress["retransmit_id"] == nil) then
        confrim_data["retransmit_id"] = progress["retransmit_id"]
    end
    temp_seralized = string.gsub(textutils.serialize(confrim_data), "[\n ]", "")
    log("confrim: "..temp_seralized)
    transmitter.transmit(settings["receive_channel"], settings["transmit_channel"], textutils.serialize(confrim_data))
end
-- writes text in color, if display supports color
local function color_write(text, color)
    if (term.isColor()) then
        term.setTextColor(color)
    end
    term.write(text)
    if (term.isColor()) then
        term.setTextColor(colors.white)
    end
end
-- prints message_press_enter on last line and waits for user to press ENTER
local function wait_for_enter()
    term_size = {term.getSize()}
    term.setCursorPos(1, (term_size[2]-1))
    clear_line()
    print(message_press_enter)
    repeat
        event, param1 = os.pullEvent("key")
    until param1 == 28
    term.setCursorPos(1, (term_size[2]-1))
    clear_line()
end
-- prints error on second to last line and then waits for ENTER
--  if fatal is set to true, terminates program instead with error message
print_error = function (error_message, fatal, wait)
    fatal = fatal or false
    if (turtle == nil) and (wait == nil) then
        wait = false
    elseif (wait == nil) then
        wait = true
    end
    local prefix = "ERROR"
    if (wait == false) then
        prefix = "WARN"
    end
    log(prefix..": "..error_message.." ["..tostring(fatal).."]["..tostring(wait).."]")

    -- if turtle and transmit is on, send to receiver
    if (not (turtle == nil)) and (settings["transmit_progress"]) then
        local error_data = {}
        error_data["error"] = error_message
        error_data["wait"] = wait
        send_message("error", error_data)
    end

    -- if fatal, terminate
    if (fatal) then
        error(error_message)
    else
        has_error = true
        term_size = {term.getSize()}
        term.setCursorPos(1, (term_size[2]-2))
        clear_line()
        color_write(prefix..": "..error_message, colors.red)
        -- if turtle, wait for user to press ENTER
        if not (turtle == nil) then
            if (wait) then
                wait_for_enter()
                term.setCursorPos(1, (term_size[2]-2))
                clear_line()
                has_error = false
            end
            -- if transmit, tell receiver error has been cleared
            if (settings["transmit_progress"]) then
                local error_data = {}
                error_data["error"] = message_error_clear
                send_message("error", error_data)
            end
        else
            if (wait) then
                wait_for_enter()
                term.setCursorPos(1, (term_size[2]-2))
                clear_line()
            end
        end
    end
end
-- set current task for turtle (just for visual)
local function set_task(main, sub)
    update_progress("task", main)
    log("task: "..main.." "..sub)
    term_size = {term.getSize()}
    term.setCursorPos(1,ids_line+4)
    clear_line()
    color_write(main, colors.cyan)
    term.setCursorPos(term_size[1]-((#sub)-1),ids_line+4)
    color_write(sub, colors.yellow)

    -- if turtle and transmit, send task data to receivers
    if (not (turtle == nil)) and (settings["transmit_progress"]) then
        local send_data = {}
        send_data["main"] = main
        send_data["sub"] = sub
        send_message("task", send_data)
    end
end

init_settings()