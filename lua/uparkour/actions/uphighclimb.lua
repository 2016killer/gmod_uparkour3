--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 低爬 ===============
local ClimbDetector = UPar.ClimbDetector
local IsStartSolid = UPar.IsStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3

local action = UPAction:Register('uphighclimb', {
	AAAACreat = '白狼',
	AAADesc = '#uphighclimb.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#uphighclimb',
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

function action:Check(ply, pos, dirNorm, loscos, refVel)
	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end

	local convars = self.ConVars

	local omins, omaxs = ply:GetCollisionBounds()
	local plyWidth = math.max(omaxs[1] - omins[1], omaxs[2] - omins[2])
	local plyHeight = omaxs[3] - omins[3]
	
	local obsHeightMax = convars.uphc_max:GetFloat() * plyHeight
	local obsHeightMin = convars.uphc_min:GetFloat() * plyHeight
    local blen = convars.uphc_blen:GetFloat() * plyWidth

	omaxs[3] = obsHeightMax
	omins[3] = obsHeightMin

	// print(obsHeightMax, obsHeightMin)
	loscos = isnumber(loscos) and loscos or convars.upctrl_los_cos:GetFloat()

	local pos, dirNorm, landpos, blockheight = ClimbDetector(
		ply, 
		pos,
		dirNorm,
        omins,
		omaxs,
		blen,
		0.5 * plyWidth,
		loscos
	)

    if not landpos then 
        return 
    end

	// print(pos, dirNorm, landpos, blockheight)
	local startspeed, endspeed = self:GetSpeed(ply, dirNorm, refVel)
	local moveDis = (landpos - pos):Length()
	local moveDuration = moveDis * 2 / (startspeed + endspeed)
	
	return {
		startpos = pos,
		endpos = landpos,

		startspeed = startspeed,
		endspeed = endspeed,

		starttime = CurTime(),

		needduck = IsStartSolid(ply, landpos, false),
		duration = moveDuration
	}
end

function action:GetSpeed(ply, dirNorm, refVel)
	refVel = isvector(refVel) and refVel or ply:GetVelocity()
	dirNorm = isvector(dirNorm) and dirNorm:GetNormalized() or XYNormal(ply:EyeAngles():Forward())
	
	local refSpeed = (dirNorm + unitzvec):Dot(refVel)
	local moveVector = Vector(
		ply:GetJumpPower(), 
		ply:KeyDown(IN_SPEED) and ply:GetRunSpeed() or 0, 
		ply:GetWalkSpeed()
	)
	
	return math.max(
		Vector(self.ConVars.uphc_speed:GetString()):Dot(moveVector), 
		refSpeed,
		10
	), 0
end

function action:Start(ply, data)
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

function action:Think(ply, data, mv, cmd)
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


function action:Clear(ply, data, mv, cmd)
	if CLIENT then 
		SetMoveControl(false, false, 0, 0)
    end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end
end

if CLIENT then
	function action:OnKeyPress()
		UPar.Trigger(LocalPlayer(), self.Name)
	end

	UPar.SeqHookAdd('UParActCVarWidget_uphighclimb', 'default', function(cvCfg, panel)
		if cvCfg.name == 'uphc_blen' or cvCfg.name == 'uphc_speed' or cvCfg.name == 'uphc_min' or cvCfg.name == 'uphc_max' then
			local created = UPar.SeqHookRun('UParActCVarWidget', 'uphighclimb', cvCfg, panel)
			if not created then
				return
			end

			local predi = panel:ControlHelp('')
			predi.Think = function(self)
				if CurTime() < (self.NextThinkTime or 0) then
					return
				end

				self.NextThinkTime = CurTime() + 0.5
				local value = nil
				if cvCfg.name == 'uphc_speed' then
					value = action:GetSpeed(LocalPlayer(), unitzvec, unitzvec)
					value = math.Round(value, 2)
				elseif cvCfg.name == 'uphc_min' or cvCfg.name == 'uphc_max' then
					local min, max = LocalPlayer():GetCollisionBounds()
					local plyHeight = max[3] - min[3]
					if cvCfg.name == 'uphc_max' then
						value = plyHeight * action.ConVars.uphc_max:GetFloat()
					else
						value = plyHeight * action.ConVars.uphc_min:GetFloat()
					end
					value = math.Round(value, 2)
				elseif cvCfg.name == 'uphc_blen' then
					local min, max = LocalPlayer():GetCollisionBounds()
					local plyWidth = math.max(max[1] - min[1], max[2] - min[2])
					value = plyWidth * action.ConVars.uphc_blen:GetFloat()
					value = math.Round(value, 2)
				end

				self:SetText(string.format('%s: %s', 
					language.GetPhrase('#upgui.predi'), 
					value
				))
			end

			predi.OnRemove = function(self)
				self.NextThinkTime = nil
			end

			return true
		end
	end)
end
