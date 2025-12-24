--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 低爬 ===============
local ClimbDetector = UPar.ClimbDetector
local VaultDetector = UPar.VaultDetector
local IsStartSolid = UPar.IsStartSolid
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
		name = 'upctrl_los_cos',
		default = '0.64',
		invisible = true
	},

	{
		name = 'upvt_hlen',
		default = '2',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'upvt_vlen',
		default = '0.5',
		widget = 'NumSlider',
		min = 0.25,
		max = 0.6,
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

function upvault:Check(ply, pos, dirNorm, refVel, landpos)
	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end

	print(pos, dirNorm, refVel, landpos)

	local convars = self.ConVars

	local omins, omaxs = ply:GetHull()
	local plyWidth = math.max(omaxs[1] - omins[1], omaxs[2] - omins[2])
	local plyHeight = omaxs[3] - omins[3]

    local hlen = convars.upvt_hlen:GetFloat() * plyWidth
    local vlen = convars.upvt_vlen:GetFloat() * plyHeight

	
	local pos, dirNorm, vaultpos, vaultheight = VaultDetector(ply, pos, dirNorm, landpos, hlen, vlen)

	if not vaultpos then
		return 
	end

	local startspeed, endspeed = self:GetSpeed(ply, dirNorm, refVel)

	if endspeed + startspeed <= 0 then 
		print('[UPar]: Warning: endspeed + startspeed <= 0')
		return
	end

	local moveDis = (vaultpos - pos):Length()
	local moveDuration = moveDis * 2 / (startspeed + endspeed)
	print(startspeed, endspeed, moveDis)
	return {
		startpos = pos,
		endpos = vaultpos,

		startspeed = startspeed,
		endspeed = endspeed,

		starttime = CurTime(),

		duration = moveDuration,

		dirNorm = dirNorm,
		blockheight = blockheight
	}

end

function upvault:GetSpeed(ply, dirNorm, refVel)
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
	UPar.SeqHookAdd('UParActKeyPress', 'test_upvault', function(pressActs)
		if pressActs['upvault'] then 
			local checkResult = UPar.CallAct('uplowclimb', 'Check', LocalPlayer())
			if not checkResult then 
				return
			end
			UPar.Trigger(LocalPlayer(), 'upvault', nil,
				checkResult.startpos,
				checkResult.dirNorm,
				nil,
				checkResult.endpos
			)
		end
	end)
end
