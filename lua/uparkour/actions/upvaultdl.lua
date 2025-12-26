--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 翻越 ===============
local XYNormal = UPar.XYNormal
local ObsDetector = UPar.ObsDetector
local ClimbDetector = UPar.ClimbDetector
local VaultDetector = UPar.VaultDetector
local IsStartSolid = UPar.IsStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3


local upvaultdl = UPAction:Register('upvaultdl', {
	AAAACreat = '白狼',
	AAADesc = '#upvaultdl.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upvaultdl',
	defaultDisabled = false,
	defaultKeybind = '[33,79,65]'
})

upvaultdl:InitConVars({
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

function upvaultdl:Check(ply, obsTrace, climbTrace)
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

	local convars = self.ConVars

	local pmins, pmaxs = ply:GetHull()
	local plyHeight = pmaxs[3] - pmins[3]

    local ehlen = convars.upvt_ehlen:GetFloat() * plyHeight
	local vaultTrace = VaultDetector(ply, obsTrace, climbTrace, ehlen)

	if not vaultTrace then
		return 
	end

	local dirNorm = obsTrace.Normal
	local pos = obsTrace.StartPos
	local vaultpos = vaultTrace.HitPos + math.min(2, vaultTrace.leftdis) * dirNorm
	local moveDis = (vaultpos - pos):Length()
	local startspeed, endspeed = self:GetSpeed(ply, dirNorm, refVel)
	local moveDuration = moveDis * 2 / (startspeed + endspeed)

	if moveDuration <= 0 then 
		print('[uplowclimb]: Warning: moveDuration <= 0')
		return
	end

	return {
		startpos = pos,
		endpos = vaultpos,

		startspeed = startspeed,
		endspeed = endspeed,

		starttime = CurTime(),

		duration = moveDuration,
		dirNorm = dirNorm,
	}, vaultTrace
end

function upvaultdl:GetSpeed(ply, dirNorm, refVel)
	refVel = isvector(refVel) and refVel or ply:GetVelocity()
	dirNorm = isvector(dirNorm) and dirNorm:GetNormalized() or XYNormal(ply:EyeAngles():Forward())
	
	local startspeed = dirNorm:Dot(refVel)
	local moveVector = Vector(
		ply:GetJumpPower(), 
		ply:KeyDown(IN_SPEED) and ply:GetRunSpeed() or 0, 
		ply:GetWalkSpeed()
	)
	
	return math.max(startspeed, 0), math.max(
		Vector(self.ConVars.upvt_speed:GetString()):Dot(moveVector), 
		startspeed,
		10
	)
end

function upvaultdl:Start(ply, data)
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

function upvaultdl:Think(ply, data, mv, cmd)
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
	UPar.SeqHookAdd('UParActKeyPress', 'test_upvaultdl', function(pressActs)
		if pressActs['upvaultdl'] then 
			local _, obsTrace, climbTrace = UPar.CallAct('uplowclimb', 'Check', LocalPlayer())
			UPar.Trigger(LocalPlayer(), 'upvaultdl', nil, obsTrace, climbTrace)
		end
	end)
end
