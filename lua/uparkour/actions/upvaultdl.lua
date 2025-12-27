--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 二段翻越 ===============
-- 为了加速检测, 这里需要复用攀爬的检测, 所以翻越是无法独立检测的

local XYNormal = UPar.XYNormal
local ObsDetector = UPar.ObsDetector
local ClimbDetector = UPar.ClimbDetector
local VaultDetector = UPar.VaultDetector
local IsPlyStartSolid = UPar.IsPlyStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3
local CallAct = UPar.CallAct

local upvaultdl = UPAction:Register('upvaultdl', {
	AAAACreat = '白狼',
	AAADesc = '#upvaultdl.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upvaultdl',
	defaultDisabled = false
})

upvaultdl:InitConVars({
	{
		name = 'upctrl_vt_ehlen',
		default = '0.6',
		invisible = true
	},

	{
		name = 'upvtdl_ehlen',
		default = '2',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'upvtdl_speed',
		default = '1 1 1',
		widget = 'UParVecEditor',
		min = 0, max = 2, decimals = 2, interval = 0.1,
		help = true
	}
})

function upvaultdl:Detector(ply, obsTrace, climbTrace)
	local mins, maxs = climbTrace.mins, climbTrace.maxs
	local plyWidth = math.max(maxs[1] - mins[1], maxs[2] - mins[2])
	local plyHeight = maxs[3] - mins[3]

	local ehlen = self.ConVars.upvtdl_ehlen:GetFloat() * plyWidth
	local evlen = self.ConVars.upctrl_vt_ehlen:GetFloat() * plyHeight
	local vaultTrace = VaultDetector(ply, obsTrace, climbTrace, ehlen, evlen)

	return vaultTrace
end

function upvaultdl:GetMoveData(ply, obsTrace, vaultTrace, refVel)
	refVel = isvector(refVel) and refVel or ply:GetVelocity()

	local dirNorm = obsTrace.Normal
	local startpos = obsTrace.StartPos
	local endpos = vaultTrace.HitPos + unitzvec
	local moveDis = (endpos - startpos):Length()

	local startspeed = math.max(10, obsTrace.Normal:Dot(refVel))

	local moveVec = ply:KeyDown(IN_SPEED)  
		and Vector(ply:GetJumpPower(), 0, ply:GetRunSpeed())
		or Vector(ply:GetJumpPower(), ply:GetWalkSpeed(), 0)

	local endspeed = math.max(
		Vector(self.ConVars.upvtdl_speed:GetString()):Dot(moveVec), 
		startspeed
	)

	local moveDuration = moveDis * 2 / (startspeed + endspeed)

	if moveDuration <= 0 then 
		print('[uplowclimb]: Warning: moveDuration <= 0')
		return
	end

	return {
		startpos = startpos,
		endpos = endpos,

		startspeed = startspeed,
		endspeed = endspeed,

		starttime = CurTime(),

		duration = moveDuration,
		dirNorm = dirNorm,
	}
end

function upvaultdl:Check(ply, obsTrace, climbTrace, refVel)
	if not obsTrace or not climbTrace then
		return
	end

	if not IsValid(ply) or not isentity(ply) or not ply:IsPlayer() then
		print('[upvaultdl]: Warning: Invalid player')
		return
	end

	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end

	local vaultTrace = self:Detector(ply, obsTrace, climbTrace)
	if not vaultTrace then
		return
	end


	local climbMoveData = CallAct('uplowclimb', 'GetMoveData', ply, obsTrace, climbTrace, refVel)
	local vaultMoveData = self:GetMoveData(ply, obsTrace, vaultTrace, refVel)

	local mins, maxs = vaultTrace.mins, vaultTrace.maxs
	local plyHeight = maxs[3] - mins[3]

	local obsHeight = climbTrace.HitPos[3] - obsTrace.StartPos[3]
	local threshold = self.ConVars.upctrl_vt_ehlen:GetFloat() * plyHeight

	if obsHeight < threshold then
		climbMoveData.endpos[3] = vaultTrace.StartPos[3]

		return {
			[1] = nil,
			[2] = vaultMoveData,
			rhythm = 1
		}
	else
		return {
			[1] = climbMoveData,
			[2] = vaultMoveData,
			rhythm = 1
		}
	end
end

function upvaultdl:Start(ply, data)
	local rhythm = data.rhythm
	CallAct('upvault', 'Start', ply, data[rhythm])
end

function upvaultdl:Think(ply, data, mv, cmd)
	// local rhythm = data.rhythm
	// local isClimbEnd = CallAct('upvault', 'Think', ply, data[rhythm], mv, cmd)
	return true
end

function upvaultdl:Clear(ply, data, mv, cmd)
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
