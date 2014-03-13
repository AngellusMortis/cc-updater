--[[
##name: ]]--
local program_name = "Branch Mining"
--[[
##file: am/turtle/branch.lua
##version: ]]--
local program_version = "1.3.0"
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

Directions (T = turtle):
    2

3   T   1

    0

##planned:
#mine ores deeper then one level
#save/resume feature
#automated updates

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

-- debug settings
local debug = false
local log_file = ".branch.log"

-- global variables
local use_coal = args[2] or false
-- mine config
local number_of_branches = args[3] or 5
local branch_between_distance = args[4] or 2
local branch_length = args[5] or 52
local torch_distance = args[6] or 10
local branch_connector_distance = args[7] or 26
local trunk_width = 2
local trunk_height = 3

-- turtle(slots) config
-- chest and torch slots are to keep track of supplies
local torch_slot = 1
local chest_slot = 2
-- cobblestone slot use to place so torch can be placed
local cobblestone_slot = 3
-- used for testing for ores (anything not in this list is considered an "ore")
-- by default should be cobblestone, dirt, stone, and gravel
local test_slots = {}

-- level of coal to reach when refueling
local min_continue_fuel_level = 500
-- ticks between attempts to move (see force_forward, force_up, and force_down)
local tick_delay = 2

-- wireless broadcast settings
-- do broadcast
-- on receiver will determine wether or not to retransmit (range extension)
local transmit_progress = true
-- variable to hold wireless modem
local transmitter = nil
-- if you have multiple modems (wired and wireless), set this to force
--  side of modem if perhiperal.find() is picking the wired one
local transmitter_side = nil
-- should not need to change these
local transmit_channel = 60000
local receive_channel = 60001

-- attempt to redirect to monitor for receiver?
--  side monitor if perhiperal.find() is picking an undesired one (works with networked monitors)
local redirect_to_monitor = true
local monitor_side = args[1] or nil

-- error messages
local has_error = false
local message_press_enter = "Press ENTER to continue..."
local message_error_clear = "__clear"
local message_error_file = "File could not be opened"
local message_error_move = "Cannot move"
local message_error_dig = "Cannot dig"
local message_error_fuel = "Out of fuel"
local message_error_chest = "Out of chests"
local message_error_torch = "Out of torches"
local message_error_modem = "No modem connected"
local message_error_modem_side = "No modem connected ("..tostring(transmitter_side)..")"
local message_error_modem_wireless = "Modem cannot do wireless"
local message_error_failed_to_place_chest = "Could not place chest"
local message_error_failed_to_place_torch = "Could not place torch"
local message_error_failed_to_place_torch_wall = "Could not place wall for torch"
local message_error_failed_to_send_message = "Failed to send message"
local message_error_display_width = "Display is not wide enough"
local message_error_display_height = "Display is not tall enough"
local message_error_trunk = "trunk_height must be 2 or 3"

-- settings for progress for resuming (not finished, do not touch)
local progress_file = ".branch.progress"
local progress = {}

-- random variables
local ids_line = 1

-- prototypes (only as needed)
local print_error = nil

-- functions
-- init progress variable
local function init_progress()
    progress = {}
    progress["task"] = nil
    progress["position"] = {{0, 0, 0}, 2}
    progress["branch"] = {}
    progress["branch"]["current"] = 1
    progress["trunk"] = {}
    progress["trunk"]["remaining"] = nil
    if (turtle == nil) then
        progress["paired_id"] = nil
        progress["retransmit_id"] = nil
    end
end
local function log(message)
    if (debug) then
        handle = nil
        if (fs.exists(log_file)) then
            handle = fs.open(log_file, "a")
        else
            handle = fs.open(log_file, "w")
        end
        if (handle == nil) then
            debug = false
            print_error("Could not open log file")
        else
            handle.writeLine("["..tostring(os.time()).."]: "..tostring(message))
            handle.close(message_error_file)
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
    transmitter.transmit(transmit_channel, receive_channel, textutils.serialize(message_data))

    if (message_type == "check") or (message_type == "branch_update") then
        os.startTimer(3)
        local do_loop = true
        -- open channel for listening
        if (turtle == nil) then
            transmitter.close(transmit_channel)
        end
        transmitter.open(receive_channel)
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
                message_data["number_of_branches"] = number_of_branches
                message_data["branch"] = progress["branch"]["current"]
                send_message("start", message_data)
            end
        end
        transmitter.close(receive_channel)
        if (turtle == nil) then
            transmitter.open(transmit_channel)
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
    if (has_error) then
        term_size = {term.getSize()}
        term.setCursorPos(1, (term_size[2]-2))
        clear_line()
        has_error = false
    end
    local confrim_data = {}
    confrim_data["type"] = "confrim"
    confrim_data["turtle_id"] = id
    if not (progress["retransmit_id"] == nil) then
        confrim_data["retransmit_id"] = progress["retransmit_id"]
    end
    temp_seralized = string.gsub(textutils.serialize(confrim_data), "[\n ]", "")
    log("confrim: "..temp_seralized)
    transmitter.transmit(receive_channel, transmit_channel, textutils.serialize(confrim_data))
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
    if (not (turtle == nil)) and (transmit_progress) then
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
            if (transmit_progress) then
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
-- writes current progress to progress file
local function write_progress()
    temp_seralized = textutils.serialize(progress)
    handle = fs.open(progress_file, "wb")

    if (handle == nil) then
        print_error(message_error_file, true)
    else
        handle.write(temp_seralized)
        handle.close()
    end
    temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
    log("write: "..temp_seralized)
end
-- reads progress from progress file
local function read_progress()
    handle = fs.open(progress_file, "r")

    if not (handle == nil) then
        temp_seralized = handle.readAll()
        progress = textutils.unserialize(temp_seralized)
        temp_seralized = string.gsub(temp_seralized, "[\n ]", "")
        log("write: "..temp_seralized)
        handle.close()

        if (progress == nil) then
            init_progress()
        end
    end
end
-- updates value in progress variable (DO NOT DO IT MANUALLY)
local function update_progress(progress_item, new_value, index_1, index_2)
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
    if not (turtle == nil) then
        write_progress()
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
    if (not (turtle == nil)) and (transmit_progress) then
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
-- force the turtle to move forward
--  kills anything in way
--  digs anything out of the way
--  can generate error if unable to move after 10 tries and block in front or 50 tries (mob)
--  updates progress["position"]
local function force_forward()
    count = 0
    while not (turtle.forward()) do
        turtle.select(1)
        turtle.attack()
        turtle.dig()
        count = count + 1
        if (count > 10 and turtle.detect()) or (count > 50) then
            print_error(message_error_move)
            count = 0
        end
        os.sleep(0.05 * tick_delay)
    end

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
-- force turtle to dig (keeps digging until no block)
local function force_dig_forward()
    count = 0
    while (turtle.detect()) do
        turtle.select(1)
        turtle.attack()
        turtle.dig()
        count = count + 1
        if (count > 10 and turtle.detect()) or (count > 50) then
            print_error(message_error_dig.." (forward)")
            count = 0
        end
        os.sleep(0.5 * tick_delay)
    end
end
-- force the turtle to move up
--  digs anything out of the way
--  can generate error if unable to move after 10 tries
--  updates progress["position"]
local function force_up()
    count = 0
    while not (turtle.up()) do
        turtle.select(1)
        turtle.digUp()
        count = count + 1
        if (count > 10) then
            print_error(message_error_move)
            count = 0
        end
        os.sleep(0.5 * tick_delay)
    end
    update_progress("position", progress["position"][1][2] + 1, 1, 2)
end
-- force turtle to dig up (keeps digging until no block)
local function force_dig_up()
    count = 0
    while (turtle.detectUp()) do
        turtle.select(1)
        turtle.digUp()
        count = count + 1
        if (count > 10) then
            print_error(message_error_dig.." (up)")
            count = 0
        end
        os.sleep(0.5 * tick_delay)
    end
end
-- force the turtle to move down
--  digs anything out of the way
--  can generate error if unable to move after 10 tries
--  updates progress["position"]
local function force_down()
    count = 0
    while not (turtle.down()) do
        turtle.select(1)
        turtle.digDown()
        count = count + 1
        if (count > 10) then
            print_error(message_error_move)
            count = 0
        end
        os.sleep(0.5 * tick_delay)
    end
    update_progress("position", progress["position"][1][2] - 1, 1, 2)
end
-- force turtle to dig down (keeps digging until no block)
local function force_dig_down()
    count = 0
    while (turtle.detectDown()) do
        turtle.select(1)
        turtle.digDown()
        count = count + 1
        if (count > 10) then
            print_error(message_error_dig.." (down)")
            count = 0
        end
        os.sleep(0.5 * tick_delay)
    end
end
-- uses all fuel in inventory
local function use_all_fuel()
    for i=1,16 do
        turtle.refuel(64)
    end
end
-- moves turtle to coords and facing direction
--   allows for both negative and positive coords for X and Y, but NOT Z
local function goto_position(coord, facing)
    temp_seralized = string.gsub(textutils.serialize({coord, facing}), "[\n ]", "")
    log("goto: "..temp_seralized)
    -- move turtle out of branch connector if in one
    branchs_z = {branch_between_distance}
    for i=2,number_of_branches do
        table.insert(branchs_z, branchs_z[#branchs_z]+branch_between_distance+1)
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
    return math.abs(progress["position"][1][1]-(trunk_width-1))+math.abs(progress["position"][1][2])+math.abs(progress["position"][1][3])
end
-- test if it is nesscary to get resources
local function get_fuel_and_supplies_if_needed(required_fuel)
    set_task("Supplies", "Checking")

    -- check fuel
    local previous_position = {{progress["position"][1][1], progress["position"][1][2], progress["position"][1][3]}, progress["position"][2]}
    if (turtle.getFuelLevel() < required_fuel) then
        set_task("Supplies", "Fuel")
        goto_position({(trunk_width-1), 0, 0}, 1)
        need_fuel = (turtle.getFuelLevel() < min_continue_fuel_level)
        while (need_fuel) do
            if not (turtle.suck()) then
                print_error(message_error_fuel)
            end
            use_all_fuel()
            need_fuel = (turtle.getFuelLevel() < min_continue_fuel_level)
        end
    end

    -- check torches/chests
    set_task("Supplies", "Checking")
    local need_chests = (turtle.getItemCount(chest_slot) <= 1)
    local need_torches = (turtle.getItemCount(torch_slot) <= (((branch_length/torch_distance)+1)*2))
    if (need_chests or need_torches) then
        set_task("Supplies", "Items")
        goto_position({0, 0, 0}, 3)

        -- resupply chests
        while (need_chests) do
            set_task("Supplies", "Chests")
            turtle.select(chest_slot)
            turtle.dropUp()
            turtle.suckUp()
            need_chests = (turtle.getItemCount(chest_slot) <= 1)
            if (need_chests) then
                print_error(message_error_chest)
            end
        end
        -- resupply torches
        while (need_torches) do
            set_task("Supplies", "Torches")
            turtle.select(torch_slot)
            turtle.drop()
            turtle.suck()
            need_torches = (turtle.getItemCount(torch_slot) <= (((branch_length/torch_distance)+1)*2))
            if (need_torches) then
                print_error(message_error_torch)
            end
        end
    end

    -- return to previous position
    set_task("Supplies", "Returning")
    goto_position(unpack(previous_position))
end

-- main functions
-- check for ores and mine them if they are there
--   will mine out anything that is not stone, dirt, gravel, or cobblestone
--   if do_down, will check block below turtle, otherwise, will check block above
local function dig_ores(do_down)
    previous_face = progress["position"][2]

    if do_down then
        -- down
        if (turtle.detectDown()) then
            is_block = {false, false, false, false}
            for i=1,#test_slots do
                turtle.select(test_slots[i])
                is_block[i] = turtle.compareDown()
            end
            if not (is_block[1] or is_block[2] or is_block[3] or is_block[4]) then
                force_dig_down()
            end
        end
    else
        -- up
        if (turtle.detectUp()) then
            is_block = {false, false, false, false}
            for i=1,#test_slots do
                turtle.select(test_slots[i])
                is_block[i] = turtle.compareUp()
            end

            if not (is_block[1] or is_block[2] or is_block[3] or is_block[4]) then
                force_dig_up()
            end
        end
    end

    -- sides
    for i,v in ipairs({0, 2}) do
        rotate(v)
        if (turtle.detect()) then
            is_block = {false, false, false, false}
            for i=1,#test_slots do
                turtle.select(test_slots[i])
                is_block[i] = turtle.compare()
            end
            if not (is_block[1] or is_block[2] or is_block[3] or is_block[4]) then
                force_dig_forward()
            end
        end
    end

    rotate(previous_face)
end
-- digs out part of trunk of length
local function dig_out_trunk(length)
    log("trunk: "..length)
    -- check for needed supplies
    required_fuel = get_distance_from_fuel() + (length * ((trunk_height-1) * 2) + trunk_width) * 2
    get_fuel_and_supplies_if_needed(required_fuel)

    set_task("Trunk", string.format("%3d%%", 0))
    rotate(2)
    for i=1,length do
        force_forward()
        if (trunk_height == 3) then
            force_up()
        end
        turtle.select(chest_slot)
        if not (turtle.compareUp()) then
            force_dig_up()
        end
        rotate(1)
        for i=1,(trunk_width-1) do
            force_forward()
            turtle.select(chest_slot)
            if not (turtle.compareUp()) then
                force_dig_up()
            end
            if (trunk_height == 3) then
                force_dig_down()
            end
        end
        rotate(3)
        for i=1,(trunk_width-1) do
            force_forward()
        end
        if (trunk_height == 3) then
            force_down()
        end
        rotate(2)
        set_task("Trunk", string.format("%3d%%", (i/length)*100))
    end
end
-- digs out a single branch
local function dig_branch()
    -- check for needed supplies
    required_fuel = get_distance_from_fuel() + ((branch_length + (branch_length/branch_connector_distance)*(branch_between_distance*2))*2 + trunk_width)*2
    get_fuel_and_supplies_if_needed(required_fuel)

    set_task("Branch", string.format("%3d%%", 0))
    -- each path through loop is one half of branch (each side of trunk)
    for x=1,2 do
        if (x == 1) then
            rotate(3)
        else
            rotate(1)
        end
        -- place supply chest
        force_up()
        turtle.select(chest_slot)
        if not (turtle.compareUp()) then
            force_up()
            force_dig_up()
            force_down()
            if not (turtle.placeUp()) then
                print_error(message_error_failed_to_place_chest)
            end
        end
        -- mine out top of branch
        for i=1,branch_length do
            set_task("Branch", string.format("%3d%%", (x-1)*50+((i/branch_length)*100)/4))
            force_forward()
            dig_ores(false)

            -- mine out branch connectors
            if (i%branch_connector_distance) == 0 then
                rotate(2)
                for j=1,branch_between_distance do
                    force_forward()
                    force_dig_down()
                end
                rotate(0)
                for j=1,branch_between_distance do
                    force_forward()
                end
                if (x == 1) then
                    rotate(3)
                else
                    rotate(1)
                end
            end

            -- verfiy blocks are in place for torches (placed later)
            if (((i%torch_distance) == 1)) then
                if (transmit_progress) then
                    send_message("check")
                end
                rotate(2)
                if (not (turtle.detect())) or (not (turtle.detectUp())) then
                    if (turtle.getItemCount(cobblestone_slot) > 3) then
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
        for i=1,branch_length do
            set_task("Branch", string.format("%3d%%", (x-1)*50+((i/branch_length)*100)/4+25))
            force_forward()
            dig_ores(true)

            -- place torches
            if (i%torch_distance) == 1 then
                if (transmit_progress) then
                    send_message("check")
                end
                turtle.select(torch_slot)
                if not (turtle.placeUp()) then
                    print_error(message_error_failed_to_place_torch, false, false)
                end
            end
        end

        set_task("Emptying", string.format("%3d%%", 0))
        force_up()
        -- use fuel is told too
        if (use_coal) then
            use_all_fuel()
        end
        -- empty out inventory (except for supplies)
        for i=1,16 do
            set_task("Emptying", string.format("%3d%%", (i/16)*100))
            turtle.select(i)
            if (i == torch_slot) or (i == chest_slot) then
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
        set_task("Branch", string.format("%3d%%", x*50))
        force_down()

        -- move to current location to continue
        if (x == 1) then
            rotate(1)
            for i=1,(trunk_width-1) do
                force_forward()
            end
        else
            rotate(3)
            for i=1,(trunk_width-1) do
                force_forward()
            end
        end
    end

    rotate(2)
end

local function run_turtle_main()
    -- verify trunk height (program not adjusted for otherwise)
    if not (trunk_height==2 or trunk_height==3) then
        print_error(message_error_trunk)
    end
    -- check for wireless modem, disable transmit if not there
    if (transmit_progress) then
        transmitter = peripheral.find("modem")
        if (transmitter == nil) then
            transmit_progress = false
        end
    end

    -- print title
    term_size = {term.getSize()}
    current_branch_location = {term_size[1]-9,ids_line+2}
    term.clear()
    term.setCursorPos(1,1)
    color_write(program_name.." v"..program_version, colors.lime)
    -- if transmit, print computer ID to indicate it
    if (transmit_progress) then
        term.setCursorPos(term_size[1]-4,ids_line)
        color_write(string.format("%5d", os.computerID()), colors.white)
    end

    -- read progress from last attempt
    read_progress()

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
        color_write("Put cobblestone in slot "..cobblestone_slot, colors.cyan)
        term.setCursorPos(1,ids_line+5)
        color_write("Put any \"do not mine\" blocks in others", colors.cyan)
        term.setCursorPos(3,ids_line+6)
        color_write("i.e.: cobblestone, stone,", colors.cyan)
        term.setCursorPos(4,ids_line+7)
        color_write("dirt, gravel", colors.cyan)
        wait_for_enter()
        -- add items in all slots but 1 and 2 to test_slots
        for i=3,16 do
            if (turtle.getItemCount(i) > 0) then
                test_slots[#test_slots+1] = i
            end
        end
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

    -- print current branch data
    term.setCursorPos(1,ids_line+2)
    color_write("Current Branch", colors.cyan)
    term.setCursorPos(unpack(current_branch_location))
    color_write(string.format("%3d", progress["branch"]["current"]), colors.yellow)
    term.setCursorPos(term_size[1]-5,ids_line+2)
    color_write("of", colors.white)
    term.setCursorPos(term_size[1]-2,ids_line+2)
    color_write(string.format("%3d", number_of_branches), colors.magenta)

    -- if transmit, send start signal to receiver
    if (transmit_progress) then
        local send_data = {}
        send_data["number_of_branches"] = number_of_branches
        send_message("start", send_data)
    end

    -- if no progress, check for supplies and start
    if (progress["task"] == nil) then
    -- Verify starting fuel level
    get_fuel_and_supplies_if_needed(min_continue_fuel_level)

    -- Dig to branch 1
    dig_out_trunk(branch_between_distance)
    elseif (progress["task"] == "trunk") then

    end

    -- dig branchs
    for i=progress["branch"]["current"],number_of_branches do
        update_progress("branch", i, "current")
        term.setCursorPos(unpack(current_branch_location))
        color_write(string.format("%3d", progress["branch"]["current"]), colors.yellow)
        -- if transmit, update current branch
        if (transmit_progress) then
            local send_data = {}
            send_data["branch"] = progress["branch"]["current"]
            send_message("branch_update", send_data)
        end
        log("branch: "..progress["branch"]["current"])
        -- dig branch
        dig_branch()
        -- dig to next branch
        dig_out_trunk(branch_between_distance+1)
    end
    -- go back to start
    set_task("Returning", "")
    goto_position({0, 0, 0}, 2)
    --if transmit, sent exit signal
    if (transmit_progress) then
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
        if not (transmitter_side == nil) then
            transmitter = peripheral.wrap(transmitter_side)
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

    if (redirect_to_monitor) then
        local temp_monitor = nil
        if not (monitor_side == nil) then
            if not (monitor_side == false) then
                temp_monitor = peripheral.wrap(monitor_side)
            end
        else
            temp_monitor = peripheral.find("monitor")
        end

        if not (temp_monitor == nil) then
            term.redirect(temp_monitor)
        else
            redirect_to_monitor = false
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
    transmitter.open(transmit_channel)
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
            number_of_branches = receiver_data["number_of_branches"]

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
            color_write(string.format("%3d", number_of_branches), colors.magenta)
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

        if (transmit_progress and retransmit) then
            receiver_data["retransmit_id"] = nil
            send_message(receiver_data["type"], receiver_data)
        end
    end
    transmitter.close(transmit_channel)
    set_task("Finished", "")
    wait_for_enter()
    term.setCursorPos(1,1)
    term.clear()
    modem.closeAll()

    if (redirect_to_monitor) then
        term.redirect(term_object)
    end
end

local function main()
    init_progress()
    fs.delete(log_file)
    if not (turtle == nil) then
        run_turtle_main()
    else
        run_receiver_main()
    end
end

main()