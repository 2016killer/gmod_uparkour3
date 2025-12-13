--[[
	作者:白狼
	2025 11 1
]]--

-- ==================== 低爬 ===============
local action = UPAction:new('DParkour-LowClimb', {
	icon = 'dparkour/icon.jpg',
	label = 'dp_lc',
})

action:Register()
action:InitConVars({
	{
		name = 'dp_los_cos',
		default = '0.64',
		widget = 'NumSlider',
		min = 0,
		max = 1,
		decimals = 2,
		help = true,
		visible = false
	},

	{
		name = 'dp_lc_blen',
		default = '1.5',
		widget = 'NumSlider',
		min = 0,
		max = 2,
		decimals = 2,
		help = true,
	},

	{
		name = 'dp_lc_max',
		default = '0.85',
		widget = 'NumSlider',
		min = 0,
		max = 0.85,
		decimals = 2,
		help = true,
	},

	{
		name = 'dp_lc_min',
		default = '0.5',
		widget = 'NumSlider',
		min = 0,
		max = 0.85,
		decimals = 2,
	},

	{
		name = 'dp_lc_speed',
		default = '1 0.25 0.25',
		widget = 'VecEditor',
		min = 0,
		max = 5,
		decimals = 2,
	}
})

local XYNormal = UPar.XYNormal
local unitzvec = UPar.unitzvec

function action:GetSpeed(ply, ref)
	local refSpeed = (XYNormal(ply:EyeAngles():Forward()) + unitzvec):Dot(ref) * 0.707
	local moveVector = Vector(
		ply:GetJumpPower(), 
		ply:KeyDown(IN_SPEED) and ply:GetRunSpeed() or 0, 
		ply:GetWalkSpeed()
	)

	local speed = Vector(self.ConVars.dp_lc_speed:GetString()):Dot(moveVector)
	
	return math.max(speed, refSpeed), 0
end

function action:Start(ply, data)
    if CLIENT then 
		local needduck = UPar.GeneralLandSpaceCheck(ply, data.endpos)
		UPar.SetMoveControl(ply, true, true, 
			needduck and IN_JUMP or bit.bor(IN_DUCK, IN_JUMP),
			needduck and IN_DUCK or 0)
	end
	
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_NOCLIP)
	end
end

function action:Play(ply, mv, cmd, data)
	local startpos = data.startpos
	local endpos = data.endpos
	local startspeed = data.startspeed
	local endspeed = data.endspeed
	local duration = data.duration
	local starttime = data.starttime
	local dir = data.dir
	
	local dt = CurTime() - starttime

    local acc = (endspeed - startspeed) / duration
	local endflag = dt > duration

	mv:SetOrigin(startpos + (0.5 * acc * dt * dt + startspeed * dt) * dir)

	if endflag then 
		return landpos
	else
		return nil
	end
end

function action:Clear(ply, mv, cmd, data)
	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end

	if SERVER then
	    if mv and UPar.GeneralLandSpaceCheck(ply, ply:GetPos()) then
			mv:SetOrigin(data.endpos)
		end
    end
end
