--[[
##name: ]]--
program_name = "am-cc Branch Mining"
--[[
##file: am/turtle/branch.lua
##version: ]]--
program_version = "3.5.2.2"
--[[

##type: turtle
##desc: Mines a branch mine with a trunk and 5 branches each divded into two 50 length halves.

##detailed:
By default, creates a branch mine this fashion (by default):
Top:
                                                               Trunk (main shaft)
                                                               |-
                                                               vv
        XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
        XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |--> XXX_T_________T_________T_________T_________T_________TCCT_________T_________T_________T_________T_________T_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |--> XXX_T_________T_________T_________T_________T_________TCCT_________T_________T_________T_________T_________T_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |--> XXX_T_________T_________T_________T_________T_________TCCT_________T_________T_________T_________T_________T_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |--> XXX_T_________T_________T_________T_________T_________TCCT_________T_________T_________T_________T_________T_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   |--> XXX_T_________T_________T_________T_________T_________TCCT_________T_________T_________T_________T_________T_XXX
   B    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX__XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   r    XXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXCZ_CXXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXX_XXX
   a       ^                         ^                        ^^ ^                        ^                         ^
   n       |-------------------------|------------------------||-|------------------------|-------------------------|
   c       |                                                  || |
   h       Branch connectors                        Torch Chest| Fuel Chest
   e                                                           Chest Chest
   s

All Chests are to drop off ores/stuff from mining except for the three marked chests near start position (0, 0, 0)

Side (branch):         Side (trunk, front view for chest locations):
                       XXXXXX
XXXXXXXXXXXXXXX        XX__XX
XTXXTXXTXXTXXTX        XXC_XX
X_XX_XX_XX_XX_X        XCZ_CX
XXXXXXXXXXXXXXX        XXXXXX

Key:
X : stone/dirt/gravel/cobblestone
_ : air
T : torch
C : Chest
Z : Coord position (0, 0, 0)

Directions (T = turtle, assuming facing in direction of mine):
    2

3   T   1

    0

Up: 4
Down: 5

##planned:
#save/resume feature
#liquids

##issues:

##parameters:
args[1]: display to redirect to (side or name) (default: nil) enter "false" to disable redirection
args[2]: Use collected coal as fuel (default: false)
args[3]: Number of branches
args[4]: Number of blocks between each branch (default: 2)
args[5]: Length of branch in blocks (default: 52)
args[6]: distance between torches (default: 10)
args[7]: Number of blocks between connections between branches (default: 26)

--]]

local args = { ... }

local log_file = ".branch.log"

local settings_file = ".branch.settings"
local settings = nil

local progress_file = ".branch.progress"
local progress = nil

-- used for testing for ores (anything not in this list is considered an "ore")
-- by default should be cobblestone, dirt, stone, and gravel
local test_slots = {}

-- variable to hold wireless modem
local transmitter = nil

-- random variables
local ids_line = 1

-- error messages
local has_error = false
local message_press_enter = "Press ENTER to continue..."
local message_error_clear = "__clear"
local message_error_file = "File could not be opened"
local message_error_move = "Cannot move"
local message_error_dig = "Cannot dig"
local message_error_fuel = "Out of fuel"
local message_error_chest = "Out of chests"
local message_error_no_chest = "No chest to put items in"
local message_error_torch = "Out of torches"
local message_error_cobble = "Not enough cobblestone"
local message_error_modem = "No modem connected"
local message_error_modem_side = nil -- see init_settings
local message_error_modem_wireless = "Modem cannot do wireless"
local message_error_failed_to_place_chest = "Could not place chest"
local message_error_failed_to_place_torch = "Could not place torch"
local message_error_failed_to_place_torch_wall = "Could not place wall for torch"
local message_error_failed_to_send_message = "Failed to send message"
local message_error_display_width = "Display is not wide enough"
local message_error_display_height = "Display is not tall enough"
local message_error_trunk = "trunk_height must be 2 or 3"
local message_error_liquids = "Encountered liquids"


-- function prototypes (only as needed)
local print_error = nil
local log = nil
local init_settings = nil
local read_settings = nil
local write_settings = nil
local init_progress = nil
local read_progress = nil
local write_progress = nil
local update_progress = nil
local empty_inventory = nil

-- functions
-- need this function for bools
local function setting_or_default(setting_value, default)
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
-- opposite direction
local function get_opposite_direction(direction)
    if (direction == 0) then
        return 2
    elseif (direction == 1) then
        return 3
    elseif (direction == 2) then
        return 0
    elseif (direction == 3) then
        return 1
    elseif (direction == 4) then
        return 5
    elseif (direction == 5) then
        return 4
    end
    return nil
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

-- turtle functions
-- rotate turtle and update progress["position"]
local function rotate(direction)
    local offset = direction - progress["position"][2]
    update_progress("position", direction, 2)
    if (offset == 0) then
        return
    elseif (math.abs(offset) == 2) then
        turtle.turnRight()
        turtle.turnRight()
    elseif (offset == 3) or (offset == -1) then
        turtle.turnRight()
    else
        turtle.turnLeft()
    end
end
-- only works in CC1.6
local function detect_liquid_forward()
    if (turtle.detect()) then
        turtle.select(settings["cobblestone_slot"])
        if (turtle.place()) then
            print_error(message_error_liquids)
        end
    end
end
-- force the turtle to move forward
--  kills anything in way
--  digs anything out of the way
--  can generate error if unable to move after 10 tries and block in front or 50 tries (mob)
--  updates progress["position"]
local function force_forward(allow_fail)
    allow_fail = allow_fail or false
    count = 0
    detect_liquid_forward()
    local move_success = turtle.forward()
    while not (move_success) do
        turtle.select(1)
        turtle.attack()
        turtle.dig()

        count = count + 1
        if (count > 10 and turtle.detect()) or (count > 50) then
            if (allow_fail) then
                break
            end
            print_error(message_error_move)
            count = 0
        end
        os.sleep(0.05 * settings["tick_delay"])
        detect_liquid_forward()
        move_success = turtle.forward()
    end

    if (move_success) then
        turtle.suck()
        turtle.suckUp()
        turtle.suckDown()

        if (progress["position"][2] == 0) then
            update_progress("position", progress["position"][1][3] - 1, 1, 3)
        elseif (progress["position"][2] == 1) then
            update_progress("position", progress["position"][1][1] + 1, 1, 1)
        elseif (progress["position"][2] == 2) then
            update_progress("position", progress["position"][1][3] + 1, 1, 3)
        else
            update_progress("position", progress["position"][1][1] - 1, 1, 1)
        end
    end
    return move_success
end
-- force turtle to dig (keeps digging until no block)
local function force_dig_forward(allow_fail)
    allow_fail = allow_fail or false
    count = 0
    detect_liquid_forward()
    while (turtle.detect()) do
        turtle.select(1)
        turtle.attack()
        turtle.dig()
        turtle.suck()
        turtle.suckUp()
        turtle.suckDown()
        count = count + 1
        if (count > 10 and turtle.detect()) or (count > 50) then
            if (allow_fail) then
                break
            end
            print_error(message_error_dig.." (forward)")
            count = 0
        end
        os.sleep(0.5 * settings["tick_delay"])
        detect_liquid_forward()
    end
end
-- only works in CC1.6
local function detect_liquid_up()
    if (turtle.detectUp()) then
        turtle.select(settings["cobblestone_slot"])
        if (turtle.placeUp()) then
            print_error(message_error_liquids)
        end
    end
end
-- force the turtle to move up
--  digs anything out of the way
--  can generate error if unable to move after 10 tries
--  updates progress["position"]
local function force_up(allow_fail)
    allow_fail = allow_fail or false
    count = 0
    detect_liquid_up()
    success = turtle.up()
    while not (success) do
        turtle.select(1)
        turtle.digUp()
        count = count + 1
        if (count > 10) then
            if (allow_fail) then
                break
            end
            print_error(message_error_move)
            count = 0
        end
        os.sleep(0.5 * settings["tick_delay"])
        detect_liquid_up()
        success = turtle.up()
    end
    if (success) then
        turtle.suckUp()
        update_progress("position", progress["position"][1][2] + 1, 1, 2)
    end
    return success
end
-- force turtle to dig up (keeps digging until no block)
local function force_dig_up(allow_fail)
    allow_fail = allow_fail or false
    count = 0
    detect_liquid_up()
    while (turtle.detectUp()) do
        turtle.select(1)
        turtle.digUp()
        turtle.suckUp()
        count = count + 1
        if (count > 10) then
            if (allow_fail) then
                break
            end
            print_error(message_error_dig.." (up)")
            count = 0
        end
        os.sleep(0.5 * settings["tick_delay"])
        detect_liquid_up()
    end
end
-- only works in CC1.6
local function detect_liquid_down()
    if (turtle.detectDown()) then
        turtle.select(settings["cobblestone_slot"])
        if (turtle.placeDown()) then
            print_error(message_error_liquids)
        end
    end
end
-- force the turtle to move down
--  digs anything out of the way
--  can generate error if unable to move after 10 tries
--  updates progress["position"]
local function force_down(allow_fail)
    allow_fail = allow_fail or false
    count = 0
    detect_liquid_down()
    success = turtle.down()
    while not (success) do
        turtle.select(1)
        turtle.digDown()
        count = count + 1
        if (count > 10) then
            if (allow_fail) then
                break
            end
            print_error(message_error_move)
            count = 0
        end
        os.sleep(0.5 * settings["tick_delay"])
        detect_liquid_down()
        success = turtle.down()
    end
    if (success) then
        turtle.suckDown()
        update_progress("position", progress["position"][1][2] - 1, 1, 2)
    end
    return success
end
-- force turtle to dig down (keeps digging until no block)
local function force_dig_down(allow_fail)
    allow_fail = allow_fail or false
    count = 0
    detect_liquid_down()
    while (turtle.detectDown()) do
        turtle.select(1)
        turtle.digDown()
        turtle.suckDown()
        count = count + 1
        if (count > 10) then
            if (allow_fail) then
                break
            end
            print_error(message_error_dig.." (down)")
            count = 0
        end
        os.sleep(0.5 * settings["tick_delay"])
        detect_liquid_down()
    end
end
-- uses all fuel in inventory
local function use_all_fuel()
    for i=1,16 do
        turtle.select(i)
        turtle.refuel(64)
    end
end
-- moves turtle to coords and facing direction
--   allows for both negative and positive coords for X and Y, but NOT Z
local function goto_position(coord, facing)
    temp_seralized = string.gsub(textutils.serialize({coord, facing}), "[\n ]", "")
    log("goto: "..temp_seralized)
    -- move turtle out of branch connector if in one
    branchs_z = {settings["branch_between_distance"]}
    for i=2,settings["number_of_branches"] do
        table.insert(branchs_z, branchs_z[#branchs_z]+settings["branch_between_distance"]+1)
    end
    distance_from_branch = -1
    for i=1,#branchs_z do
        if (progress["position"][1][3] >= branchs_z[i]) then
            temp_distance = progress["position"][1][3] - branchs_z[i]
            if (temp_distance < distance_from_branch) or (distance_from_branch == -1) then
                distance_from_branch = progress["position"][1][3] - branchs_z[i]
            end
        else
            break
        end
    end
    for i=1,distance_from_branch do
        rotate(0)
        force_forward()
    end

    -- goto x coord
    while (progress["position"][1][1] > coord[1]) do
        rotate(3)
        force_forward()
    end
    while (progress["position"][1][1] < coord[1]) do
        rotate(1)
        force_forward()
    end

    -- goto z coord
    while (progress["position"][1][3] > coord[3]) do
        rotate(0)
        force_forward()
    end
    while (progress["position"][1][3] < coord[3]) do
        rotate(2)
        force_forward()
    end

    -- goto y coord
    while (progress["position"][1][2] > coord[2]) do
        force_down()
    end
    while (progress["position"][1][2] < coord[2]) do
        force_up()
    end

    -- rotate to facing
    rotate(facing)
end
-- calculate the distance from the fuel chest
local function get_distance_from_fuel()
    -- fuel position is (trunk_width-1, 0, 0)
    return math.abs(progress["position"][1][1]-(settings["trunk_width"]-1))+math.abs(progress["position"][1][2])+math.abs(progress["position"][1][3])
end
local function get_fuel_amount_for_branch()
    return get_distance_from_fuel() + ((settings["branch_length"] + (settings["branch_length"]/settings["branch_connector_distance"])*(settings["branch_between_distance"]*2))*2 + settings["trunk_width"])*2
end
-- test if it is nesscary to get resources
local function get_fuel_and_supplies_if_needed(required_fuel)
    set_task("Supplies", "Checking")

    -- check fuel
    local previous_position = {{progress["position"][1][1], progress["position"][1][2], progress["position"][1][3]}, progress["position"][2]}
    local has_moved = false
    if (turtle.getFuelLevel() < required_fuel) then
        if (required_fuel < settings["min_continue_fuel_level"]) then
            required_fuel = settings["min_continue_fuel_level"]
        end
        has_moved = true
        set_task("Supplies", "Fuel")
        goto_position({(settings["trunk_width"]-1), 0, 0}, 1)
        need_fuel = (turtle.getFuelLevel() < required_fuel)
        while (need_fuel) do
            if not (turtle.suck()) then
                print_error(message_error_fuel)
            end
            use_all_fuel()
            need_fuel = (turtle.getFuelLevel() < required_fuel)
        end
    end

    -- check torches/chests
    set_task("Supplies", "Checking")
    local need_chests = (turtle.getItemCount(settings["chest_slot"]) <= 1)
    local need_torches = (turtle.getItemCount(settings["torch_slot"]) <= (((settings["branch_length"]/settings["torch_distance"])+1)*2))
    if (need_chests or need_torches) then
        has_moved = true
        set_task("Supplies", "Items")
        goto_position({0, 0, 0}, 3)

        -- resupply chests
        while (need_chests) do
            set_task("Supplies", "Chests")
            turtle.select(settings["chest_slot"])
            turtle.dropUp()
            turtle.suckUp()
            need_chests = (turtle.getItemCount(settings["chest_slot"]) <= 1)
            if (need_chests) then
                print_error(message_error_chest)
            end
        end
        -- resupply torches
        while (need_torches) do
            set_task("Supplies", "Torches")
            turtle.select(settings["torch_slot"])
            turtle.drop()
            turtle.suck()
            need_torches = (turtle.getItemCount(settings["torch_slot"]) <= (((settings["branch_length"]/settings["torch_distance"])+1)*2))
            if (need_torches) then
                print_error(message_error_torch)
            end
        end
    end

    empty_slots = false
    for i=1,16 do
        empty_slots = empty_slots or (turtle.getItemCount(i) == 0)
    end
    if not empty_slots then
        has_moved = true
        set_task("Supplies", "Emptying")
        goto_position({progress["branch"]["side"]-1, 1, settings["branch_between_distance"]*progress["branch"]["current"]}, 2)
        empty_inventory()
    end

    if (has_moved) then
        -- return to previous position
        set_task("Supplies", "Returning")
        goto_position(unpack(previous_position))
    end
end

-- main functions
empty_inventory = function()
    for i=1,16 do
        set_task("Emptying", string.format("%3d%%", (i/16)*100))
        turtle.select(i)
        if (i == settings["torch_slot"]) or (i == settings["chest_slot"]) or (i == settings["cobblestone_slot"]) then
        else
            is_test_block = false
            for index,value in ipairs(test_slots) do
                is_test_block = (is_test_block or (i == value))
            end
            if (is_test_block) then
                to_drop = turtle.getItemCount(i)-1
                if (to_drop > 0) then
                    turtle.dropUp(to_drop)
                end
            else
                turtle.dropUp(64)
            end
        end
    end
end
-- check for ores and mine them if they are there
--   will mine out anything that is not stone, dirt, gravel, or cobblestone
--   if do_down, will check block below turtle, otherwise, will check block above
local function dig_ores(movement)
    movement = movement or {}

    if (#movement == 0) then
        previous_face = progress["position"][2]
    end

    -- down
    if (turtle.detectDown()) then
        not_ore_block = false
        for index,value in ipairs(test_slots) do
            turtle.select(value)
            not_ore_block = (not_ore_block or turtle.compareDown())
        end
        if not (not_ore_block) then
            if (#movement == 0) then
                -- check for needed supplies
                required_fuel = get_fuel_amount_for_branch()
                get_fuel_and_supplies_if_needed(required_fuel)
                set_task("Mining Vein", "")
            end
            if (force_down(true)) then
                movement[#movement+1]=4
                os.sleep(0.05 * settings["tick_delay"])
                dig_ores(movement)
            end
        end
    end
    -- up
    if (turtle.detectUp()) then
        not_ore_block = false
        for index,value in ipairs(test_slots) do
            turtle.select(value)
            not_ore_block = (not_ore_block or turtle.compareUp())
        end
        if not (not_ore_block) then
            if (#movement == 0) then
                -- check for needed supplies
                required_fuel = get_fuel_amount_for_branch()
                get_fuel_and_supplies_if_needed(required_fuel)
                set_task("Mining Vein", "")
            end
            if (force_up(true)) then
                movement[#movement+1]=5
                os.sleep(0.05 * settings["tick_delay"])
                dig_ores(movement)
            end
        end
    end

    sides_to_check = {}
    if (#movement == 0) then
        sides_to_check = {0, 2}
    else
        sides_to_check = {0, 1, 2, 3}
    end
    -- sides
    for i,v in ipairs(sides_to_check) do
        rotate(v)
        if (turtle.detect()) then
            not_ore_block = false
            for index,value in ipairs(test_slots) do
                turtle.select(value)
                not_ore_block = (not_ore_block or turtle.compare())
            end
            if not (not_ore_block) then
                if (#movement == 0) then
                    -- check for needed supplies
                    required_fuel = get_fuel_amount_for_branch()
                    get_fuel_and_supplies_if_needed(required_fuel)
                    set_task("Mining Vein", "")
                end
                if (force_forward(true)) then
                    movement[#movement+1]=get_opposite_direction(v)
                    os.sleep(0.05 * settings["tick_delay"])
                    dig_ores(movement)
                end
            end
        end
    end

    if (#movement > 0) then
        if (movement[#movement] == 4) then
            force_up()
        elseif (movement[#movement] == 5) then
            force_down()
        else
            rotate(movement[#movement])
            force_forward()
        end
        movement[#movement] = nil
    else
        rotate(previous_face)
    end
end
-- digs out part of trunk of length
local function dig_out_trunk(length)
    log("trunk: "..length)
    -- check for needed supplies
    required_fuel = get_fuel_amount_for_branch()
    get_fuel_and_supplies_if_needed(required_fuel)

    set_task("Trunk", string.format("%3d%%", 0))
    rotate(2)
    for i=1,length do
        force_forward()
        if (settings["trunk_height"] == 3) then
            force_up()
        end
        turtle.select(settings["chest_slot"])
        if not (turtle.compareUp()) then
            force_dig_up()
        end
        rotate(1)
        for i=1,(settings["trunk_width"]-1) do
            force_forward()
            if (i == settings["trunk_width"]-1) then
                turtle.select(settings["chest_slot"])
                if not (turtle.compareUp()) then
                    force_dig_up()
                end
            else
                force_dig_up()
            end
            if (settings["trunk_height"] == 3) then
                force_dig_down()
            end
        end
        rotate(3)
        for i=1,(settings["trunk_width"]-1) do
            force_forward()
        end
        if (settings["trunk_height"] == 3) then
            force_down()
        end
        rotate(2)
        set_task("Trunk", string.format("%3d%%", (i/length)*100))
    end
end
-- digs out a single branch
local function dig_branch()
    -- check for needed supplies
    required_fuel = get_distance_from_fuel() + ((settings["branch_length"] + (settings["branch_length"]/settings["branch_connector_distance"])*(settings["branch_between_distance"]*2))*2 + settings["trunk_width"])*2
    get_fuel_and_supplies_if_needed(required_fuel)

    set_task("Branch", string.format("%3d%%", 0))
    progress["branch"]["side"] = progress["branch"]["side"] or 1

    -- each path through loop is one half of branch (each side of trunk)
    for x=progress["branch"]["side"],2 do
        update_progress("branch", x, "side")
        if (x == 1) then
            rotate(3)
        else
            rotate(1)
        end

        if (progress["branch"]["height"] == nil) then
            update_progress("branch", 1, "height")
        end

        if (progress["branch"]["height"] == 1) then
            if (progress["branch"]["progress"] == nil) or (progress["branch"]["progress"] == 1) then
                -- place supply chest
                force_up()
                if not (turtle.compareUp()) then
                    force_up()
                    force_dig_up()
                    force_down()
                    turtle.select(settings["chest_slot"])
                    while not (turtle.placeUp()) do
                        print_error(message_error_failed_to_place_chest)
                        turtle.select(settings["chest_slot"])
                    end
                else
                    turtle.select(settings["chest_slot"])
                    turtle.placeUp()
                end
            end
            progress["branch"]["progress"] = progress["branch"]["progress"] or 1
            -- mine out top of branch
            for i=progress["branch"]["progress"],settings["branch_length"] do
                update_progress("branch", i, "progress")
                set_task("Branch", string.format("%3d%%", (x-1)*50+((i/settings["branch_length"])*100)/4))
                force_forward()
                dig_ores()

                -- mine out branch connectors
                if (i%settings["branch_connector_distance"]) == 0 then
                    rotate(2)
                    for j=1,settings["branch_between_distance"] do
                        force_forward()
                        dig_ores()
                    end
                    force_down()
                    rotate(0)
                    for j=1,settings["branch_between_distance"] do
                        force_forward()
                        dig_ores()
                    end
                    force_up()
                    if (x == 1) then
                        rotate(3)
                    else
                        rotate(1)
                    end
                end

                -- verfiy blocks are in place for torches (placed later)
                if (((i%settings["torch_distance"]) == 1)) then
                    log("branch: place: torch wall")
                    if (has_error) then
                        term_size = {term.getSize()}
                        term.setCursorPos(1, (term_size[2]-2))
                        clear_line()
                        has_error = false
                    end
                    if (settings["transmit_progress"]) then
                        send_message("check")
                    end
                    rotate(2)
                    if (not (turtle.detect())) or (not (turtle.detectUp())) then
                        if (turtle.getItemCount(settings["cobblestone_slot"]) > 3) then
                            turtle.select(settings["cobblestone_slot"])
                            turtle.placeUp()
                            turtle.place()
                        else
                            print_error(message_error_failed_to_place_torch_wall, false, false)
                        end
                    end
                    if (x == 1) then
                        rotate(3)
                    else
                        rotate(1)
                    end
                end
            end
            if (x == 1) then
                rotate(1)
            else
                rotate(3)
            end
            --mine out bottom level of branch (return)
            force_down()
            update_progress("branch", 0, "height")
            update_progress("branch", 1, "progress")
        end

        if (progress["branch"]["progress"] == nil) then
            update_progress("branch", 1, "progress")
        end

        for i=progress["branch"]["progress"],settings["branch_length"] do
            set_task("Branch", string.format("%3d%%", (x-1)*50+((i/settings["branch_length"])*100)/4+25))
            force_forward()
            dig_ores()

            -- place torches
            if (i%settings["torch_distance"]) == 1 then
                log("branch: place: torch")
                if (has_error) then
                    term_size = {term.getSize()}
                    term.setCursorPos(1, (term_size[2]-2))
                    clear_line()
                    has_error = false
                end
                if (settings["transmit_progress"]) then
                    send_message("check")
                end
                turtle.select(settings["torch_slot"])
                if not (turtle.placeUp()) then
                    print_error(message_error_failed_to_place_torch, false, false)
                end
            end
        end
        update_progress("branch", nil, "progress")
        set_task("Emptying", string.format("%3d%%", 0))
        force_up()
        -- use fuel is told too
        if (settings["use_coal"]) then
            use_all_fuel()
        end
        turtle.select(settings["chest_slot"])
        while not (turtle.compareUp()) do
            print_error(message_error_no_chest)
        end
        -- empty out inventory (except for supplies)
        empty_inventory()
        set_task("Branch", string.format("%3d%%", x*50))
        force_down()

        -- move to current location to continue
        if (x == 1) then
            rotate(1)
            for i=1,(settings["trunk_width"]-1) do
                force_forward()
            end
        else
            rotate(3)
            for i=1,(settings["trunk_width"]-1) do
                force_forward()
            end
        end

        update_progress("branch", 1, "height")
        update_progress("branch", 1, "progress")
    end

    update_progress("branch", 1, "height")
    update_progress("branch", 1, "progress")
    update_progress("branch", 1, "side")
    rotate(2)
end

local function run_turtle_main()
    -- verify trunk height (program not adjusted for otherwise)
    if not (settings["trunk_height"]==2 or settings["trunk_height"]==3) then
        print_error(message_error_trunk)
    end
    -- check for wireless modem, disable transmit if not there
    if (settings["transmit_progress"]) then
        if not (settings["transmitter_side"] == nil) then
            transmitter = peripheral.wrap(settings["transmitter_side"])
        else
            transmitter = peripheral.find("modem")
        end
        if (transmitter == nil) then
            settings["transmit_progress"] = false
        end
    end

    -- print title
    term_size = {term.getSize()}
    current_branch_location = {term_size[1]-9,ids_line+2}
    term.clear()
    term.setCursorPos(1,1)
    color_write(program_name.." v"..program_version, colors.lime)
    -- if transmit, print computer ID to indicate it
    if (settings["transmit_progress"]) then
        term.setCursorPos(term_size[1]-4,ids_line)
        color_write(string.format("%5d", os.computerID()), colors.white)
    end

    -- if no progress, start new
    if (progress["task"] == nil) then
        -- verfiy there is at least __some__ fuel to get started
        while (turtle.getFuelLevel() == 0) do
            use_all_fuel()
            if (turtle.getFuelLevel() == 0) then
                term.setCursorPos(1,ids_line+3)
                color_write("Put at least one piece of fuel in", colors.cyan)
                wait_for_enter()
                term.setCursorPos(1,ids_line+3)
                clear_line()
            end
        end

        -- remind use to have stone, dirt, gravel, and cobblestone
        term.setCursorPos(1,ids_line+3)
        color_write("Leave slots 1 and 2 empty", colors.cyan)
        term.setCursorPos(1,ids_line+4)
        color_write("Put a stack of cobblestone in slot "..settings["cobblestone_slot"], colors.cyan)
        term.setCursorPos(1,ids_line+5)
        color_write("Put any \"do not mine\" blocks in others", colors.cyan)
        term.setCursorPos(3,ids_line+6)
        color_write("i.e.: cobblestone, stone,", colors.cyan)
        term.setCursorPos(4,ids_line+7)
        color_write("dirt, gravel", colors.cyan)
        wait_for_enter()
        while (turtle.getItemCount(settings["cobblestone_slot"]) < 64) do
            print_error(message_error_cobble)
        end
        -- add items in all slots but 1 and 2 to test_slots
        term.setCursorPos(1,ids_line+3)
        clear_line()
        term.setCursorPos(1,ids_line+4)
        clear_line()
        term.setCursorPos(1,ids_line+5)
        clear_line()
        term.setCursorPos(1,ids_line+6)
        clear_line()
        term.setCursorPos(1,ids_line+7)
        clear_line()
    end

    for i=1,16 do
        if (turtle.getItemCount(i) > 0) then
            test_slots[#test_slots+1] = i
        end
    end

    -- print current branch data
    term.setCursorPos(1,ids_line+2)
    color_write("Current Branch", colors.cyan)
    term.setCursorPos(unpack(current_branch_location))
    color_write(string.format("%3d", progress["branch"]["current"]), colors.yellow)
    term.setCursorPos(term_size[1]-5,ids_line+2)
    color_write("of", colors.white)
    term.setCursorPos(term_size[1]-2,ids_line+2)
    color_write(string.format("%3d", settings["number_of_branches"]), colors.magenta)

    -- if transmit, send start signal to receiver
    if (settings["transmit_progress"]) then
        local send_data = {}
        send_data["number_of_branches"] = settings["number_of_branches"]
        send_message("start", send_data)
    end

    -- if no progress, check for supplies and start
    if (progress["task"] == nil) then
    -- Verify starting fuel level
    get_fuel_and_supplies_if_needed(settings["min_continue_fuel_level"])

    -- Dig to branch 1
    dig_out_trunk(settings["branch_between_distance"])
    elseif (progress["task"] == "trunk") then

    end

    -- dig branchs
    for i=progress["branch"]["current"],settings["number_of_branches"] do
        update_progress("branch", i, "current")
        term.setCursorPos(unpack(current_branch_location))
        color_write(string.format("%3d", progress["branch"]["current"]), colors.yellow)
        -- if transmit, update current branch
        if (settings["transmit_progress"]) then
            local send_data = {}
            send_data["branch"] = progress["branch"]["current"]
            send_message("branch_update", send_data)
        end
        log("branch: "..progress["branch"]["current"])
        -- dig branch
        dig_branch()
        -- dig to next branch
        dig_out_trunk(settings["branch_between_distance"]+1)
    end
    -- go back to start
    set_task("Returning", "")
    goto_position({0, 0, 0}, 2)
    --if transmit, sent exit signal
    if (settings["transmit_progress"]) then
        send_message("exit")
    end
    -- delete progress file
    fs.delete(progress_file)
    -- wait for user's acknowledgement of completion
    wait_for_enter()
    term.setCursorPos(1,1)
    term.clear()
end

local function run_receiver_main()
    local term_object = term

    -- check for transmitter
    while (transmitter == nil) do
        -- if transmitter_side is not nil, for check on that side
        if not (settings["transmitter_side"] == nil) then
            transmitter = peripheral.wrap(settings["transmitter_side"])
            -- if no transmitter, print error to add one
            if (transmitter == nil) then
                print_error(message_error_modem_side, false, true)
            end
        else
            -- look for transmitter
            transmitter = peripheral.find("modem")
            -- if no transmitter, print error to add one
            if (transmitter == nil) then
                print_error(message_error_modem, false, true)
            end
        end
    end

    -- verify it is a wireless transmitter
    if not (transmitter.isWireless()) then
        print_error(message_error_modem_wireless, false, true)
    end

    if (settings["redirect_to_monitor"]) then
        local temp_monitor = nil
        if not (settings["monitor_side"] == nil) then
            if not (settings["monitor_side"] == false) then
                temp_monitor = peripheral.wrap(settings["monitor_side"])
            end
        else
            temp_monitor = peripheral.find("monitor")
        end

        if not (temp_monitor == nil) then
            term.redirect(temp_monitor)
        else
            settings["redirect_to_monitor"] = false
        end
    end

    term_size = {term.getSize()}

    -- print title
    term.clear()
    term.setCursorPos(1,1)
    title = program_name.." v"..program_version
    if (term_size[1] < string.len(title)+17) then
        ids_line = 2
        if (term_size[1] < string.len(title)) or (term_size[1] < 17) then
            print_error(message_error_display_width, true)
        end
    end
    if (term_size[2] < 12) then
        print_error(message_error_display_height, true)
    end
    current_branch_location = {term_size[1]-9,ids_line+2}
    color_write(title, colors.lime)
    term.setCursorPos(1,ids_line+2)
    color_write("Waiting for turtle...", colors.magenta)

    -- open channel for listening
    transmitter.open(settings["transmit_channel"])
    -- listen for events
    do_loop = true
    while (do_loop) do
        local event, modemSide, senderChannel,
            replyChannel, message, senderDistance = os.pullEvent("modem_message")

        local retransmit = false

        local receiver_data = textutils.unserialize(message)
        receiver_data["retransmit_id"] = receiver_data["retransmit_id"] or nil

        temp_seralized = string.gsub(textutils.serialize(receiver_data), "[\n ]", "")
        log("receive: "..temp_seralized)

        -- start event, can only be ran if waiting for turtle (paired_id == nil)
        if (receiver_data["type"] == "start") and (progress["paired_id"] == nil) then
            update_progress("paired_id", receiver_data["turtle_id"])
            update_progress("retransmit_id", receiver_data["retransmit_id"])
            update_progress("branch", receiver_data["branch"] or progress["branch"]["current"], "current")
            settings["number_of_branches"] = receiver_data["number_of_branches"]

            if not (progress["retransmit_id"] == nil) then
                term.setCursorPos(term_size[1]-16,ids_line)
            else
                term.setCursorPos(term_size[1]-10,ids_line)
            end
            color_write(string.format("%5d", os.computerID()), colors.white)
            color_write(":", colors.yellow)
            if not (progress["retransmit_id"] == nil) then
                color_write(string.format("%5d", progress["retransmit_id"]), colors.green)
                color_write(":", colors.yellow)
            end
            color_write(string.format("%5d", progress["paired_id"]), colors.red)

            term.setCursorPos(1,ids_line+2)
            clear_line()
            color_write("Current Branch", colors.cyan)
            term.setCursorPos(unpack(current_branch_location))
            color_write(string.format("%3d", progress["branch"]["current"]), colors.yellow)
            term.setCursorPos(term_size[1]-5,ids_line+2)
            color_write("of", colors.white)
            term.setCursorPos(term_size[1]-2,ids_line+2)
            color_write(string.format("%3d", settings["number_of_branches"]), colors.magenta)
            retransmit = true
        -- branch_update event
        elseif (receiver_data["type"] == "branch_update") and (progress["paired_id"] == receiver_data["turtle_id"]) and (progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            update_progress("branch", receiver_data["branch"], "current")
            term.setCursorPos(unpack(current_branch_location))
            color_write(string.format("%3d", progress["branch"]["current"]), colors.yellow)
            send_confrim(receiver_data["turtle_id"])
            retransmit = true
        -- task event
        elseif (receiver_data["type"] == "task") and (progress["paired_id"] == receiver_data["turtle_id"]) and (progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            set_task(receiver_data["main"], receiver_data["sub"])
            retransmit = true
        -- error event
        elseif (receiver_data["type"] == "check") and (progress["paired_id"] == receiver_data["turtle_id"]) and (progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            send_confrim(receiver_data["turtle_id"])
            retransmit = true
        elseif (receiver_data["type"] == "error") and (progress["paired_id"] == receiver_data["turtle_id"]) and (progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            -- clear previous error
            if (receiver_data["error"] == message_error_clear) then
                term.setCursorPos(1, (term_size[2]-2))
                clear_line()
            -- print error
            else
                print_error(receiver_data["error"])
            end
            retransmit = true
        -- exit event
        elseif (receiver_data["type"] == "exit") and (progress["paired_id"] == receiver_data["turtle_id"]) and (progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            do_loop = false
            retransmit = true
        end

        if (settings["transmit_progress"] and retransmit) then
            receiver_data["retransmit_id"] = nil
            send_message(receiver_data["type"], receiver_data)
        end
    end
    transmitter.close(settings["transmit_channel"])
    set_task("Finished", "")
    wait_for_enter()
    term.setCursorPos(1,1)
    term.clear()
    transmitter.closeAll()

    if (settings["redirect_to_monitor"]) then
        term.redirect(term_object)
    end
end

local function main()
    init_settings()
    init_progress()
    fs.delete(log_file)
    if not (turtle == nil) then
        run_turtle_main()
    else
        run_receiver_main()
    end
end

main()