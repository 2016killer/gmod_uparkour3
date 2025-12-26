--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 二段翻越 ===============
local XYNormal = UPar.XYNormal
local ObsDetector = UPar.ObsDetector
local ClimbDetector = UPar.ClimbDetector
local VaultDetector = UPar.VaultDetector
local IsPlyStartSolid = UPar.IsPlyStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3
local CallAct = UPar.CallAct

local upvaultd = UPAction:Register('upvaultd', {
	AAAACreat = '白狼',
	AAADesc = '#upvaultd.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upvaultd',
	defaultDisabled = false,
	defaultKeybind = '[33,79,65]'
})

upvaultd:InitConVars({
	{
		name = 'upctrl_vaultd_th',
		default = '0.6',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'upvtdl_max',
		default = '0.6',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	}
})

function upvaultd:Check(ply, obsTrace, climbTrace, vaultTrace, refVel)
	if not obsTrace or not climbTrace or not vaultTrace then
		return
	end

	if not IsValid(ply) or not isentity(ply) or not ply:IsPlayer() then
		print('[upvaultd]: Warning: Invalid player')
		return
	end

	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end



	local climbMoveData = CallAct('uplowclimb', 'GetMoveData', ply, obsTrace, climbTrace, refVel)
	local vaultMoveData = CallAct('upvault', 'GetMoveData', ply, obsTrace, vaultTrace, refVel)

	local mins, maxs = vaultTrace.mins, vaultTrace.maxs
	local plyHeight = maxs[3] - mins[3]

	local obsHeight = climbTrace.HitPos[3] - obsTrace.StartPos[3]
	local threshold = self.ConVars.upctrl_vault_th:GetFloat() * plyHeight

	if obsHeight < threshold then
		climbMoveData.endpos[3] = vaultTrace.StartPos[3]

		return {
			upvault = vaultMoveData
			rhythm = 'upvault'
		}
	else
		return {
			uplowclimb = climbMoveData,
			upvault = vaultMoveData,
			rhythm = 'uplowclimb'
		}
	end
end

function upvaultd:Start(ply, data)
	local rhythm = data.rhythm
	CallAct('upvault', 'Start', ply, data[rhythm])
end

function upvaultd:Think(ply, data, mv, cmd)
	local rhythm = data.rhythm
	local isClimbEnd = CallAct('upvault', 'Think', ply, data[rhythm], mv, cmd)
end

function upvaultd:Clear(ply, data, mv, cmd)
	if CLIENT then 
		SetMoveControl(false, false, 0, 0)
	elseif SERVER then
		if mv and istable(data) and isnumber(data.endspeed) and isvector(data.dirNorm) then
			mv:SetVelocity(data.endspeed * data.dirNorm)
		end
    end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end
end

if CLIENT then

end
