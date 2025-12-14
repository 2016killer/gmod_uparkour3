--[[
	作者:白狼
	2025 12 13
--]]

local white = Color(255, 255, 255)
-- ==================== 描述 ===============
local Description = {}

function Description:Init2(action)
	if not UPar.isupaction(action) then
		ErrorNoHaltWithStack(string.format('Invalid action "%s" (not upaction)', action))
		return
	end

	self:Help(string.format('%s: %s', language.GetPhrase('upgui.desc'), language.GetPhrase(tostring(action.AAADesc))))
	self:Help('====================')
	self:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), action.AAACreat))
	self:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), action.AAAContrib))
	self:Help('====================')
	for effName, effect in pairs(action.Effects) do
		if not UPar.isupeffect(effect) then
			ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not upeffect)', effect))
			continue
		end
		self:Help(string.format('%s: %s', language.GetPhrase('upgui.effect'), effName))
		self:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), effect.AAACreat))
		self:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), effect.AAAContrib))
		self:Help('')
	end
end

vgui.Register('UParDescription', Description, 'DForm')
Description = nil