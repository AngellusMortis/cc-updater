--[[
##name:
##file: am-cc/programs/turtle/branch.lua
##version: ]]--
program_version = "3.7.0.2"
--[[

##type: turtle
##desc: Mines a branch mine with a trunk and 5 branches each divded into two 50 length halves.

##images:
https://github.com/AngellusMortis/am-cc/tree/master/images/branch.lua

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
args[1]: force start without opening on new tab

--]]

local base_path = "/"

if (fs.exists("/disk/am-cc")) then
    base_path = "/disk/"
end

-- load shared code
local branch = loadfile(base_path.."am-cc/core/branch")()

local args = { ... }

local empty_inventory = nil

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

-- turtle functions
-- rotate turtle and update progress["position"]
local function rotate(direction)
    local offset = direction - branch.progress["position"][2]
    branch.update_progress("position", direction, 2)
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
        turtle.select(branch.settings["cobblestone_slot"])
        if (turtle.place()) then
            branch.print_error(branch.message_error_liquids)
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
            branch.print_error(branch.message_error_move)
            count = 0
        end
        os.sleep(0.05 * branch.settings["tick_delay"])
        detect_liquid_forward()
        move_success = turtle.forward()
    end

    if (move_success) then
        turtle.select(branch.settings["chest_slot"])
        if not (turtle.compare()) then
            turtle.suck()
        end
        if not (turtle.compareUp()) then
            turtle.suckUp()
        end
        if not (turtle.compareDown()) then
            turtle.suckDown()
        end

        if (branch.progress["position"][2] == 0) then
            branch.update_progress("position", branch.progress["position"][1][3] - 1, 1, 3)
        elseif (branch.progress["position"][2] == 1) then
            branch.update_progress("position", branch.progress["position"][1][1] + 1, 1, 1)
        elseif (branch.progress["position"][2] == 2) then
            branch.update_progress("position", branch.progress["position"][1][3] + 1, 1, 3)
        else
            branch.update_progress("position", branch.progress["position"][1][1] - 1, 1, 1)
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
            branch.print_error(branch.message_error_dig.." (forward)")
            count = 0
        end
        os.sleep(0.5 * branch.settings["tick_delay"])
        detect_liquid_forward()
    end
end
-- only works in CC1.6
local function detect_liquid_up()
    if (turtle.detectUp()) then
        turtle.select(branch.settings["cobblestone_slot"])
        if (turtle.placeUp()) then
            branch.print_error(branch.message_error_liquids)
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
            branch.print_error(branch.message_error_move)
            count = 0
        end
        os.sleep(0.5 * branch.settings["tick_delay"])
        detect_liquid_up()
        success = turtle.up()
    end
    if (success) then
        turtle.suckUp()
        branch.update_progress("position", branch.progress["position"][1][2] + 1, 1, 2)
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
            branch.print_error(branch.message_error_dig.." (up)")
            count = 0
        end
        os.sleep(0.5 * branch.settings["tick_delay"])
        detect_liquid_up()
    end
end
-- only works in CC1.6
local function detect_liquid_down()
    if (turtle.detectDown()) then
        turtle.select(branch.settings["cobblestone_slot"])
        if (turtle.placeDown()) then
            branch.print_error(branch.message_error_liquids)
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
            branch.print_error(branch.message_error_move)
            count = 0
        end
        os.sleep(0.5 * branch.settings["tick_delay"])
        detect_liquid_down()
        success = turtle.down()
    end
    if (success) then
        turtle.suckDown()
        branch.update_progress("position", branch.progress["position"][1][2] - 1, 1, 2)
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
            branch.print_error(branch.message_error_dig.." (down)")
            count = 0
        end
        os.sleep(0.5 * branch.settings["tick_delay"])
        detect_liquid_down()
    end
end
-- uses all fuel in inventory
local function use_all_fuel()
    for i=1,16 do
        if not (i == branch.settings["chest_slot"]) then
            turtle.select(i)
            turtle.refuel(64)
        end
    end
end
-- moves turtle to coords and facing direction
--   allows for both negative and positive coords for X and Y, but NOT Z
local function goto_position(coord, facing)
    temp_seralized = string.gsub(textutils.serialize({coord, facing}), "[\n ]", "")
    branch.log("goto: "..temp_seralized)
    -- move turtle out of branch connector if in one
    local branchs_z = {branch.settings["branch_between_distance"]}
    for i=2,branch.settings["number_of_branches"] do
        table.insert(branchs_z, branchs_z[#branchs_z]+branch.settings["branch_between_distance"]+1)
    end
    local distance_from_branch = -1
    for i=1,#branchs_z do
        if (branch.progress["position"][1][3] >= branchs_z[i]) then
            temp_distance = branch.progress["position"][1][3] - branchs_z[i]
            if (temp_distance < distance_from_branch) or (distance_from_branch == -1) then
                distance_from_branch = branch.progress["position"][1][3] - branchs_z[i]
            end
        else
            break
        end
    end
    for i=1,distance_from_branch do
        rotate(0)
        force_forward()
    end

    -- move turtle to trunk
    min_trunk = 0
    max_trunk = (branch.settings["trunk_width"])-1
    while (branch.progress["position"][1][1] > max_trunk) do
        rotate(3)
        force_forward()
    end
    while (branch.progress["position"][1][1] < min_trunk) do
        rotate(1)
        force_forward()
    end

    -- goto y coord (down)
    while (branch.progress["position"][1][2] > coord[2]) do
        force_down()
    end

    -- goto z coord
    while (branch.progress["position"][1][3] > coord[3]) do
        rotate(0)
        force_forward()
    end
    while (branch.progress["position"][1][3] < coord[3]) do
        rotate(2)
        force_forward()
    end

    -- goto x coord
    while (branch.progress["position"][1][1] > coord[1]) do
        rotate(3)
        force_forward()
    end
    while (branch.progress["position"][1][1] < coord[1]) do
        rotate(1)
        force_forward()
    end

    -- goto y coord (up)
    while (branch.progress["position"][1][2] < coord[2]) do
        force_up()
    end

    -- rotate to facing
    rotate(facing)
end
-- calculate the distance from the fuel chest
local function get_distance_from_fuel()
    -- fuel position is (trunk_width-1, 0, 0)
    return math.abs(branch.progress["position"][1][1]-(branch.settings["trunk_width"]-1))+math.abs(branch.progress["position"][1][2])+math.abs(branch.progress["position"][1][3])
end
local function get_fuel_amount_for_branch()
    return get_distance_from_fuel() + ((branch.settings["branch_length"] + (branch.settings["branch_length"]/branch.settings["branch_connector_distance"])*(branch.settings["branch_between_distance"]*2))*2 + branch.settings["trunk_width"])*2
end
-- test if it is nesscary to get resources
local function get_fuel_and_supplies_if_needed(required_fuel)
    branch.set_task("Supplies", "Checking")

    -- check fuel
    local previous_position = {{branch.progress["position"][1][1], branch.progress["position"][1][2], branch.progress["position"][1][3]}, branch.progress["position"][2]}
    local has_moved = false
    if (turtle.getFuelLevel() < required_fuel) then
        if (required_fuel < branch.settings["min_continue_fuel_level"]) then
            required_fuel = branch.settings["min_continue_fuel_level"]
        end
        has_moved = true
        branch.set_task("Supplies", "Fuel")
        goto_position({(branch.settings["trunk_width"]-1), 0, 0}, 1)
        need_fuel = (turtle.getFuelLevel() < required_fuel)
        while (need_fuel) do
            turtle.select(12)
            if not (turtle.suck()) then
                branch.print_error(branch.message_error_fuel)
            end
            use_all_fuel()
            need_fuel = (turtle.getFuelLevel() < required_fuel)
        end
    end

    -- check torches/chests
    branch.set_task("Supplies", "Checking")
    local need_chests = (turtle.getItemCount(branch.settings["chest_slot"]) <= 1)
    local need_torches = (turtle.getItemCount(branch.settings["torch_slot"]) <= (((branch.settings["branch_length"]/branch.settings["torch_distance"])+1)*2))
    if (need_chests or need_torches) then
        has_moved = true
        branch.set_task("Supplies", "Items")
        goto_position({0, 0, 0}, 3)

        -- resupply chests
        while (need_chests) do
            branch.set_task("Supplies", "Chests")
            turtle.select(branch.settings["chest_slot"])
            turtle.suckUp(64-turtle.getItemCount(branch.settings["chest_slot"]))
            need_chests = (turtle.getItemCount(branch.settings["chest_slot"]) <= 1)
            if (need_chests) then
                branch.print_error(branch.message_error_chest)
            end
        end
        -- resupply torches
        while (need_torches) do
            branch.set_task("Supplies", "Torches")
            turtle.select(branch.settings["torch_slot"])
            turtle.suck(64-turtle.getItemCount(branch.settings["torch_slot"]))
            need_torches = (turtle.getItemCount(branch.settings["torch_slot"]) <= (((branch.settings["branch_length"]/branch.settings["torch_distance"])+1)*2))
            if (need_torches) then
                branch.print_error(branch.message_error_torch)
            end
        end
    end

    empty_slots = false
    for i=1,16 do
        empty_slots = empty_slots or (turtle.getItemCount(i) == 0)
    end
    if not empty_slots then
        has_moved = true
        branch.set_task("Supplies", "Emptying")
        drop_off_x = 0
        if (branch.progress["branch"]["side"] == 2) then
           drop_off_x = (branch.settings["trunk_width"])-1
        end
        goto_position({drop_off_x, 1, ((branch.settings["branch_between_distance"]+1)*branch.progress["branch"]["current"])-1}, 2)
        empty_inventory()
    end

    if (has_moved) then
        -- return to previous position
        branch.set_task("Supplies", "Returning")
        goto_position(unpack(previous_position))
    end
end

-- main functions
empty_inventory = function()
    for i=1,16 do
        branch.set_task("Emptying", string.format("%3d%%", (i/16)*100))
        turtle.select(i)
        if (i == branch.settings["torch_slot"]) or (i == branch.settings["chest_slot"]) or (i == branch.settings["cobblestone_slot"]) then
        else
            is_test_block = false
            for index,value in ipairs(branch.test_slots) do
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

    local previous_face = nil

    if (#movement == 0) or ((#movement == 1) and (movement[1] == -1)) then
        previous_face = branch.progress["position"][2]
    end

    -- down
    if (turtle.detectDown()) then
        not_ore_block = false
        for index,value in ipairs(branch.test_slots) do
            turtle.select(value)
            not_ore_block = (not_ore_block or turtle.compareDown())
        end
        if not (not_ore_block) then
            if (#movement == 0) then
                -- check for needed supplies
                required_fuel = get_fuel_amount_for_branch()
                get_fuel_and_supplies_if_needed(required_fuel)
                branch.set_task("Mining Vein", "")
            end
            if (force_down(true)) then
                movement[#movement+1]=4
                os.sleep(0.05 * branch.settings["tick_delay"])
                dig_ores(movement)
            end
        end
    end
    -- up
    if (turtle.detectUp()) then
        not_ore_block = false
        for index,value in ipairs(branch.test_slots) do
            turtle.select(value)
            not_ore_block = (not_ore_block or turtle.compareUp())
        end
        if not (not_ore_block) then
            if (#movement == 0) then
                -- check for needed supplies
                required_fuel = get_fuel_amount_for_branch()
                get_fuel_and_supplies_if_needed(required_fuel)
                branch.set_task("Mining Vein", "")
            end
            if (force_up(true)) then
                movement[#movement+1]=5
                os.sleep(0.05 * branch.settings["tick_delay"])
                dig_ores(movement)
            end
        end
    end

    sides_to_check = {}
    if (#movement == 0) then
        sides_to_check = {0, 2}
    elseif (#movement == 1) and (movement[1] == -1) then
        movement[1] = nil
        sides_to_check = {1, 3}
    else
        sides_to_check = {0, 1, 2, 3}
    end
    -- sides
    for i,v in ipairs(sides_to_check) do
        rotate(v)
        if (turtle.detect()) then
            not_ore_block = false
            for index,value in ipairs(branch.test_slots) do
                turtle.select(value)
                not_ore_block = (not_ore_block or turtle.compare())
            end
            if not (not_ore_block) then
                if (#movement == 0) then
                    -- check for needed supplies
                    required_fuel = get_fuel_amount_for_branch()
                    get_fuel_and_supplies_if_needed(required_fuel)
                    branch.set_task("Mining Vein", "")
                end
                if (force_forward(true)) then
                    movement[#movement+1]=get_opposite_direction(v)
                    os.sleep(0.05 * branch.settings["tick_delay"])
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
    branch.log("trunk: "..length)
    -- check for needed supplies
    required_fuel = get_fuel_amount_for_branch()
    get_fuel_and_supplies_if_needed(required_fuel)

    branch.set_task("Trunk", string.format("%3d%%", 0))
    rotate(2)
    for i=1,length do
        force_forward()
        if (branch.settings["trunk_height"] == 3) then
            force_up()
        end
        turtle.select(branch.settings["chest_slot"])
        if not (turtle.compareUp()) then
            force_dig_up()
        end
        rotate(1)
        for i=1,(branch.settings["trunk_width"]-1) do
            force_forward()
            if (i == branch.settings["trunk_width"]-1) then
                turtle.select(branch.settings["chest_slot"])
                if not (turtle.compareUp()) then
                    force_dig_up()
                end
            else
                force_dig_up()
            end
            if (branch.settings["trunk_height"] == 3) then
                force_dig_down()
            end
        end
        rotate(3)
        for i=1,(branch.settings["trunk_width"]-1) do
            force_forward()
        end
        if (branch.settings["trunk_height"] == 3) then
            force_down()
        end
        rotate(2)
        branch.set_task("Trunk", string.format("%3d%%", (i/length)*100))
    end
end
-- digs out a single branch
local function dig_branch()
    -- check for needed supplies
    required_fuel = get_distance_from_fuel() + ((branch.settings["branch_length"] + (branch.settings["branch_length"]/branch.settings["branch_connector_distance"])*(branch.settings["branch_between_distance"]*2))*2 + branch.settings["trunk_width"])*2
    get_fuel_and_supplies_if_needed(required_fuel)

    branch.set_task("Branch", string.format("%3d%%", 0))
    branch.progress["branch"]["side"] = branch.progress["branch"]["side"] or 1

    -- each path through loop is one half of branch (each side of trunk)
    for x=branch.progress["branch"]["side"],2 do
        branch.update_progress("branch", x, "side")
        if (x == 1) then
            rotate(3)
        else
            rotate(1)
        end

        if (branch.progress["branch"]["height"] == nil) then
            branch.update_progress("branch", 1, "height")
        end

        if (branch.progress["branch"]["height"] == 1) then
            if (branch.progress["branch"]["progress"] == nil) or (branch.progress["branch"]["progress"] == 1) then
                -- place supply chest
                force_up()
                if not (turtle.compareUp()) then
                    force_up()
                    force_dig_up()
                    force_down()
                    turtle.select(branch.settings["chest_slot"])
                    while not (turtle.placeUp()) do
                        branch.print_error(branch.message_error_failed_to_place_chest)
                        turtle.select(branch.settings["chest_slot"])
                    end
                else
                    turtle.select(branch.settings["chest_slot"])
                    turtle.placeUp()
                end
            end
            branch.progress["branch"]["progress"] = branch.progress["branch"]["progress"] or 1
            -- mine out top of branch
            for i=branch.progress["branch"]["progress"],branch.settings["branch_length"] do
                branch.update_progress("branch", i, "progress")
                branch.set_task("Branch", string.format("%3d%%", (x-1)*50+((i/branch.settings["branch_length"])*100)/4))
                force_forward()
                dig_ores()

                -- mine out branch connectors
                if (i%branch.settings["branch_connector_distance"]) == 0 then
                    rotate(2)
                    for j=1,branch.settings["branch_between_distance"] do
                        force_forward()
                        dig_ores({-1})
                    end
                    force_down()
                    rotate(0)
                    for j=1,branch.settings["branch_between_distance"] do
                        force_forward()
                        dig_ores({-1})
                    end
                    force_up()
                    if (x == 1) then
                        rotate(3)
                    else
                        rotate(1)
                    end
                end

                -- verfiy blocks are in place for torches (placed later)
                if (((i%branch.settings["torch_distance"]) == 1)) then
                    branch.log("branch: place: torch wall")
                    if (branch.has_error) then
                        term_size = {term.getSize()}
                        term.setCursorPos(1, (term_size[2]-2))
                        branch.clear_line()
                        branch.has_error = false
                    end
                    if (branch.settings["transmit_progress"]) then
                        branch.send_message("check")
                    end
                    rotate(2)
                    if (not (turtle.detect())) or (not (turtle.detectUp())) then
                        if (turtle.getItemCount(branch.settings["cobblestone_slot"]) > 3) then
                            turtle.select(branch.settings["cobblestone_slot"])
                            turtle.placeUp()
                            turtle.place()
                        else
                            branch.print_error(branch.message_error_failed_to_place_torch_wall, false, false)
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
            branch.update_progress("branch", 0, "height")
            branch.update_progress("branch", 1, "progress")
        end

        if (branch.progress["branch"]["progress"] == nil) then
            branch.update_progress("branch", 1, "progress")
        end

        for i=branch.progress["branch"]["progress"],branch.settings["branch_length"] do
            branch.set_task("Branch", string.format("%3d%%", (x-1)*50+((i/branch.settings["branch_length"])*100)/4+25))
            force_forward()
            dig_ores()

            -- place torches
            if (i%branch.settings["torch_distance"]) == 1 then
                branch.log("branch: place: torch")
                if (branch.has_error) then
                    term_size = {term.getSize()}
                    term.setCursorPos(1, (term_size[2]-2))
                    branch.clear_line()
                    branch.has_error = false
                end
                if (branch.settings["transmit_progress"]) then
                    branch.send_message("check")
                end
                turtle.select(branch.settings["torch_slot"])
                if not (turtle.placeUp()) then
                    branch.print_error(branch.message_error_failed_to_place_torch, false, false)
                end
            end
        end
        branch.update_progress("branch", nil, "progress")
        branch.set_task("Emptying", string.format("%3d%%", 0))
        force_up()
        -- use fuel is told too
        if (branch.settings["use_coal"]) then
            use_all_fuel()
        end
        turtle.select(branch.settings["chest_slot"])
        while not (turtle.compareUp()) do
            branch.print_error(branch.message_error_no_chest)
        end
        -- empty out inventory (except for supplies)
        empty_inventory()
        branch.set_task("Branch", string.format("%3d%%", x*50))
        force_down()

        -- move to current location to continue
        if (x == 1) then
            rotate(1)
            for i=1,(branch.settings["trunk_width"]-1) do
                force_forward()
            end
        else
            rotate(3)
            for i=1,(branch.settings["trunk_width"]-1) do
                force_forward()
            end
        end

        branch.update_progress("branch", 1, "height")
        branch.update_progress("branch", 1, "progress")
    end

    branch.update_progress("branch", 1, "height")
    branch.update_progress("branch", 1, "progress")
    branch.update_progress("branch", 1, "side")
    rotate(2)
end

local function main()
    branch.init_progress()
    fs.delete(branch.log_file)

    -- verify trunk height (program not adjusted for otherwise)
    if not (branch.settings["trunk_height"]==2 or branch.settings["trunk_height"]==3) then
        branch.print_error(branch.message_error_trunk)
    end
    -- check for wireless modem, disable transmit if not there
    if (branch.settings["transmit_progress"]) then
        if not (branch.settings["transmitter_side"] == nil) then
            branch.transmitter = peripheral.wrap(branch.settings["transmitter_side"])
        else
            branch.transmitter = peripheral.find("modem")
        end
        if (branch.transmitter == nil) then
            branch.settings["transmit_progress"] = false
        end
    end

    -- print title
    term_size = {term.getSize()}
    local current_branch_location = {term_size[1]-9,branch.ids_line+2}
    term.clear()
    term.setCursorPos(1,1)
    branch.color_write(branch.program_name.." v"..program_version, colors.lime)
    -- if transmit, print computer ID to indicate it
    if (branch.settings["transmit_progress"]) then
        term.setCursorPos(term_size[1]-4,branch.ids_line)
        branch.color_write(string.format("%5d", os.computerID()), colors.white)
    end

    -- if no progress, start new
    if (branch.progress["task"] == nil) then
        -- verfiy there is at least __some__ fuel to get started
        while (turtle.getFuelLevel() == 0) do
            use_all_fuel()
            if (turtle.getFuelLevel() == 0) then
                term.setCursorPos(1,branch.ids_line+3)
                branch.color_write("Put at least one piece of fuel in", colors.cyan)
                branch.wait_for_enter()
                term.setCursorPos(1,branch.ids_line+3)
                branch.clear_line()
            end
        end

        -- remind use to have stone, dirt, gravel, and cobblestone
        term.setCursorPos(1,branch.ids_line+3)
        branch.color_write("Leave slots 1 and 2 empty", colors.cyan)
        term.setCursorPos(1,branch.ids_line+4)
        branch.color_write("Put a stack of cobblestone in slot "..branch.settings["cobblestone_slot"], colors.cyan)
        term.setCursorPos(1,branch.ids_line+5)
        branch.color_write("Put any \"do not mine\" blocks in others", colors.cyan)
        term.setCursorPos(3,branch.ids_line+6)
        branch.color_write("i.e.: cobblestone, stone,", colors.cyan)
        term.setCursorPos(4,branch.ids_line+7)
        branch.color_write("dirt, gravel", colors.cyan)
        branch.wait_for_enter()
        while (turtle.getItemCount(branch.settings["cobblestone_slot"]) < 64) do
            branch.print_error(branch.message_error_cobble)
        end
        -- add items in all slots but 1 and 2 to test_slots
        term.setCursorPos(1,branch.ids_line+3)
        branch.clear_line()
        term.setCursorPos(1,branch.ids_line+4)
        branch.clear_line()
        term.setCursorPos(1,branch.ids_line+5)
        branch.clear_line()
        term.setCursorPos(1,branch.ids_line+6)
        branch.clear_line()
        term.setCursorPos(1,branch.ids_line+7)
        branch.clear_line()
    end

    for i=1,16 do
        if (turtle.getItemCount(i) > 0) then
            branch.test_slots[#branch.test_slots+1] = i
        end
    end

    -- print current branch data
    term.setCursorPos(1,branch.ids_line+2)
    branch.color_write("Current Branch", colors.cyan)
    term.setCursorPos(unpack(current_branch_location))
    branch.color_write(string.format("%3d", branch.progress["branch"]["current"]), colors.yellow)
    term.setCursorPos(term_size[1]-5,branch.ids_line+2)
    branch.color_write("of", colors.white)
    term.setCursorPos(term_size[1]-2,branch.ids_line+2)
    branch.color_write(string.format("%3d", branch.settings["number_of_branches"]), colors.magenta)

    -- if transmit, send start signal to receiver
    if (branch.settings["transmit_progress"]) then
        local send_data = {}
        send_data["number_of_branches"] = branch.settings["number_of_branches"]
        branch.send_message("start", send_data)
    end

    -- if no progress, check for supplies and start
    if (branch.progress["task"] == nil) then
    -- Verify starting fuel level
    get_fuel_and_supplies_if_needed(branch.settings["min_continue_fuel_level"])

    -- Dig to branch 1
    dig_out_trunk(branch.settings["branch_between_distance"])
    elseif (branch.progress["task"] == "trunk") then

    end

    -- dig branchs
    for i=branch.progress["branch"]["current"],branch.settings["number_of_branches"] do
        branch.update_progress("branch", i, "current")
        term.setCursorPos(unpack(current_branch_location))
        branch.color_write(string.format("%3d", branch.progress["branch"]["current"]), colors.yellow)
        -- if transmit, update current branch
        if (branch.settings["transmit_progress"]) then
            local send_data = {}
            send_data["branch"] = branch.progress["branch"]["current"]
            branch.send_message("branch_update", send_data)
        end
        branch.log("branch: "..branch.progress["branch"]["current"])
        -- dig branch
        dig_branch()
        -- dig to next branch
        dig_out_trunk(branch.settings["branch_between_distance"]+1)
    end
    -- go back to start
    branch.set_task("Returning", "")
    goto_position({0, 0, 0}, 2)
    --if transmit, sent exit signal
    if (branch.settings["transmit_progress"]) then
        branch.send_message("exit")
    end
    -- delete progress file
    fs.delete(branch.progress_file)
    -- wait for user's acknowledgement of completion
    branch.wait_for_enter()
    term.setCursorPos(1,1)
    term.clear()
end

if (not args[1]) and branch.settings["do_multitask"] then
    shell.openTab("branch", "true")
else
    main()
end