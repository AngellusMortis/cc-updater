local self = {
    --[[
    ##name: ]]--
    program_name = "am-cc Branch",
    --[[
    ##file: am-cc/core/branch.lua
    ##version: ]]--
    program_version = "3.7.0.1",
    --[[

    ##type: core
    ##desc: Shared code for branch mining program (see am-cc/programs/turtle/branch.lua)

    ##images:

    ##detailed:

    ##planned:

    ##issues:

    ##parameters:

    --]]

    log_file = ".branch.log",

    settings_file = ".branch.settings",
    settings = nil,

    progress_file = ".branch.progress",
    progress = nil,

    -- used for testing for ores (anything not in this list is considered an "ore")
    -- by default should be cobblestone, dirt, stone, and gravel
    test_slots = {},

    -- variable to hold wireless modem
    transmitter = nil,

    -- random variables
    ids_line = 1,

    -- error messages
    has_error = false,
    message_press_enter = "Press ENTER to continue...",
    message_error_clear = "__clear",
    message_error_file = "File could not be opened",
    message_error_move = "Cannot move",
    message_error_dig = "Cannot dig",
    message_error_fuel = "Out of fuel",
    message_error_chest = "Out of chests",
    message_error_no_chest = "No chest to put items in",
    message_error_torch = "Out of torches",
    message_error_cobble = "Not enough cobblestone",
    message_error_modem = "No modem connected",
    message_error_modem_side = nil, -- see init_settings
    message_error_modem_wireless = "Modem cannot do wireless",
    message_error_failed_to_place_chest = "Could not place chest",
    message_error_failed_to_place_torch = "Could not place torch",
    message_error_failed_to_place_torch_wall = "Could not place wall for torch",
    message_error_failed_to_send_message = "Failed to send message",
    message_error_display_width = "Display is not wide enough",
    message_error_display_height = "Display is not tall enough",
    message_error_trunk = "trunk_height must be 2 or 3",
    message_error_liquids = "Encountered liquids",


    -- function prototypes (only as needed)
    print_error = nil,
    log = nil,
    init_settings = nil,
    read_settings = nil,
    write_settings = nil,
    init_progress = nil,
    read_progress = nil,
    write_progress = nil,
    update_progress = nil,
}

-- functions
-- need this function for bools
self.setting_or_default = function(setting_value, default)
    if (self.settings[setting_value] == nil) then
        return default
    end
    return self.settings[setting_value]
end
-- init settings variable
self.init_settings = function()
    self.read_settings()

    self.settings = self.settings or {}

    -- debug settings
    self.settings["debug"] = self.setting_or_default("debug", false)

    -- mine config
    self.settings["use_coal"] = self.setting_or_default("use_coal", false)
    self.settings["number_of_branches"] = self.settings["number_of_branches"] or 5
    self.settings["branch_between_distance"] = self.settings["branch_between_distance"] or 2
    self.settings["branch_length"] = self.settings["branch_length"] or 52
    self.settings["torch_distance"] = self.settings["torch_distance"] or 10
    self.settings["branch_connector_distance"] = self.settings["branch_connector_distance"] or 26
    self.settings["trunk_width"] = self.settings["trunk_width"] or 2
    self.settings["trunk_height"] = self.settings["trunk_height"] or 3

    -- turtle(slots) config
    -- chest and torch slots are to keep track of supplies
    self.settings["torch_slot"] = self.settings["torch_slot"] or 1
    self.settings["chest_slot"] = self.settings["chest_slot"] or 2
    -- cobblestone slot use to place so torch can be placed
    self.settings["cobblestone_slot"] = self.settings["cobblestone_slot"] or 3

    -- level of coal to reach when refueling
    self.settings["min_continue_fuel_level"] = self.settings["min_continue_fuel_level"] or 500
    -- ticks between attempts to move (see force_forward, force_up, and force_down)
    self.settings["tick_delay"] = self.settings["tick_delay"] or 2

    -- wireless broadcast settings
    -- do broadcast
    -- on receiver will determine wether or not to retransmit (range extension)
    self.settings["transmit_progress"] = self.setting_or_default("transmit_progress", true)
    -- if you have multiple modems (wired and wireless), set this to force
    --  side of modem if perhiperal.find() is picking the wired one
    self.settings["transmitter_side"] = self.setting_or_default("transmitter_side", nil)
    -- should not need to change these
    self.settings["transmit_channel"] = self.settings["transmit_channel"] or 60000
    self.settings["receive_channel"] = self.settings["receive_channel"] or 60001

    -- attempt to redirect to monitor for receiver?
    --  side monitor if perhiperal.find() is picking an undesired one (works with networked monitors)
    self.settings["redirect_to_monitor"] = self.setting_or_default("redirect_to_monitor", true)
    self.settings["monitor_side"] = self.setting_or_default("monitor_side", nil)

    --save/load functionaility
    -- WIP, do NOT use
    self.settings["allow_resume"] = self.setting_or_default("allow_resume", false)

    -- multitask stuff
    self.settings["do_multitask"] = self.setting_or_default("do_multitask", not (term.isColor == nil))

    self.write_settings()

    self.message_error_modem_side = "No modem connected ("..tostring(self.settings["transmitter_side"])..")"
end
-- writes current progress to progress file
self.write_settings = function()
    temp_seralized = textutils.serialize(self.settings)
    handle = fs.open(self.settings_file, "w")

    if (handle == nil) then
        self.print_error(self.message_error_file, true)
    else
        handle.write(temp_seralized)
        handle.close()
    end
    temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
    self.log("write: settings: "..temp_seralized)
end
-- reads progress from progress file
self.read_settings = function()
    handle = fs.open(self.settings_file, "r")

    if not (handle == nil) then
        temp_seralized = handle.readAll()
        if (string.len(temp_seralized) > 5) then
            self.settings = textutils.unserialize(temp_seralized)
            temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
            self.log("read: settings: "..temp_seralized)
            handle.close()
        end
    end
end
-- init progress variable
self.init_progress = function()
    if not (turtle == nil) then
        self.read_progress()
    end
    if (self.progress == nil) then
        self.progress = {}
        self.progress["task"] = nil
        self.progress["position"] = {{0, 0, 0}, 2}
        self.progress["branch"] = {}
        self.progress["branch"]["current"] = 1
        self.progress["branch"]["progress"] = nil
        self.progress["branch"]["side"] = nil
        self.progress["branch"]["height"] = 1
        self.progress["trunk"] = {}
        self.progress["trunk"]["remaining"] = nil
        if (turtle == nil) then
            self.progress["paired_id"] = nil
            self.progress["retransmit_id"] = nil
        end
    end

    if (self.settings["allow_resume"]) then
        self.write_progress()
    end
end
-- writes current progress to progress file
self.write_progress = function()
    temp_seralized = textutils.serialize(self.progress)
    handle = fs.open(self.progress_file, "w")

    if (handle == nil) then
        self.print_error(self.message_error_file, true)
    else
        handle.write(temp_seralized)
        handle.close()
    end
    temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
    self.log("write: progress: "..temp_seralized)
end
-- reads progress from progress file
self.read_progress = function()
    handle = fs.open(self.progress_file, "r")

    if not (handle == nil) then
        temp_seralized = handle.readAll()
        if (string.len(temp_seralized) > 5) then
            self.progress = textutils.unserialize(temp_seralized)
            temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
            self.log("read: progress: "..temp_seralized)
            handle.close()
        end
    end
end
-- updates value in progress variable (DO NOT DO IT MANUALLY)
self.update_progress = function(progress_item, new_value, index_1, index_2)
    self.log("update: "..tostring(progress_item).."["..tostring(index_1).."]["..tostring(index_2).."] "..tostring(new_value))
    if (progress_item == "position") and (index_2 == nil) then
        self.progress[progress_item][index_1] = new_value
    elseif (progress_item == "position") then
        self.progress[progress_item][index_1][index_2] = new_value
    elseif (progress_item == "branch") then
        self.progress[progress_item][index_1] = new_value
    else
        self.progress[progress_item] = new_value
    end
    if not (turtle == nil) and (self.settings["allow_resume"]) then
        self.write_progress()
    end
end
-- if debug, logs message to file
self.log = function(message)
    if (self.settings["debug"]) then
        handle = nil
        if (fs.exists(self.log_file)) then
            handle = fs.open(self.log_file, "a")
        else
            handle = fs.open(self.log_file, "w")
        end
        if (handle == nil) then
            self.settings["debug"] = false
            self.print_error(self.message_error_file)
        else
            handle.writeLine("["..tostring(os.time()).."]: "..tostring(message))
            handle.close()
        end
    end
end
-- send message to receiver
self.send_message = function(message_type, message_data)
    message_data = message_data or {}
    if (message_data["turtle_id"] == nil) and not (turtle == nil) then
        message_data["turtle_id"] = os.computerID()
    elseif (message_data["turtle_id"] == nil) then
        message_data["turtle_id"] = self.progress["paired_id"]
    end
    if (message_data["type"] == nil) then
        message_data["type"] = message_type
    end
    if (turtle == nil) then
        message_data["retransmit_id"] = os.computerID()
    end

    if (message_data["type"] == nil) or (message_data["turtle_id"] == nil) then
        temp_seralized = string.gsub(textutils.serialize(message_data), "[\n ]", "")
        self.log("send: "..temp_seralized)
        self.print_error(self.message_error_failed_to_send_message, false, false)
        return
    end
    temp_seralized = string.gsub(textutils.serialize(message_data), "[\n ]", "")
    self.log("send: "..temp_seralized)
    self.transmitter.transmit(self.settings["transmit_channel"], self.settings["receive_channel"], textutils.serialize(message_data))

    if (message_type == "check") or (message_type == "branch_update") then
        os.startTimer(3)
        local do_loop = true
        -- open channel for listening
        if (turtle == nil) then
            self.transmitter.close(self.settings["transmit_channel"])
        end
        self.transmitter.open(self.settings["receive_channel"])
        while (do_loop) do
            local event, modemSide, senderChannel,
                replyChannel, message, senderDistance = os.pullEvent()

            temp_seralized = string.gsub(tostring(message), "[\n ]", "")
            self.log("pull: "..event..": "..temp_seralized)
            if (event == "modem_message") then
                message_data = textutils.unserialize(message)

                -- confrim event
                if (message_data["type"] == "confrim") and
                  ((not (turtle == nil) and (message_data["turtle_id"] == os.computerID())) or
                   ((turtle == nil) and (message_data["turtle_id"] == self.progress["paired_id"]) and (message_data["retransmit_id"] == os.computerID()))) then
                    do_loop = false
                end
            elseif (event == "timer") then
                self.log("timer")
                do_loop = false
                message_data = {}
                message_data["number_of_branches"] = self.settings["number_of_branches"]
                message_data["branch"] = self.progress["branch"]["current"]
                self.send_message("start", message_data)
            end
        end
        self.transmitter.close(self.settings["receive_channel"])
        if (turtle == nil) then
            self.transmitter.open(self.settings["transmit_channel"])
        end
    end
end
-- Force clears the current terminal line and then
--  sets it to first positions (was having trouble with term.clearLine())
self.clear_line = function()
    pos = {term.getCursorPos()}
    term_size = {term.getSize()}
    term.setCursorPos(1, pos[2])
    term.write(string.rep(" ",term_size[1]))
    term.setCursorPos(1, pos[2])
end
-- used by receiver to confrim request
self.send_confrim = function(id)
    local confrim_data = {}
    confrim_data["type"] = "confrim"
    confrim_data["turtle_id"] = id
    if not (self.progress["retransmit_id"] == nil) then
        confrim_data["retransmit_id"] = self.progress["retransmit_id"]
    end
    temp_seralized = string.gsub(textutils.serialize(confrim_data), "[\n ]", "")
    self.log("confrim: "..temp_seralized)
    self.transmitter.transmit(self.settings["receive_channel"], self.settings["transmit_channel"], textutils.serialize(confrim_data))
end
-- writes text in color, if display supports color
self.color_write = function(text, color)
    if (term.isColor()) then
        term.setTextColor(color)
    end
    term.write(text)
    if (term.isColor()) then
        term.setTextColor(colors.white)
    end
end
self.wait_for_enter = function()
    term_size = {term.getSize()}
    term.setCursorPos(1, (term_size[2]-1))
    self.clear_line()
    print(self.message_press_enter)
    repeat
        event, param1 = os.pullEvent("key")
    until param1 == 28
    term.setCursorPos(1, (term_size[2]-1))
    self.clear_line()
end
-- prints error on second to last line and then waits for ENTER
--  if fatal is set to true, terminates program instead with error message
self.print_error = function(error_message, fatal, wait)
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
    self.log(prefix..": "..error_message.." ["..tostring(fatal).."]["..tostring(wait).."]")

    -- if turtle and transmit is on, send to receiver
    if (not (turtle == nil)) and (self.settings["transmit_progress"]) then
        local error_data = {}
        error_data["error"] = error_message
        error_data["wait"] = wait
        self.send_message("error", error_data)
    end

    -- if fatal, terminate
    if (fatal) then
        error(error_message)
    else
        self.has_error = true
        term_size = {term.getSize()}
        term.setCursorPos(1, (term_size[2]-2))
        self.clear_line()
        self.color_write(prefix..": "..error_message, colors.red)
        -- if turtle, wait for user to press ENTER
        if not (turtle == nil) then
            if (wait) then
                self.wait_for_enter()
                term.setCursorPos(1, (term_size[2]-2))
                self.clear_line()
                self.has_error = false
            end
            -- if transmit, tell receiver error has been cleared
            if (self.settings["transmit_progress"]) then
                local error_data = {}
                error_data["error"] = self.message_error_clear
                send_message("error", error_data)
            end
        else
            if (wait) then
                self.wait_for_enter()
                term.setCursorPos(1, (term_size[2]-2))
                self.clear_line()
            end
        end
    end
end
-- set current task for turtle (just for visual)
self.set_task = function(main, sub)
    self.update_progress("task", main)
    self.log("task: "..main.." "..sub)
    term_size = {term.getSize()}
    term.setCursorPos(1,self.ids_line+4)
    self.clear_line()
    self.color_write(main, colors.cyan)
    term.setCursorPos(term_size[1]-((#sub)-1),self.ids_line+4)
    self.color_write(sub, colors.yellow)

    -- if turtle and transmit, send task data to receivers
    if (not (turtle == nil)) and (self.settings["transmit_progress"]) then
        local send_data = {}
        send_data["main"] = main
        send_data["sub"] = sub
        self.send_message("task", send_data)
    end
end

self.init_settings()

return self