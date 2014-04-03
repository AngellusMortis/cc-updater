--[[
##name:
##file: am-cc/programs/computer/branch.lua
##version: ]]--
program_version = "3.7.0.1"
--[[

##type: turtle
##desc: Reciever code for branch mining program (see am-cc/programs/turtle/branch.lua)

##images:

##detailed:

##planned:

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

local function main()
    branch.init_progress()
    fs.delete(branch.log_file)

    local term_object = term

    -- check for transmitter
    while (branch.transmitter == nil) do
        -- if transmitter_side is not nil, for check on that side
        if not (branch.settings["transmitter_side"] == nil) then
            branch.transmitter = peripheral.wrap(branch.settings["transmitter_side"])
            -- if no transmitter, print error to add one
            if (branch.transmitter == nil) then
                branch.print_error(branch.message_error_modem_side, false, true)
            end
        else
            -- look for transmitter
            branch.transmitter = peripheral.find("modem")
            -- if no transmitter, print error to add one
            if (branch.transmitter == nil) then
                branch.print_error(branch.message_error_modem, false, true)
            end
        end
    end

    -- verify it is a wireless transmitter
    if not (branch.transmitter.isWireless()) then
        branch.print_error(branch.message_error_modem_wireless, false, true)
    end

    if (branch.settings["redirect_to_monitor"]) then
        local temp_monitor = nil
        if not (branch.settings["monitor_side"] == nil) then
            if not (branch.settings["monitor_side"] == false) then
                temp_monitor = peripheral.wrap(branch.settings["monitor_side"])
            end
        else
            temp_monitor = peripheral.find("monitor")
        end

        if not (temp_monitor == nil) then
            term.redirect(temp_monitor)
        else
            branch.settings["redirect_to_monitor"] = false
        end
    end

    local term_size = {term.getSize()}

    -- print title
    term.clear()
    term.setCursorPos(1,1)
    title = branch.program_name.." v"..program_version
    if (term_size[1] < string.len(title)+17) then
        branch.ids_line = 2
        if (term_size[1] < string.len(title)) or (term_size[1] < 17) then
            branch.print_error(branch.message_error_display_width, true)
        end
    end
    if (term_size[2] < 12) then
        branch.print_error(branch.message_error_display_height, true)
    end
    local current_branch_location = {term_size[1]-9,branch.ids_line+2}
    branch.color_write(title, colors.lime)
    term.setCursorPos(1,branch.ids_line+2)
    branch.color_write("Waiting for turtle...", colors.magenta)

    -- open channel for listening
    branch.transmitter.open(branch.settings["transmit_channel"])
    -- listen for events
    local do_loop = true
    while (do_loop) do
        local event, modemSide, senderChannel,
            replyChannel, message, senderDistance = os.pullEvent("modem_message")

        local retransmit = false
        local is_error = false

        local receiver_data = textutils.unserialize(message)
        receiver_data["retransmit_id"] = receiver_data["retransmit_id"] or nil

        temp_seralized = string.gsub(textutils.serialize(receiver_data), "[\n ]", "")
        branch.log("receive: "..temp_seralized)

        -- start event, can only be ran if waiting for turtle (paired_id == nil)
        if (receiver_data["type"] == "start") and (branch.progress["paired_id"] == nil) then
            branch.update_progress("paired_id", receiver_data["turtle_id"])
            branch.update_progress("retransmit_id", receiver_data["retransmit_id"])
            branch.update_progress("branch", receiver_data["branch"] or branch.progress["branch"]["current"], "current")
            branch.settings["number_of_branches"] = receiver_data["number_of_branches"]

            if not (branch.progress["retransmit_id"] == nil) then
                term.setCursorPos(term_size[1]-16,branch.ids_line)
            else
                term.setCursorPos(term_size[1]-10,branch.ids_line)
            end
            branch.color_write(string.format("%5d", os.computerID()), colors.white)
            branch.color_write(":", colors.yellow)
            if not (branch.progress["retransmit_id"] == nil) then
                branch.color_write(string.format("%5d", branch.progress["retransmit_id"]), colors.green)
                branch.color_write(":", colors.yellow)
            end
            branch.color_write(string.format("%5d", branch.progress["paired_id"]), colors.red)

            term.setCursorPos(1,branch.ids_line+2)
            branch.clear_line()
            branch.color_write("Current Branch", colors.cyan)
            term.setCursorPos(unpack(current_branch_location))
            branch.color_write(string.format("%3d", branch.progress["branch"]["current"]), colors.yellow)
            term.setCursorPos(term_size[1]-5,branch.ids_line+2)
            branch.color_write("of", colors.white)
            term.setCursorPos(term_size[1]-2,branch.ids_line+2)
            branch.color_write(string.format("%3d", branch.settings["number_of_branches"]), colors.magenta)
            retransmit = true
        -- branch_update event
        elseif (receiver_data["type"] == "branch_update") and (branch.progress["paired_id"] == receiver_data["turtle_id"]) and (branch.progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            branch.update_progress("branch", receiver_data["branch"], "current")
            term.setCursorPos(unpack(current_branch_location))
            branch.color_write(string.format("%3d", branch.progress["branch"]["current"]), colors.yellow)
            branch.send_confrim(receiver_data["turtle_id"])
            retransmit = true
        -- task event
        elseif (receiver_data["type"] == "task") and (branch.progress["paired_id"] == receiver_data["turtle_id"]) and (branch.progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            branch.set_task(receiver_data["main"], receiver_data["sub"])
            retransmit = true
        -- error event
        elseif (receiver_data["type"] == "check") and (branch.progress["paired_id"] == receiver_data["turtle_id"]) and (branch.progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            branch.send_confrim(receiver_data["turtle_id"])
            retransmit = true
        elseif (receiver_data["type"] == "error") and (branch.progress["paired_id"] == receiver_data["turtle_id"]) and (branch.progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            -- clear previous error
            if (receiver_data["error"] == branch.message_error_clear) then
                term.setCursorPos(1, (term_size[2]-2))
                branch.clear_line()
            -- print error
            else
                -- make suire the retransmitter runs first
                is_error = true
            end
            retransmit = true
        -- exit event
        elseif (receiver_data["type"] == "exit") and (branch.progress["paired_id"] == receiver_data["turtle_id"]) and (branch.progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            do_loop = false
            retransmit = true
        end

        if (branch.settings["transmit_progress"] and retransmit) then
            receiver_data["retransmit_id"] = nil
            branch.send_message(receiver_data["type"], receiver_data)
        end

        if (is_error) then
            branch.print_error(receiver_data["error"], false, receiver_data["wait"])
        end
    end
    branch.transmitter.close(settings["transmit_channel"])
    branch.set_task("Finished", "")
    branch.wait_for_enter()
    term.setCursorPos(1,1)
    term.clear()
    branch.transmitter.closeAll()

    if (branch.settings["redirect_to_monitor"]) then
        term.redirect(term_object)
    end
end

if (not args[1]) and branch.settings["do_multitask"] then
    shell.openTab("branch", "true")
else
    main()
end