--[[
	作者:白狼
	2025 12 27
]]--

-- ====================  二段翻越特效 ===============
local effect = UPEffect:Register('upvaultdl', 'default', {
	AAAACreat = '白狼',
	AAADesc = '#upvaultdl.defaulteff.desc',
})

function effect:Start(ply, data)
	local rhythm = istable(data) and data.rhythm or 1
	local actName = rhythm == 1 and 'uplowclimb' or 'upvault'
	return UPar.CallPlyUsingEff(actName, 'Start', ply)
end

function effect:Rhythm(ply, data)
	local rhythm = istable(data) and data.rhythm or 2
	local actName = rhythm == 1 and 'uplowclimb' or 'upvault'
	return UPar.CallPlyUsingEff(actName, 'Start', ply)
end

effect.Clear = UPar.GenEffClear
