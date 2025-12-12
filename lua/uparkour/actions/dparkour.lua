--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 耻辱跑酷 ===============
local action = UPAction:new('DParkour', {})
action:Register()
action:SetIcon('dparkour/icon.jpg')
action:InitConVars({
	{
		name = 'dp_los_cos',
		default = '0.64',
		widget = 'NumSlider',
		min = 0,
		max = 1,
		decimals = 2,
		help = true
	}
})

