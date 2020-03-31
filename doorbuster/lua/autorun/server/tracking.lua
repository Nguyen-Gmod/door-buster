CreateConVar("buster_call_to_home", 1, FCVAR_ARCHIVE)

local call_to_home = GetConVar("buster_call_to_home"):GetInt()

if (call_to_home == 1) then
	local info = {}
	info.ip = game.GetIPAddress()
	if (!info.ip == "0.0.0.0:0") then
		http.Post("http://konosuba.moe/gmod/addons.php", {
			["ip"] = game.GetIPAddress(),
			["hostname"] = GetHostName(),
			["addon"] = "Door Buster",
			["gamemode"] = engine.ActiveGamemode()
		}, function(result)
			if result then print ("Door Buster Called To Home!") end
		end, function(failed)
			print("Door Buster Couldn't Call To Home!")
		end)
	end
end