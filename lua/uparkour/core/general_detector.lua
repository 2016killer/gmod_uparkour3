--[[
	作者:白狼
	2025 11 1

--]]
local unitzvec = UPar.unitzvec
local function XYNormal(v)
	v = Vector(v)
	v[3] = 0
	v:Normalize()
	return v
end

UPar.XYNormal = XYNormal

UPar.ObsDetector = function(ply, pos, dir, omins, omaxs, loscos)
	-- 获取障碍位置
	-- pos 检测位置
	-- dir 检测方向
	-- omins, omaxs 碰撞盒
	-- loscos 视线余弦值

	local obsTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = pos,
		endpos = pos + dir,
		mins = omins,
		maxs = omaxs
	})

	UPar.debugwireframebox(obsTrace.HitPos, omins, omaxs, 3, 
		(obsTrace.StartSolid or obsTrace.Hit) and Color(255, 0, 0) or Color(0, 255, 0), 
		true)

	if obsTrace.StartSolid or not obsTrace.Hit or obsTrace.HitNormal[3] >= 0.707 then
		return
	end

	if isnumber(loscos) and XYNormal(-obsTrace.HitNormal):Dot(dir:GetNormalized()) < loscos then 
		return 
	end

	if SERVER and IsValid(obsTrace.Entity) and obsTrace.Entity:IsPlayerHolding() then
		return
	end

	obsTrace.mins = omins
	obsTrace.maxs = omaxs
	obsTrace.loscos = loscos

	return obsTrace
end

UPar.ClimbDetector = function(ply, obsTrace, ehlen)
	-- obsTrace 障碍检测结果
	-- ehlen 落脚点距离

	local pos = obsTrace.StartPos
	local obsPos = obsTrace.HitPos
	local maxh = obsTrace.maxs[3]
	local minh = obsTrace.mins[3]
	local dirNorm = obsTrace.Normal

	-- 确保落脚点有足够空间, 所以检测蹲碰撞盒
	local evlen = maxh - minh
	local dmins, dmaxs = ply:GetHullDuck()

	local startpos = obsPos + Vector(0, 0, maxh) + dirNorm * ehlen
	local endpos = startpos - Vector(0, 0, evlen)

	local climbTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = endpos,
		mins = dmins,
		maxs = dmaxs,
	})

	UPar.debugwireframebox(climbTrace.StartPos, dmins, dmaxs, 3, Color(0, 255, 255), true)

	-- 确保不在滑坡上且在障碍物上
	if not climbTrace.Hit or climbTrace.HitNormal[3] < 0.707 then
		return
	end

	-- 检测落脚点是否有足够空间
	-- OK, 预留1的单位高度防止极端情况
	if climbTrace.StartSolid or climbTrace.Fraction * evlen < 1 then
		return
	end

	UPar.debugwireframebox(climbTrace.HitPos, dmins, dmaxs, 3, nil, true)
	
	climbTrace.mins = dmins
	climbTrace.maxs = dmaxs
	climbTrace.leftdis = climbTrace.Fraction * evlen

	return climbTrace
end

UPar.IsPlyStartSolid = function(ply, startpos, cur)
	local pmins, pmaxs = nil
	if cur then
		pmins, pmaxs = ply:GetCollisionBounds()
	else
		pmins, pmaxs = ply:GetHull()
	end

	startpos = isvector(startpos) and startpos or ply:GetPos()

	local spacecheck = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = startpos,
		mins = pmins,
		maxs = pmaxs,
	})
	
	UPar.debugwireframebox(startpos, pmins, pmaxs, 3, 
		(spacecheck.StartSolid or spacecheck.Hit) and Color(255, 0, 0) or Color(0, 255, 0), 
		true)

	return spacecheck.StartSolid or spacecheck.Hit 
end

UPar.VaultDetector = function(ply, obsTrace, climbTrace, ehlen)
	-- obsTrace 障碍检测结果
	-- climbTrace 攀爬检测结果
	-- ehlen 水平距离

	local pos = obsTrace.StartPos
	local dirNorm = obsTrace.Normal
	local landpos = climbTrace.HitPos

	local dmins, dmaxs = climbTrace.mins, climbTrace.maxs
	local plyWidth = math.max(dmaxs[1] - dmins[1], dmaxs[2] - dmins[2])

	-- 简单检测一下是否会被阻挡
	local linelen = ehlen + 0.707 * plyWidth
	local line = dirNorm * linelen
	
	local simpletrace1 = util.QuickTrace(landpos + Vector(0, 0, dmaxs[3]), line, ply)
	local simpletrace2 = util.QuickTrace(landpos + Vector(0, 0, dmaxs[3] * 0.5), line, ply)
	
	debugoverlay.Line(
		landpos + Vector(0, 0, dmaxs[3]), 
		landpos + Vector(0, 0, dmaxs[3]) + line, 
		3, nil, true)

	debugoverlay.Line(
		landpos + Vector(0, 0, dmaxs[3] * 0.5), 
		landpos + Vector(0, 0, dmaxs[3] * 0.5) + line, 
		3, nil, true)

	if simpletrace1.StartSolid or simpletrace2.StartSolid then
		return
	end

	-- 更新水平检测范围
	local maxVaultWidth, maxVaultWidthVec
	if simpletrace1.Hit or simpletrace2.Hit then
		maxVaultWidth = math.max(
			0, 
			linelen * math.min(simpletrace1.Fraction, simpletrace2.Fraction) - plyWidth * 0.707
		)
		maxVaultWidthVec = dirNorm * maxVaultWidth
	else
		maxVaultWidth = ehlen
		maxVaultWidthVec = dirNorm * maxVaultWidth
	end
 
	local startpos = landpos + maxVaultWidthVec
	local endpos = startpos - Vector(0, 0, landpos[3] - pos[3])

	local vtrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = endpos,
		mins = dmins,
		maxs = dmaxs,
	})

	UPar.debugwireframebox(vtrace.HitPos, dmins, dmaxs, 3, Color(255, 0, 255), true)

	if vtrace.StartSolid then
		return
	end

	local pmins, pmaxs = ply:GetHull()
	startpos = vtrace.HitPos + unitzvec
	endpos = startpos - maxVaultWidthVec

	local vaultTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = endpos,
		mins = pmins,
		maxs = pmaxs,
	})

	if vaultTrace.StartSolid or not vaultTrace.Hit then
		return
	end

	UPar.debugwireframebox(vaultTrace.HitPos, pmins, pmaxs, 3, nil, true)

	vaultTrace.leftdis = vaultTrace.Fraction * maxVaultWidth

	return vaultTrace
end

UPar.GetFallDamageInfo = function(ply, fallspeed, ref)
	fallspeed = fallspeed or ply:GetVelocity()[3]
	if fallspeed < ref then
		local damage = hook.Run('GetFallDamage', ply, fallspeed) or 0
		if isnumber(damage) and damage > 0 then
			local d = DamageInfo()
			d:SetDamage(damage)
			d:SetAttacker(Entity(0))
			d:SetDamageType(DMG_FALL) 

			return d	
		end 
	end
end

UPar.Hermite3 = function(t_norm, m0, m1)
    local t = math.Clamp(t_norm, 0, 1)
    local t2 = t * t
    local t3 = t2 * t

    local h10 = t3 - 2 * t2 + t
    local h01 = -2 * t3 + 3 * t2
    local h11 = t3 - t2

    local result = m0 * h10 + h01 + m1 * h11

    return math.Clamp(result, 0, 1)
end