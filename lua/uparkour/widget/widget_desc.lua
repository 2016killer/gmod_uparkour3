--[[
	作者:白狼
	2025 12 13
--]]


-- ==================== 描述 ===============
local Description = {}

function Description:Init2(action)
	if not UPar.isupaction(action) then
		ErrorNoHaltWithStack(string.format('Invalid action "%s" (not upaction)', action))
		return
	end

	self:Help(string.format('%s: %s', language.GetPhrase('upgui.desc'), language.GetPhrase(tostring(action.AAADesc))))
	self:Help('')

	if action.AAAACreat ~= nil then
		self:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), action.AAAACreat))
	end
	if action.AAAContrib ~= nil then
		self:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), action.AAAContrib))
	end
	self:Help('====================')

	if istable(action.ConVarsPreset) then
		for pname, pdata in pairs(action.ConVarsPreset) do
			local label = isstring(pdata.label) and pdata.label or pname
			self:Help(string.format('%s: %s', language.GetPhrase('#preset'), language.GetPhrase(label)))

			if pdata.AAAACreat ~= nil then
				self:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), pdata.AAAACreat))
			end
			if pdata.AAAContrib ~= nil then
				self:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), pdata.AAAContrib))
			end

			self:Help('')
		end
	end

	self:Help('====================')
	for effName, effect in pairs(UPar.GetEffects(action.Name)) do
		if not UPar.isupeffect(effect) then
			ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not upeffect)', effect))
			continue
		end
		self:Help(string.format('%s: %s', language.GetPhrase('upgui.effect'), effName))
		if effect.AAAACreat ~= nil then
			self:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), effect.AAAACreat))
		end
		if effect.AAAContrib ~= nil then
			self:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), effect.AAAContrib))
		end
		self:Help('')
	end
end

vgui.Register('UParDescription', Description, 'DForm')
Description = nil