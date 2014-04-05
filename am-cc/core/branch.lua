assert(not (core == nil))
--[[
##name: ]]--
name = "Branch"
--[[
##file: am-cc/core/branch.lua
##version: ]]--
version = "3.7.1.0"
--[[

##type: core
##desc: Shared code for branch mining program (see am-cc/programs/turtle/branch.lua)

##detailed:

##images:

##planned:

##issues:

##parameters:

--]]

-- hardcoded default settings
settings_file = core.settings_base.."/branch"
log_file = core.log_base.."/branch"
progress_file = ".branch.progress"

default_settings = {
    -- mine config
    -- Use collected coal as fuel
    use_coal = false,
    -- Number of branches
    number_of_branches = 5,
    -- Number of blocks between each branch
    branch_between_distance = 3,
    -- Length of branch in blocks
    branch_length = 52,
    -- distance between torches
    torch_distance = 10,
    -- Number of blocks between connections between branches
    branch_connector_distance = 26,
    trunk_width = 2,
    trunk_height = 3,

    -- turtle(slots) config
    -- chest and torch slots are to keep track of supplies
    torch_slot = 1,
    chest_slot = 2,
    -- cobblestone slot use to place so torch can be placed
    cobblestone_slot = 3,

    -- level of coal to reach when refueling
    min_continue_fuel_level = 500,
    -- ticks between attempts to move (see force_forward, force_up, and force_down)
    tick_delay = 2,

    -- wireless broadcast settings
    -- do broadcast
    -- on receiver will determine wether or not to retransmit (range extension)
    transmit_progress = true,
    -- if you have multiple modems (wired and wireless), set this to force
    --  side of modem if perhiperal.find() is picking the wired one
    transmitter_side = nil,
    -- should not need to change these
    transmit_channel = 60000,
    receive_channel = 60001,

    -- attempt to redirect to monitor for receiver?
    --  side monitor if perhiperal.find() is picking an undesired one (works with networked monitors)
    redirect_to_monitor = true,
    monitor_side = nil,

    --save/load functionaility
    -- WIP, do NOT use
    allow_resume = false,

    -- multitask stuff
    do_multitask = (not (term.isColor == nil))
}

settings = nil
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
strings = {
    errors = {
        move = "Cannot move",
        dig = "Cannot dig",
        fuel = "Out of fuel",
        chest = "Out of chests",
        no_chest = "No chest to put items in",
        torch = "Out of torches",
        cobble = "Not enough cobblestone",
        modem = "No modem connected",
        modem_side = "No modem connected on (%s)",
        modem_wireless = "Modem cannot do wireless",
        failed_to_place_chest = "Could not place chest",
        failed_to_place_torch = "Could not place torch",
        failed_to_place_torch_wall = "Could not place wall for torch",
        failed_to_send_message = "Failed to send message",
        trunk = "trunk_height must be 2 or 3",
        liquids = "Encountered liquids"
    }
}

-- function prototypes
init_progress = nil
write_progress = nil
read_progress = nil
update_progress = nil
send_message = nil
send_confrim = nil
set_task = nil

-- init progress variable
init_progress = function()
    if not (turtle == nil) then
        branch.read_progress()
    end
    if (branch.progress == nil) then
        branch.progress = {}
        branch.progress["task"] = nil
        branch.progress["position"] = {{0, 0, 0}, 2}
        branch.progress["branch"] = {}
        branch.progress["branch"]["current"] = 1
        branch.progress["branch"]["progress"] = nil
        branch.progress["branch"]["side"] = nil
        branch.progress["branch"]["height"] = 1
        branch.progress["trunk"] = {}
        branch.progress["trunk"]["remaining"] = nil
        if (turtle == nil) then
            branch.progress["paired_id"] = nil
            branch.progress["retransmit_id"] = nil
        end
    end

    if (branch.settings["allow_resume"]) then
        branch.write_progress()
    end
end
-- writes current progress to progress file
write_progress = function()
    temp_seralized = textutils.serialize(branch.progress)
    handle = fs.open(core.base_path..branch.progress_file, "w")

    if (handle == nil) then
        core.text.print_error(branch, core.strings.levels.error, core.strings.errors.file, true)
    else
        handle.write(temp_seralized)
        handle.close()
    end
    temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
    core.log(branch, core.strings.levels.info, "write: progress: "..temp_seralized)
end
-- reads progress from progress file
read_progress = function()
    handle = fs.open(core.base_path..branch.progress_file, "r")

    if not (handle == nil) then
        temp_seralized = handle.readAll()
        if (string.len(temp_seralized) > 5) then
            branch.progress = textutils.unserialize(temp_seralized)
            temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
            core.log(branch, core.strings.levels.info, "read: progress: "..temp_seralized)
            handle.close()
        end
    end
end
-- updates value in progress variable (DO NOT DO IT MANUALLY)
update_progress = function(progress_item, new_value, index_1, index_2)
    core.log(branch, core.strings.levels.info, "update: "..tostring(progress_item).."["..tostring(index_1).."]["..tostring(index_2).."] "..tostring(new_value))
    if (progress_item == "position") and (index_2 == nil) then
        branch.progress[progress_item][index_1] = new_value
    elseif (progress_item == "position") then
        branch.progress[progress_item][index_1][index_2] = new_value
    elseif (progress_item == "branch") then
        branch.progress[progress_item][index_1] = new_value
    else
        branch.progress[progress_item] = new_value
    end
    if not (turtle == nil) and (branch.settings["allow_resume"]) then
        branch.write_progress()
    end
end
-- send message to receiver
send_message = function(message_type, message_data)
    message_data = message_data or {}
    if (message_data["turtle_id"] == nil) and not (turtle == nil) then
        message_data["turtle_id"] = os.computerID()
    elseif (message_data["turtle_id"] == nil) then
        message_data["turtle_id"] = branch.progress["paired_id"]
    end
    if (message_data["type"] == nil) then
        message_data["type"] = message_type
    end
    if (turtle == nil) then
        message_data["retransmit_id"] = os.computerID()
    end

    if (message_data["type"] == nil) or (message_data["turtle_id"] == nil) then
        temp_seralized = string.gsub(textutils.serialize(message_data), "[\n ]", "")
        core.log(branch, core.strings.levels.info, "send: "..temp_seralized)
        core.text.print_error(branch, core.strings.levels.warn, branch.strings.errors.failed_to_send_message, false, false)
        return
    end
    temp_seralized = string.gsub(textutils.serialize(message_data), "[\n ]", "")
    core.log(branch, core.strings.levels.debug, "send: "..temp_seralized)
    branch.transmitter.transmit(branch.settings["transmit_channel"], branch.settings["receive_channel"], textutils.serialize(message_data))

    if (message_type == "check") or (message_type == "branch_update") then
        os.startTimer(3)
        local do_loop = true
        -- open channel for listening
        if (turtle == nil) then
            branch.transmitter.close(branch.settings["transmit_channel"])
        end
        branch.transmitter.open(branch.settings["receive_channel"])
        while (do_loop) do
            local event, modemSide, senderChannel,
                replyChannel, message, senderDistance = os.pullEvent()

            temp_seralized = string.gsub(tostring(message), "[\n ]", "")
            core.log(branch, core.strings.levels.debug, "pull: "..event..": "..temp_seralized)
            if (event == "modem_message") then
                message_data = textutils.unserialize(message)

                -- confrim event
                if (message_data["type"] == "confrim") and
                  ((not (turtle == nil) and (message_data["turtle_id"] == os.computerID())) or
                   ((turtle == nil) and (message_data["turtle_id"] == branch.progress["paired_id"]) and (message_data["retransmit_id"] == os.computerID()))) then
                    do_loop = false
                end
            elseif (event == "timer") then
                core.log(branch, core.strings.levels.debug, "timer")
                do_loop = false
                message_data = {}
                message_data["number_of_branches"] = branch.settings["number_of_branches"]
                message_data["branch"] = branch.progress["branch"]["current"]
                send_message("start", message_data)
            end
        end
        branch.transmitter.close(branch.settings["receive_channel"])
        if (turtle == nil) then
            branch.transmitter.open(branch.settings["transmit_channel"])
        end
    end
end
-- used by receiver to confrim request
send_confrim = function(id)
    local confrim_data = {}
    confrim_data["type"] = "confrim"
    confrim_data["turtle_id"] = id
    if not (branch.progress["retransmit_id"] == nil) then
        confrim_data["retransmit_id"] = branch.progress["retransmit_id"]
    end
    temp_seralized = string.gsub(textutils.serialize(confrim_data), "[\n ]", "")
    core.log(branch, core.strings.levels.debug, "confrim: "..temp_seralized)
    branch.transmitter.transmit(branch.settings["receive_channel"], branch.settings["transmit_channel"], textutils.serialize(confrim_data))
end
-- set current task for turtle (just for visual)
set_task = function(main, sub)
    branch.update_progress("task", main)
    core.log(branch, core.strings.levels.debug, "task: "..main.." "..sub)
    term_size = {term.getSize()}
    term.setCursorPos(1,branch.ids_line+4)
    core.text.clear_line()
    core.text.color_write(main, colors.cyan)
    term.setCursorPos(term_size[1]-((#sub)-1),branch.ids_line+4)
    core.text.color_write(sub, colors.yellow)

    -- if turtle and transmit, send task data to receivers
    if (not (turtle == nil)) and (branch.settings["transmit_progress"]) then
        local send_data = {}
        send_data["main"] = main
        send_data["sub"] = sub
        send_message("task", send_data)
    end
end