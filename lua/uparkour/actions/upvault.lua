--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 低爬 ===============
local ClimbDetector = UPar.ClimbDetector
local IsStartSolid = UPar.IsStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec

local action = UPAction:Register('upvault', {
	AAAACreat = '白狼',
	AAADesc = 'upgui.act.vault.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upgui.act.vault',
	defaultDisabled = false,
	defaultKeybind = '[33,79,65]'
})

action:InitConVars({
	{
		name = 'upctrl_los_cos',
		default = '0.64',
		invisible = true
	},

	{
		name = 'vault_hlen',
		default = '2',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'vault_vlen',
		default = '0.5',
		widget = 'NumSlider',
		min = 0.25,
		max = 0.6,
		decimals = 2,
		help = true,
	}
})

local convars = {

}



function action:Check(ply, pos, dirNorm, loscos, refVel)
	
end

function action:GetSpeed(ply, dirNorm, refVel)

end

function action:Start(ply, data)

end

function action:Think(ply, data, mv, cmd)

end

function action:Clear(ply, data, mv, cmd)

end

if CLIENT then

end
