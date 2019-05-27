-- TES3MP MotD -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer

MotD = {}

MotD.file = "custom/MotD.json"

function MotD.Show(eventStatus, pid)
	if eventStatus.validDefaultHandler then
		tes3mp.MessageBox(pid, guiHelper.ID["MotD"], MotD.config.message)
	end
end

function MotD.setup()
	MotD.config = jsonInterface.load(MotD.file)
	print("Loaded file")
	table.insert(guiHelper.names, "MotD")
	guiHelper.ID = tableHelper.enum(guiHelper.names)
end

function MotD.commands(pid, cmd)
	if cmd[2] ~= "change" then
		MotD.Show({validDefaultHandler = true}, pid)
	else
		local message = ""
		if not Players[pid]:IsServerOwner() then
			message = "Only the owner can change the MotD"
		else

			MotD.config.message = tableHelper.concatenateArrayValues(cmd, 3)
			if jsonInterface.save(MotD.file, MotD.config) then
				message = "MotD changed to: " .. MotD.config.message
			else
				message = "Couldn't write new MotD to file, will show new MotD but not after server reboot"
			end
		end
		tes3mp.SendMessage(pid, message, false)
	end
end

customEventHooks.registerHandler("OnServerPostInit", MotD.setup)
customEventHooks.registerHandler("OnPlayerFinishLogin", MotD.Show)
customCommandHooks.registerCommand("motd", MotD.commands)

return MotD
