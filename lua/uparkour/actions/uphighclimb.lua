--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 低爬 ===============
local XYNormal = UPar.XYNormal
local ObsDetector = UPar.ObsDetector
local ClimbDetector = UPar.ClimbDetector
local IsPlyStartSolid = UPar.IsPlyStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3

local uphighclimb = UPAction:Register('uphighclimb', {
	AAAACreat = '白狼',
	AAADesc = '#uphighclimb.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#uphighclimb',
	defaultDisabled = false,
	defaultKeybind = '[33,79,65]'
})

uphighclimb:InitConVars({
	{
		name = 'upctrl_los_cos',
		default = '0.64',
		invisible = true
	},

	{
		name = 'uphc_blen',
		default = '0.5',
		widget = 'NumSlider',
		min = 0, max = 2, decimals = 2,
		help = true
	},

	{
		name = 'uphc_max',
		default = '1.3',
		widget = 'NumSlider',
		min = 0.86, max = 2, decimals = 2,
		help = true
	},

	{
		name = 'uphc_min',
		default = '0.86',
		widget = 'NumSlider',
		min = 0.86, max = 2, decimals = 2,
	},

	{
		name = 'uphc_speed',
		default = '1 0.25 0.25',
		widget = 'UParVecEditor',
		min = 0, max = 2, decimals = 2, interval = 0.1,
		help = true
	}
})

function uphighclimb:Detector(ply, pos, dirNorm)
	pos = isvector(pos) and pos or ply:GetPos()
	dirNorm = isvector(dirNorm) and dirNorm:GetNormalized() or XYNormal(ply:EyeAngles():Forward())
	local convars = self.ConVars

	local omins, omaxs = ply:GetCollisionBounds()
	local plyWidth = math.max(omaxs[1] - omins[1], omaxs[2] - omins[2])
	local plyHeight = omaxs[3] - omins[3]
	
	local obsHeightMax = convars.uphc_max:GetFloat() * plyHeight
	local obsHeightMin = convars.uphc_min:GetFloat() * plyHeight

	omaxs[3] = obsHeightMax
	omins[3] = obsHeightMin

	local obsTrace = ObsDetector(ply, pos, 
		dirNorm * convars.uphc_blen:GetFloat() * plyWidth, 
		omins, omaxs, 
		convars.upctrl_los_cos:GetFloat())

	if not obsTrace then 
		return
	end

	local climbTrace = ClimbDetector(ply, obsTrace, 0.5 * plyWidth)

    if not climbTrace then 
        return 
    end

	return obsTrace, climbTrace
end

function uphighclimb:GetMoveData(ply, obsTrace, climbTrace, refVel)
	refVel = isvector(refVel) and refVel or ply:GetVelocity()
	
	local startpos = obsTrace.StartPos
	local endpos = climbTrace.HitPos + unitzvec
	local moveDis = (endpos - startpos):Length()

	local moveVec = ply:KeyDown(IN_SPEED)  
		and Vector(ply:GetJumpPower(), 0, ply:GetRunSpeed())
		or Vector(ply:GetJumpPower(), ply:GetWalkSpeed(), 0)

	local startspeed = math.max(
		Vector(self.ConVars.uphc_speed:GetString()):Dot(moveVec), 
		(obsTrace.Normal + unitzvec):Dot(refVel),
		10
	)

	local moveDuration = moveDis * 2 / startspeed

	if moveDuration <= 0 then 
		print('[uphighclimb]: Warning: moveDuration <= 0')
		return
	end
	
	return {
		startpos = startpos,
		endpos = endpos,

		startspeed = startspeed,
		endspeed = 0,

		starttime = CurTime(),

		needduck = IsPlyStartSolid(ply, endpos, false),
		duration = moveDuration
	}
end

function uphighclimb:Check(ply, pos, dirNorm, refVel)
	if not IsValid(ply) or not isentity(ply) or not ply:IsPlayer() then
		print('[uphighclimb]: Warning: Invalid player')
		return
	end

	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end

	local obsTrace, climbTrace = self:Detector(ply, pos, dirNorm)
	if not obsTrace or not climbTrace then 
		return
	end

	return self:GetMoveData(ply, obsTrace, climbTrace, refVel)
end

function uphighclimb:Start(ply, data)
    if CLIENT then 
		local timeout = isnumber(data.duration) and data.duration * 2 or 0.5
		local needduck = data.needduck
		SetMoveControl(true, true, 
			needduck and IN_JUMP or bit.bor(IN_DUCK, IN_JUMP),
			needduck and IN_DUCK or 0, 
			timeout)
	end
	
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_NOCLIP)
	end
end

function uphighclimb:Think(ply, data, mv, cmd)
	local startpos = data.startpos
	local endpos = data.endpos
	local startspeed = data.startspeed
	local endspeed = data.endspeed
	local duration = data.duration
	local starttime = data.starttime


	local speed_max = math.abs(math.max(startspeed, endspeed))
	local dt = CurTime() - starttime - 0.1
	local result = Hermite3(dt / duration, startspeed / speed_max, endspeed / speed_max)
	local endflag = dt > duration or result >= 1

	local curpos = endflag and endpos or LerpVector(result, startpos, endpos)

	mv:SetOrigin(curpos)

	return endflag
end


function uphighclimb:Clear(ply, data, mv, cmd)
	if CLIENT then 
		SetMoveControl(false, false, 0, 0)
    end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end
end

if CLIENT then
	UPar.SeqHookAdd('UParActKeyPress', 'test_uphighclimb', function(pressActs)
		if pressActs['uphighclimb'] then 
			UPar.Trigger(LocalPlayer(), 'uphighclimb')
		end
	end)

	UPar.SeqHookAdd('UParActCVarWidget_uphighclimb', 'default', function(cvCfg, panel)
		local cvName = cvCfg.name
		if cvName == 'uphc_blen' 
		or cvName == 'uphc_speed' 
		or cvName == 'uphc_min' 
		or cvName == 'uphc_max' then
			local created = UPar.SeqHookRun('UParActCVarWidget', 'uphighclimb', cvCfg, panel)
			if not created then
				return
			end

			local predi = panel:ControlHelp('')
			predi.NEXT = 0
			predi.Think = function(self)
				if CurTime() < self.NEXT then return end

				self.NEXT = CurTime() + 0.5

				local value = nil
				local cvar = UPar.GetActKeyValue('uphighclimb', 'ConVars')[cvCfg.name]
				if cvName == 'uphc_speed' then
					local ply = LocalPlayer()
					local cvarVal = Vector(cvar:GetString())
					local moveVec = Vector(ply:GetJumpPower(), ply:GetWalkSpeed(), 0)
					local moveVec2 = Vector(ply:GetJumpPower(), 0, ply:GetRunSpeed())
				
					value = string.format('%s, %s', 
						math.Round(cvarVal:Dot(moveVec), 2),
						math.Round(cvarVal:Dot(moveVec2), 2)
					)
				elseif cvName == 'uphc_min' or cvName == 'uphc_max' then
					local min, max = LocalPlayer():GetCollisionBounds()
					local plyHeight = max[3] - min[3]
					value = math.Round(plyHeight * cvar:GetFloat(), 2)
				elseif cvCfg.name == 'uphc_blen' then
					local min, max = LocalPlayer():GetCollisionBounds()
					local plyWidth = math.max(max[1] - min[1], max[2] - min[2])
					value = math.Round(plyWidth * cvar:GetFloat(), 2)
				end

				self:SetText(string.format('%s: %s', 
					language.GetPhrase('#upgui.predi'), 
					value
				))
			end

			predi.OnRemove = function(self) self.NEXT = nil end

			return true
		end
	end)
end
