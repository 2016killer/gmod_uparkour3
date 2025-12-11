--[[
	作者:白狼
	2025 11 1
--]]

UPar.EffectTest = function(ply, actionName, effectName)
	local action = UPar.GetAction(actionName)
	if not action then
		print(string.format('[UPar]: effect test failed, action "%s" not found', actionName))
		return
	end

	local effect = action:GetPlayerEffect(ply, effectName)
	if not effect then
		print(string.format('[UPar]: effect test failed, action "%s" effect "%s" not found', actionName, effectName))
		return
	end

	effect:start(ply)
	timer.Simple(1, function() effect:clear(ply) end)
	
	if CLIENT then
		net.Start('UParEffectTest')
			net.WriteString(actionName)
			net.WriteString(effectName)
		net.SendToServer()
	end
end

if SERVER then
	util.AddNetworkString('UParEffectTest')

	net.Receive('UParEffectTest', function(len, ply)
		local actionName = net.ReadString()
		local effectName = net.ReadString()
		
		UPar.EffectTest(ply, actionName, effectName)
	end)
elseif CLIENT then
	UPar.SendEffectTest = function(actionName, effectName)
		UPar.EffectTest(LocalPlayer(), actionName, effectName)

	end
end

