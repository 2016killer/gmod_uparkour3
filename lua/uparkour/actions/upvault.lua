--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 翻越 ===============
local XYNormal = UPar.XYNormal
local ObsDetector = UPar.ObsDetector
local ClimbDetector = UPar.ClimbDetector
local VaultDetector = UPar.VaultDetector
local IsPlyStartSolid = UPar.IsPlyStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3


local upvault = UPAction:Register('upvault', {
	AAAACreat = '白狼',
	AAADesc = '#upvault.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upvault',
	defaultDisabled = false,
	defaultKeybind = '[33,79,65]'
})

upvault:InitConVars({
	{
		name = 'upvt_ehlen',
		default = '2',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'upvt_speed',
		default = '1 1 1',
		widget = 'UParVecEditor',
		min = 0, max = 2, decimals = 2, interval = 0.1,
		help = true
	}
})

-- 为了加速检测, 这里需要复用 uplowclimb 的检测缓存, 所以 upvault 是无法独立检测的
function upvault:Detector(ply, obsTrace, climbTrace)
	local mins, maxs = climbTrace.mins, climbTrace.maxs
	local plyWidth = math.max(maxs[1] - mins[1], maxs[2] - mins[2])

    local ehlen = self.ConVars.upvt_ehlen:GetFloat() * plyWidth
	local vaultTrace = VaultDetector(ply, obsTrace, climbTrace, ehlen)

	return vaultTrace
end

function upvault:GetMoveData(ply, obsTrace, vaultTrace, refVel)
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
		Vector(self.ConVars.upvt_speed:GetString()):Dot(moveVec), 
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

function upvault:Check(ply, obsTrace, climbTrace, refVel)
	if not obsTrace or not climbTrace then
		return
	end

	if not IsValid(ply) or not isentity(ply) or not ply:IsPlayer() then
		print('[upvault]: Warning: Invalid player')
		return
	end

	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end

	local vaultTrace = self:Detector(ply, obsTrace, climbTrace)

	if not vaultTrace then
		return 
	end

	return self:GetMoveData(ply, obsTrace, vaultTrace, refVel)
end

function upvault:Start(ply, data)
    if CLIENT then 
		local timeout = isnumber(data.duration) and data.duration * 2 or 0.5
		local needduck = false
		SetMoveControl(true, true, 
			needduck and IN_JUMP or bit.bor(IN_DUCK, IN_JUMP),
			needduck and IN_DUCK or 0, 
			timeout)
	end
	
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_NOCLIP)
	end
end

function upvault:Think(ply, data, mv, cmd)
	local startpos = data.startpos
	local endpos = data.endpos
	local startspeed = data.startspeed
	local endspeed = data.endspeed
	local duration = data.duration
	local starttime = data.starttime

	local speed_max = math.abs(math.max(startspeed, endspeed))
	local dt = CurTime() - starttime
	local result = Hermite3(dt / duration, startspeed / speed_max, endspeed / speed_max)
	local endflag = dt > duration or result >= 1

	local curpos = endflag and endpos or LerpVector(result, startpos, endpos) + (-100 / duration * dt * dt + 100 * dt) * unitzvec

	mv:SetOrigin(curpos)

	return endflag
end

function upvault:Clear(ply, data, mv, cmd)
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
