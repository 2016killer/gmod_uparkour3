--[[
	作者:白狼
	2025 11 1

--]]

local function XYNormal(v)
	v = Vector(v)
	v[3] = 0
	v:Normalize()
	return v
end
local unitzvec = Vector(0, 0, 1)

UPar.XYNormal = XYNormal
UPar.unitzvec = unitzvec



UPar.ClimbDetector = function(ply, pos, dirNorm, omins, omaxs, olen, ehlen, loscos)
	if not IsValid(ply) or not ply:IsPlayer() then
		print(string.format('Invalid ply "%s"', ply))
		return
	end

	pos = (isvector(pos) and pos or ply:GetPos()) + unitzvec
	dirNorm = isvector(dirNorm) and dirNorm:GetNormalized() or XYNormal(ply:EyeAngles():Forward())
	omins = isvector(omins) and omins or Vector(-16, -16, 32)
	omaxs = isvector(omaxs) and omaxs or Vector(16, 16, 54)
	olen = isnumber(olen) and olen or 48
	
	-- 主要是为了检查是否对准了障碍物和阻碍
	local obsTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = pos,
		endpos = pos + dirNorm * olen,
		mins = omins,
		maxs = omaxs,
	})

	UPar.debugwireframebox(obsTrace.HitPos, omins, omaxs, 3, 
		(obsTrace.StartSolid or obsTrace.Hit) and Color(255, 0, 0) or Color(0, 255, 0), 
		true)

	if obsTrace.StartSolid or not obsTrace.Hit or obsTrace.HitNormal[3] >= 0.707 then
		return
	end

	-- 判断是否对准了障碍物
	if isnumber(loscos) and XYNormal(-obsTrace.HitNormal):Dot(dir) < loscos then 
		return 
	end

	if SERVER and IsValid(obsTrace.Entity) and obsTrace.Entity:IsPlayerHolding() then
		return
	end
	
	ehlen = isnumber(ehlen) and ehlen or 16

	-- 确保落脚点有足够空间, 所以检测蹲碰撞盒
	local evlen = omaxs[3] - omins[3]
	local dmins, dmaxs = ply:GetHullDuck()

	local startpos = obsTrace.HitPos + Vector(0, 0, omaxs[3]) + dirNorm * ehlen
	local endpos = startpos - Vector(0, 0, evlen)

	local trace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = endpos,
		mins = dmins,
		maxs = dmaxs,
	})

	UPar.debugwireframebox(trace.StartPos, dmins, dmaxs, 3, Color(0, 255, 255), true)

	-- 确保不在滑坡上且在障碍物上
	if not trace.Hit or trace.HitNormal[3] < 0.707 then
		return
	end

	-- 检测落脚点是否有足够空间
	-- OK, 预留1的单位高度防止极端情况
	if trace.StartSolid or trace.Fraction * evlen < 1 then
		return
	end

	UPar.debugwireframebox(trace.HitPos, dmins, dmaxs, 3, nil, true)
	
	trace.HitPos[3] = trace.HitPos[3] + 1
	return pos, dirNorm, trace.HitPos, trace.HitPos[3] - pos[3]
end

UPar.IsStartSolid = function(ply, startpos)
	if not IsValid(ply) or not ply:IsPlayer() then
		print(string.format('Invalid ply "%s"', ply))
		return
	end

	local pmins, pmaxs = ply:GetHull()
	startpos = isvector(startpos) and startpos or ply:GetPos()

	local spacecheck = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = startpos,
		mins = pmins,
		maxs = pmaxs,
	})
	
	// UPar.debugwireframebox(startpos, pmins, pmaxs, 3, 
	// 	(spacecheck.StartSolid or spacecheck.Hit) and Color(255, 0, 0) or Color(0, 255, 0), 
	// 	true)

	return spacecheck.StartSolid or spacecheck.Hit 
end


UPar.VaultDetector = function(ply, pos, dirNorm, landpos, hlen, vlen)
	-- 通用翻越检查, 在 ClimbDetector 后面
	-- 主要检测障碍物的镜像面是否符合条件

	-- 不需要检查是否在斜坡上

	-- 假设蹲伏不会改变玩家宽度
	pos = (isvector(pos) and pos or ply:GetPos()) + unitzvec
	dirNorm = isvector(dirNorm) and dirNorm:GetNormalized() or XYNormal(ply:EyeAngles():Forward())
	hlen = isnumber(hlen) and hlen or 48
	vlen = isnumber(vlen) and vlen or 54

	local dmins, dmaxs = ply:GetHullDuck()
	local plyWidth = math.max(dmaxs[1] - dmins[1], dmaxs[2] - dmins[2])

	-- 简单检测一下是否会被阻挡
	local linelen = hlen + 0.707 * plyWidth
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
		maxVaultWidth = hlen
		maxVaultWidthVec = dirNorm * maxVaultWidth
	end
 
	local startpos = landpos + maxVaultWidthVec
	local endpos = startpos - Vector(0, 0, vlen)

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
	local htrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = endpos,
		mins = pmins,
		maxs = pmaxs,
	})

	if htrace.StartSolid or not htrace.Hit then
		return
	end

	UPar.debugwireframebox(htrace.HitPos, dmins, dmaxs, 3, nil, true)

	local vaultpos = htrace.HitPos + dirNorm * math.min(2, htrace.Fraction * maxVaultWidth)
	local vaultheight = vaultpos[3] - pos[3]

	return pos, dirNorm, vaultpos, vaultheight
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



if CLIENT then
	concommand.Add('test_is_startsolid', function(ply)
		UPar.IsStartSolid(ply)
	end)

	concommand.Add('test_climb_detector', function(ply)
		local landpos, height = UPar.ClimbDetector(ply)
		print(landpos, height)
	end)

	concommand.Add('test_vault_detector', function(ply)
		local landpos, height = UPar.ClimbDetector(ply)
		if not landpos then return end
		local vaultpos, vaultheight = UPar.VaultDetector(ply, nil, nil, landpos)
		print(vaultpos, vaultheight)
	end)
end