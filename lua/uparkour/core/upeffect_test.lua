--[[
	作者:白狼
	2025 11 1
--]]

UPar.EffectTest = function(ply, actName, effName)
	local action = UPar.GetAction(actName)
	if not action then
		print(string.format('[UPar]: effect test failed, action "%s" not found', actName))
		return
	end

	local effect = action:GetPlayerEffect(ply, effName)
	if not effect then
		print(string.format('[UPar]: effect test failed, action "%s" effect "%s" not found', actName, effName))
		return
	end

	effect:start(ply)
	timer.Simple(1, function() effect:clear(ply) end)
	
	if CLIENT then
		net.Start('UParEffectTest')
			net.WriteString(actName)
			net.WriteString(effName)
		net.SendToServer()
	end
end

if SERVER then
	util.AddNetworkString('UParEffectTest')

	net.Receive('UParEffectTest', function(len, ply)
		local actName = net.ReadString()
		local effName = net.ReadString()
		
		UPar.EffectTest(ply, actName, effName)
	end)
elseif CLIENT then
	UPar.SendEffectTest = function(actName, effName)
		UPar.EffectTest(LocalPlayer(), actName, effName)

	end
end

