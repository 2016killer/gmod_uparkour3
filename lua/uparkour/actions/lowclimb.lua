--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 低爬 ===============
local ClimbDetector = UPar.ClimbDetector
local IsStartSolid = UPar.IsStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec

local action = UPAction:Register('lowclimb', {
	AAAACreat = '白狼',
	AAADesc = 'upgui.act.lowclimb.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upgui.act.lowclimb',
	defaultDisabled = false,
	defaultPredictionMode = false,
	defaultKeybind = '[33,79,65]'
})

action:InitConVars({
	{
		name = 'los_cos',
		default = '0.64',
		invisible = true
	},

	{
		name = 'lc_blen',
		label = '#upgui.act.lc.blen',
		default = '1.5',
		widget = 'NumSlider',
		min = 0, max = 2, decimals = 2,
		help = '#upgui.act.lc.blen.help'
	},

	{
		name = 'lc_max',
		label = '#upgui.act.lc.max',
		default = '0.85',
		widget = 'NumSlider',
		min = 0, max = 0.85, decimals = 2,
		help = '#upgui.act.lc.max.help'
	},

	{
		name = 'lc_min',
		label = '#upgui.act.lc.min',
		default = '0.5',
		widget = 'NumSlider',
		min = 0, max = 0.85, decimals = 2
	},

	{
		name = 'lc_speed',
		label = '#upgui.act.lc.speed',
		default = '1 0.25 0.25',
		widget = 'UParVecEditor',
		min = 0, max = 2, decimals = 2
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
	
	local obsHeightMax = convars.lc_max:GetFloat() * plyHeight
	local obsHeightMin = convars.lc_min:GetFloat() * plyHeight
    local blen = convars.lc_blen:GetFloat() * plyWidth

	omaxs[3] = obsHeightMax
	omins[3] = obsHeightMin

	// print(obsHeightMax, obsHeightMin)
	loscos = isnumber(loscos) and loscos or convars.los_cos:GetFloat()

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
	local moveDir = (landpos - pos) / moveDis
	local moveDuration = moveDis * 2 / (startspeed + endspeed)
	
	return {
		dir = moveDir,
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
		Vector(self.ConVars.lc_speed:GetString()):Dot(moveVector), 
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
	// local endpos = data.endpos
	local startspeed = data.startspeed
	// local endspeed = data.endspeed
	local duration = data.duration
	local starttime = data.starttime
	local dir = data.dir
	local acc = data.acc or (data.endspeed - startspeed) / duration
	
	local dt = CurTime() - starttime
	local endflag = dt > duration

	dt = math.Clamp(dt, 0, duration)
	local curpos = startpos + (0.5 * acc * dt * dt + startspeed * dt) * dir

	data.curpos = curpos
	mv:SetOrigin(curpos)

	return endflag
end

function action:Clear(ply, data, mv, cmd)
	if SERVER then
	    if mv and istable(data) and isvector(data.curpos) and isvector(data.endpos)
			and IsStartSolid(ply, data.curpos, true)
		then
			mv:SetOrigin(data.endpos)
			mv:SetVelocity(unitzvec)
		end
	elseif CLIENT then 
		SetMoveControl(false, false, 0, 0)
    end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end
end

if SERVER then
	hook.Add('KeyPress', 'aaaaaaa', function(ply, key)
		if key == IN_JUMP then 
			UPar.Trigger(ply, 'lowclimb')
		end
	end)
end
