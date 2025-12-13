--[[
	作者:白狼
	2025 12 13
--]]

local white = Color(255, 255, 255)
-- ==================== 描述 ===============
local Description = {}

function Description:Init2(action)
	if not UPar.isupaction(action) then
		print(string.format('Invalid action "%s" (not upaction)', action))
		return
	end

	local actCreater = action.AAACreat
	local actContrib = action.AAAContrib
	local actDesc = action.AAADesc

	self:Help(language.GetPhrase('upgui.desc'), actDesc)
	self:Help('==========================================')
	self:ControlHelp(language.GetPhrase('upgui.creat') .. tostring(actCreater))
	self:ControlHelp(language.GetPhrase('upgui.contrib') .. tostring(actContrib))
	self:Help('==========================================')
	self:Help(language.GetPhrase('upgui.effect') .. language.GetPhrase('upgui.creat'))
	for effName, effect in pairs(action.Effects) do
		if not UPar.isupeffect(effect) then
			print(string.format('Invalid effect "%s" (not upeffect)', effName))
			continue
		end
		local effDesc = effect.AAADesc
		local effCreater = effect.AAACreat
		local effContrib = effect.AAAContrib
	end
end


vgui.Register('UParDescription', Description, 'DForm')
Description = nil