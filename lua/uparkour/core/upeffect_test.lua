--[[
	作者:白狼
	2025 12 13
--]]

UPar.GeneralEffectClear = function(self, ply, interruptSource, _)
	if SERVER then
		ply:SetNWString('UP_WOS', '')
	elseif CLIENT and interruptSource then
		VManip:Remove()
	elseif CLIENT then
		local currentAnim = VManip:GetCurrentAnim()
		if currentAnim and currentAnim == self.VManipAnim then
			VManip:QuitHolding(currentAnim)
		end
	end
end


UPar.EffectTest = function(ply, actName, effName)
	local action = UPar.GetAction(actName)
	if not action then
		ErrorNoHaltWithStack(string.format('effect test failed, can not find action named "%s"', actName))
		return
	end

	local effect = action:GetPlayerEffect(ply, effName)
	if not effect then
		ErrorNoHaltWithStack(string.format('effect test failed, can not find effect named "%s" from act "%s"', effName, actName))
		return
	end

	effect:Start(ply)
	timer.Simple(1, function() effect:OnRhythmChange(ply) end)
	timer.Simple(2, function() effect:Clear(ply) end)
end

if SERVER then
	util.AddNetworkString('UParEffectTest')

	net.Receive('UParEffectTest', function(len, ply)
		local actName = net.ReadString()
		local effName = net.ReadString()
		
		UPar.EffectTest(ply, actName, effName)
	end)
elseif CLIENT then
	UPar.CallServerEffectTest = function(actName, effName)
		net.Start('UParEffectTest')
			net.WriteString(actName)
			net.WriteString(effName)
		net.SendToServer()
	end
end