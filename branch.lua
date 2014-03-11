--[[

##file: am/turtle/branch.lua
##version: 1.0.4

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



##parameters:
args[1]: display to redreict to (side or name) (default: nil) enter "false" to disable redirection
args[2]: Use collected coal as fuel (default: false)
args[3]: Number of branches
args[4]: Number of blocks between each branch (default: 2)
args[5]: Length of branch in blocks (default: 52)
args[6]: distance between torches (default: 10)
args[7]: Number of blocks between connections between branches (default: 26)

--]]

local args = { ... }

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
-- test slots should have 1 stone, gravel, dirt, and cobblestone in each
-- used for testing for ores
local torch_slot = 1
local chest_slot = 2
local cobblestone_slot = 3
local test_slots = {cobblestone_slot, 4, 5, 6}

-- level of coal to reach when refueling
local min_continue_fuel_level = 500
-- ticks between attempts to move (see force_forward, force_up, and force_down)
local tick_delay = 2

-- wireless broadcast settings
-- do broadcast
local transmit_progress = true
-- variable to hold wireless modem
local transmitter = nil
-- if you have multiple modems (wired and wireless), set this to force 
--  side of modem if perhiperal.find() is picking the wired one
local transmitter_side = nil
-- should not need to change these
local transmit_channel = 60000
local receive_channel = 60001

-- attempt to redirect to monitor for reciever?
--  side monitor if perhiperal.find() is picking an undesired one (works with networked monitors)
local redirect_to_monitor = true
local monitor_side = args[1] or nil

-- error messages
local message_press_enter = "Press ENTER to continue..."
local message_error_clear = "__clear"
local message_error_file = "File could not be opened"
local message_error_move = "Cannot move"
local message_error_fuel = "Out of fuel"
local message_error_chest = "Out of chests"
local message_error_torch = "Out of torches"
local message_error_modem = "No modem connected"
local message_error_modem_side = "No modem connected ("..tostring(transmitter_side)..")"
local message_error_modem_wireless = "Modem cannot do wireless"

-- settings for progress for resuming (not finished, do not touch)
local progress_file = ".branch.progress"
local progress = {}


-- functions
-- Force clears the current terminal line and then 
--  sets it to first positions (was having trouble with term.clearLine())
local function init_progress()
    progress = {}
    progress["task"] = nil 
    progress["position"] = {{0, 0, 0}, 2}
    progress["branch"] = {}
    progress["branch"]["current"] = 1
    progress["trunk"] = {}
    progress["trunk"]["remaining"] = nil
end
local function clear_line()
    pos = {term.getCursorPos()}
    term_size = {term.getSize()}
    term.setCursorPos(1, pos[2])
    term.write(string.rep(" ",term_size[1]))
    term.setCursorPos(1, pos[2])
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
local function print_error(error, fatal, wait)
    fatal = fatal or false
    if (turtle == nil) then
        wait = wait or false
    else
        wait = wait or true
    end

    -- if turtle and transmit is on, send to reciever
    if (not (turtle == nil)) and (transmit_progress) then
        data = {}
        data["type"] = "error"
        data["id"] = os.computerID()
        data["error"] = error
        transmitter.transmit(transmit_channel, receive_channel, textutils.serialize(data))
    end

    -- if fatal, terminate
    if (fatal) then
        error(error)
    else
        term_size = {term.getSize()}
        term.setCursorPos(1, (term_size[2]-2))
        clear_line()
        color_write("ERROR: "..error, colors.red)
        -- if turtle, wait for user to press ENTER
        if not (turtle == nil) then
            if (wait) then
                wait_for_enter()
                term.setCursorPos(1, (term_size[2]-2))
                clear_line()
            end
            data = {}
            -- if transmit, tell reciever error has been cleared
            if (transmit_progress) then
                data["type"] = "error"
                data["id"] = os.computerID()
                data["error"] = message_error_clear
                transmitter.transmit(transmit_channel, receive_channel, textutils.serialize(data))
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
    handle = fs.open(progress_file, "wb")

    if (handle == nil) then
        print_error(message_error_file, true)
    else
        handle.write(textutils.serialize(progress))
        handle.close()
    end
end
-- reads progress from progress file
local function read_progress()
    handle = fs.open(progress_file, "r")

    if not (handle == nil) then
        progress = textutils.unserialize(handle.readAll())
        handle.close()

        if (progress == nil) then
            init_progress()
        end
    end
end
-- updates value in progress variable (DO NOT DO IT MANUALLY)
local function update_progress(progress_item, new_value, index_1, index_2)
    if (progress_item == "position") and (index_2 == nil) then
        progress[progress_item][index_1] = new_value
        elseif (progress_item == "position") then
            progress[progress_item][index_1][index_2] = new_value
            elseif (progress_item == "branch") then
                progress[progress_item][index_1] = new_value
            else
                progress[progress_item] = new_value
            end
            write_progress()
        end
-- set current task for turtle (just for visual)
local function set_task(main, sub)
    update_progress("task", main)

    term_size = {term.getSize()}
    term.setCursorPos(1,5)
    clear_line()
    color_write(main, colors.cyan)
    term.setCursorPos(term_size[1]-((#sub)-1),5)
    color_write(sub, colors.yellow)

-- if turtle and transmit, send task data to receivers
if (not (turtle == nil)) and (transmit_progress) then
    data = {}
    data["type"] = "task"
    data["id"] = os.computerID()
    data["main"] = main
    data["sub"] = sub
    transmitter.transmit(transmit_channel, receive_channel, textutils.serialize(data))
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
-- uses all fuel in inventory
local function use_all_fuel()
    for i=1,16 do
        turtle.refuel(64)
    end
end
-- moves turtle to coords and facing direction
--   allows for both negative and positive coords for X and Y, but NOT Z
local function goto_position(coord, facing)
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
is_block = {false, false, false, false}
for i=1,4 do
    turtle.select(test_slots[i])
    is_block[i] = turtle.compareDown()
end
if not (is_block[1] or is_block[2] or is_block[3] or is_block[4]) then
    turtle.digDown()
end
else
-- up
is_block = {false, false, false, false}
for i=1,4 do
    turtle.select(test_slots[i])
    is_block[i] = turtle.compareUp()
end
if not (is_block[1] or is_block[2] or is_block[3] or is_block[4]) then
    turtle.digUp()
end
end

-- sides
for i,v in ipairs({0, 2}) do
    is_block = {false, false, false, false}
    rotate(v)
    for i=1,4 do
        turtle.select(test_slots[i])
        is_block[i] = turtle.compare()
    end
    if not (is_block[1] or is_block[2] or is_block[3] or is_block[4]) then
        turtle.dig()
    end
end

rotate(previous_face)
end
-- digs out part of trunk of length
local function dig_out_trunk(length)
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
    turtle.digUp()
    rotate(1)
    for i=1,(trunk_width-1) do
        force_forward()
        turtle.digUp()
        if (trunk_height == 3) then
            turtle.digDown()
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
force_up()
turtle.digUp()
force_down()
turtle.select(chest_slot)
turtle.placeUp()
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
        turtle.digDown()
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
if ((i%torch_distance) == 1) and (turtle.getItemCount(cobblestone_slot) > 2) then
    rotate(0)
    turtle.place()
    rotate(2)
    turtle.place()
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
    turtle.select(torch_slot)
    turtle.placeUp()
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
        elseif (i == test_slots[1]) or (i == test_slots[2]) or (i == test_slots[3]) or (i == test_slots[4]) then
            to_drop = turtle.getItemCount(i)-1
            turtle.dropUp(to_drop)
        else
            turtle.dropUp(to_drop)
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
    error("trunk_height can only be 2 or 3")
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
current_branch_location = {term_size[1]-9,3}
term.clear()
term.setCursorPos(1,1)
color_write("Branch Mining", colors.lime)
-- if transmit, print computer ID to indicate it
if (transmit_progress) then
    term.setCursorPos(term_size[1]-4,1)
    color_write(string.format("%5d", os.computerID()), colors.red)
end 

-- read progress from last attempt
read_progress()

-- if no progress, start new
if (progress["task"] == nil) then
-- verfiy there is at least __some__ fuel to get started
while (turtle.getFuelLevel() == 0) do
    use_all_fuel()
    if (turtle.getFuelLevel() == 0) then
        term.setCursorPos(1,4)
        color_write("Put at least one piece of fuel in", colors.cyan)
        wait_for_enter() 
        term.setCursorPos(1,4)
        clear_line()
    end
end

-- remind use to have stone, dirt, gravel, and cobblestone
term.setCursorPos(1,4)
color_write("Put cobblestone in slot "..test_slots[1], colors.cyan)
term.setCursorPos(1,5)
color_write("Put stone, dirt, and gravel in slots ", colors.cyan)
term.setCursorPos(4,6)
color_write(test_slots[2]..", "..test_slots[3]..", and "..test_slots[4], colors.cyan)
wait_for_enter() 
term.setCursorPos(1,4)
clear_line()
term.setCursorPos(1,5)
clear_line()
term.setCursorPos(1,6)
clear_line()
end

-- print current branch data
term.setCursorPos(1,3)
color_write("Current Branch", colors.cyan)
term.setCursorPos(unpack(current_branch_location))
color_write(string.format("%3d", progress["branch"]["current"]), colors.yellow)
term.setCursorPos(term_size[1]-5,3)
color_write("of", colors.white)
term.setCursorPos(term_size[1]-2,3)
color_write(string.format("%3d", number_of_branches), colors.magenta)

-- if transmit, send start signal to reciever
if (transmit_progress) then
    data = {}
    data["type"] = "start"
    data["id"] = os.computerID()
    data["number_of_branches"] = number_of_branches
    transmitter.transmit(transmit_channel, receive_channel, textutils.serialize(data))
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
    color_write(string.format("%3d", i), colors.yellow)
-- if transmit, update current branch
if (transmit_progress) then
    data = {}
    data["type"] = "branch_update"
    data["id"] = os.computerID()
    data["branch"] = i
    transmitter.transmit(transmit_channel, receive_channel, textutils.serialize(data))
end
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
    data = {}
    data["type"] = "exit"
    data["id"] = os.computerID()
    transmitter.transmit(transmit_channel, receive_channel, textutils.serialize(data))
end
-- delete progress file
fs.delete(progress_file)
-- wait for user's acknowledgement of completion
wait_for_enter()
term.setCursorPos(1,1)
term.clear()
end

local function run_reciever_main()
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

-- open channel for listening
transmitter.open(transmit_channel)

term_size = {term.getSize()}
current_branch_location = {term_size[1]-9,3}

-- print title
term.clear()
term.setCursorPos(1,1)
color_write("Branch Mining", colors.lime)
term.setCursorPos(1,3)
color_write("Waiting for turtle...", colors.magenta)

-- ID of turtle in which to listen for messages for
paired_id = nil 

-- listen for events
do_loop = true
while (do_loop) do
    local event, modemSide, senderChannel, 
    replyChannel, message, senderDistance = os.pullEvent("modem_message")

    data = textutils.unserialize(message)

-- start event, can only be ran if waiting for turtle (paired_id == nil)
if (data["type"] == "start") and (paired_id == nil) then
    paired_id = data["id"]
    term.setCursorPos(term_size[1]-4,1)
    color_write(string.format("%5d", paired_id), colors.red)

    term.setCursorPos(1,3)
    clear_line()
    color_write("Current Branch", colors.cyan)
    term.setCursorPos(unpack(current_branch_location))
    color_write(string.format("%3d", 0), colors.yellow)
    term.setCursorPos(term_size[1]-5,3)
    color_write("of", colors.white)
    term.setCursorPos(term_size[1]-2,3)
    color_write(string.format("%3d", data["number_of_branches"]), colors.magenta)
-- branch_update event
elseif (data["type"] == "branch_update") and (paired_id == data["id"]) then
    term.setCursorPos(unpack(current_branch_location))
    color_write(string.format("%3d", data["branch"]), colors.yellow)
-- task event
elseif (data["type"] == "task") and (paired_id == data["id"]) then
    set_task(data["main"], data["sub"])
-- error event
elseif (data["type"] == "error") and (paired_id == data["id"]) then
-- clear previous error
if (data["error"] == message_error_clear) then
    term.setCursorPos(1, (term_size[2]-2))
    clear_line()
-- print error
else
    print_error(data["error"])
end
-- exit event
elseif (data["type"] == "exit") and (paired_id == data["id"]) then
    do_loop = false
end
end
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
    if not (turtle == nil) then
        run_turtle_main()
    else 
        run_reciever_main()
    end
end

main()