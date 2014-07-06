local args = { ... }
--[[
##name:
#See am-cc/core/branch.lua
##file: 
am-cc/programs/computer/branch.lua
##version: ]]--
version = "3.7.1.0"
--[[

##type: 
computer
##desc: 
reciever for branch mining 

##detailed:
Reciever code for branch mining program. See am-cc/programs/turtle/branch.lua

##images:
#See am-cc/programs/turtle/branch.lua

##planned:
#See am-cc/programs/turtle/branch.lua

##issues:
#See am-cc/programs/turtle/branch.lua

##parameters:
args[1]: force start without opening on new tab

##usage:
cmd: branch <force-no-tab>

--]]

local function main()
    -- change version from core
    branch.core = {}
    branch.core.version = branch.version
    branch.version = version

    -- init progress
    branch.init_progress()
    fs.delete(core.base_path..branch.log_file)

    local term_object = term

    -- check for transmitter
    while (branch.transmitter == nil) do
        -- if transmitter_side is not nil, for check on that side
        if not (branch.settings["transmitter_side"] == nil) then
            branch.transmitter = peripheral.wrap(branch.settings["transmitter_side"])
            -- if no transmitter, print error to add one
            if (branch.transmitter == nil) then
                core.text.print_error(branch, core.strings.levels.error, string.format(branch.strings.errors.modem_side, branch.settings["transmitter_side"]), false, true)
            end
        else
            -- look for transmitter
            branch.transmitter = peripheral.find("modem")
            -- if no transmitter, print error to add one
            if (branch.transmitter == nil) then
                core.text.print_error(branch, core.strings.levels.error, branch.strings.errors.modem, false, true)
            end
        end
    end

    -- verify it is a wireless transmitter
    if not (branch.transmitter.isWireless()) then
        core.text.print_error(branch, core.strings.levels.error, branch.strings.errors.modem_wireless, true)
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
    title = branch.name.." v"..branch.version
    if (term_size[1] < string.len(title)+17) then
        branch.ids_line = 2
        if (term_size[1] < string.len(title)) or (term_size[1] < 17) then
            core.text.print_error(branch, core.strings.levels.error, core.strings.errors.width, true)
        end
    end
    if (term_size[2] < 12) then
        core.text.print_error(branch, core.strings.levels.error, core.strings.errors.height, true)
    end
    local current_branch_location = {term_size[1]-9,branch.ids_line+2}
    core.text.color_write(title, colors.lime)
    term.setCursorPos(1,branch.ids_line+2)
    core.text.color_write("Waiting for turtle...", colors.magenta)

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
        core.log(branch, core.strings.levels.debug, "receive: "..temp_seralized)

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
            core.text.color_write(string.format("%5d", os.computerID()), colors.white)
            core.text.color_write(":", colors.yellow)
            if not (branch.progress["retransmit_id"] == nil) then
                core.text.color_write(string.format("%5d", branch.progress["retransmit_id"]), colors.green)
                core.text.color_write(":", colors.yellow)
            end
            core.text.color_write(string.format("%5d", branch.progress["paired_id"]), colors.red)

            term.setCursorPos(1,branch.ids_line+2)
            core.text.clear_line()
            core.text.color_write("Current Branch", colors.cyan)
            term.setCursorPos(unpack(current_branch_location))
            core.text.color_write(string.format("%3d", branch.progress["branch"]["current"]), colors.yellow)
            term.setCursorPos(term_size[1]-5,branch.ids_line+2)
            core.text.color_write("of", colors.white)
            term.setCursorPos(term_size[1]-2,branch.ids_line+2)
            core.text.color_write(string.format("%3d", branch.settings["number_of_branches"]), colors.magenta)
            retransmit = true
        -- branch_update event
        elseif (receiver_data["type"] == "branch_update") and (branch.progress["paired_id"] == receiver_data["turtle_id"]) and (branch.progress["retransmit_id"] == receiver_data["retransmit_id"]) then
            branch.update_progress("branch", receiver_data["branch"], "current")
            term.setCursorPos(unpack(current_branch_location))
            core.text.color_write(string.format("%3d", branch.progress["branch"]["current"]), colors.yellow)
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
            if (receiver_data["error"] == core.strings.errors.clear) then
                term.setCursorPos(1, (term_size[2]-2))
                core.text.clear_line()
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
            core.text.print_error(branch, core.strings.levels.error, receiver_data["error"], false, false)
        end
    end
    branch.transmitter.close(branch.settings["transmit_channel"])
    branch.set_task("Finished", "")
    core.text.wait_for_enter()
    term.setCursorPos(1,1)
    term.clear()
    branch.transmitter.closeAll()

    if (branch.settings["redirect_to_monitor"]) then
        term.redirect(term_object)
    end
end

-- make sure required code gets/is loaded
assert(not (core == nil))
assert(os.loadAPI(core.base_path.."am-cc/core/branch"))
core.init_settings(branch)
if (not args[1]) and branch.settings["do_multitask"] then
    shell.openTab("branch", "true")
else
    main()
end
-- unload shared code
os.unloadAPI(core.base_path.."am-cc/core/branch")