--[[
	作者:白狼
	2025 12 27
]]--

-- ==================== 二段翻越 ===============
-- 为了加速检测, 这里需要复用攀爬的检测, 所以翻越是无法独立检测的

local XYNormal = UPar.XYNormal
local ObsDetector = UPar.ObsDetector
local ClimbDetector = UPar.ClimbDetector
local VaultDetector = UPar.VaultDetector
local IsInSolid = UPar.IsInSolid
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
		name = 'upctrl_vt_evlen',
		default = '0.6',
		invisible = true
	},

	{
		name = 'upctrl_vtd_thr',
		default = '0.25',
		invisible = true
	},

	{
		name = 'upvtdl_ehlen',
		default = '1',
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
	local convars = self.ConVars

	return VaultDetector(ply, obsTrace, climbTrace, 
		convars.upvtdl_ehlen:GetFloat(), 
		convars.upctrl_vt_evlen:GetFloat()
	)
end

function upvaultdl:GetVaultMoveData(ply, obsTrace, vaultTrace, refVel)
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
		endvel = dirNorm * endspeed,
	}
end

function upvaultdl:GetMoveData(ply, obsTrace, climbTrace, vaultTrace, refVel)
	local vaultMoveData = self:GetVaultMoveData(ply, obsTrace, vaultTrace, refVel)
	
	if not vaultMoveData then
		return
	end

	local threshold = obsTrace.plyh * self.ConVars.upctrl_vtd_thr:GetFloat()
	if vaultMoveData.endpos[3] - vaultMoveData.startpos[3] < threshold then
		return {{}, vaultMoveData, rhythm = 2}
	else
		-- 二段翻越
		local climbMoveData = CallAct('uplowclimb', 'GetMoveData', ply, obsTrace, climbTrace, refVel)
		climbMoveData.endpos[3] = vaultMoveData.endpos[3]
		climbMoveData.endspeed = climbMoveData.startspeed * 0.3
		climbMoveData.duration = (climbMoveData.startpos - climbMoveData.endpos):Length() * 2 / 
		(climbMoveData.startspeed + climbMoveData.endspeed)
		

		vaultMoveData.startpos = climbMoveData.endpos
		vaultMoveData.startspeed = climbMoveData.endspeed
		vaultMoveData.duration = (vaultMoveData.startpos - vaultMoveData.endpos):Length() * 2 / 
		(vaultMoveData.startspeed + vaultMoveData.endspeed)

		return {climbMoveData, vaultMoveData, rhythm = 1}
	end
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

	return self:GetMoveData(ply, obsTrace, climbTrace, vaultTrace, refVel)
end

function upvaultdl:Start(ply, data)
    if CLIENT then 
		local timeout = ((isnumber(data[1].duration) and data[1].duration or 0) + 
			(isnumber(data[2].duration) and data[2].duration or 0)) + 0.5

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
	if data.rhythm == 1 then
		local isClimbEnd = CallAct('uplowclimb', 'Think', ply, data[1], mv, cmd)
		if isClimbEnd then 
			data.rhythm = 2
			data[2].starttime = CurTime()
			UPar.ActEffRhythmChange(ply, self, data)
		end
	elseif data.rhythm == 2 then
		return CallAct('upvault', 'Think', ply, data[2], mv, cmd)
	end
end

function upvaultdl:Clear(ply, data, mv, cmd)
	if CLIENT then 
		SetMoveControl(false, false, 0, 0)
	elseif SERVER then
		if mv and istable(data) and istable(data[2]) and isvector(data[2].endvel) then
			mv:SetVelocity(data[2].endvel)
		end
    end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end
end
