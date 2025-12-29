--[[
	作者:白狼
	2025 12 28
--]]

local zerovec = UPar.zerovec
local zeroang = UPar.zeroang
local diagonalvec = UPar.diagonalvec
local emptyTable = UPar.emptyTable

UPManip = UPManip or {}

local function SetBonePosition(ent, boneId, posw, angw) 
	-- 最好传入非奇异矩阵, 如果骨骼或父级的变换是奇异的, 则可能出现问题
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新
	-- 应该还能再优化

	if not IsValid(ent) or not isentity(ent) then
		print(string.format('[UPManip.SetBonePosition]: invaild ent "%s"', ent))
		return
	end
	
	if boneId == -1 then
		print('[SetBonePosition]: invalid boneId "-1"')
		return false
	end
	
	local curTransform = ent:GetBoneMatrix(boneId)
	if not curTransform then 
		// string.format('[SetBonePosition]: ent "%s" boneId "%s" no Matrix', ent, boneId)
		return false
	end
	
	local parentboneId = ent:GetBoneParent(boneId)
	local parentTransform = parentboneId == -1 and ent:GetWorldTransformMatrix() or ent:GetBoneMatrix(parentboneId)
	if not parentTransform then 
		// string.format('[SetBonePosition]: ent "%s" boneId "%s" no parent', ent, boneId)
		return false
	end

	local curTransformInvert = curTransform:GetInverse()
	if not curTransformInvert then 
		// print(string.format('[SetBonePosition]: ent "%s" boneId "%s" Matrix is Singular', ent, boneId))
		return false
	end

	local parentTransformInvert = parentTransform:GetInverse()
	if not parentTransformInvert then 
		// print(string.format('[SetBonePosition]: ent "%s" boneId "%s" parent Matrix is Singular', ent, boneId))
		return false
	end


	local curAngManip = Matrix()
	curAngManip:SetAngles(ent:GetManipulateBoneAngles(boneId))
	
	local tarRotate = Matrix()
	tarRotate:SetAngles(angw)


	local newManipAng = (curAngManip * curTransformInvert * tarRotate):GetAngles()
	local newManipPos = parentTransformInvert
		* (posw - curTransform:GetTranslation() + parentTransform:GetTranslation())
		+ ent:GetManipulateBonePosition(boneId)

	ent:ManipulateBoneAngles(boneId, newManipAng)
	ent:ManipulateBonePosition(boneId, newManipPos)

	return newManipAng, newManipPos
end

local function UnpackBMData(bmdata)
	-- 返回 骨骼名称, 偏移矩阵
	
	if istable(bmdata) then 
		local boneName = isstring(bmdata.boneName) and bmdata.boneName or nil
		
		local offsetMatrix = nil
		local offsetAng = bmdata.ang
		local offsetPos = bmdata.pos
		local offsetScale = bmdata.scale

		if isangle(offsetAng) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetAngles(offsetAng)
		end

		if isvector(offsetPos) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetTranslation(offsetPos)
		end

		if isvector(offsetScale) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetScale(offsetScale)
		end

		return boneName, offsetMatrix
	elseif isstring(bmdata) then 
		return bmdata, nil
	else
		return nil, nil
	end
end

local function ClearManip(ent, boneMapping)
	if not IsValid(ent) or not isentity(ent) then
		print(string.format('[UPManip.ClearManip]: invaild ent "%s"', ent))
		return
	end

	if istable(boneMapping) then
		for boneName, _ in pairs(boneMapping) do
			if not isstring(boneName) or string.Trim(boneName) == '' then 
				continue 
			end

			local boneId = ent:LookupBone(boneName)
			if not boneId then continue end

			ent:ManipulateBoneAngles(boneId, zeroang)
			ent:ManipulateBonePosition(boneId, zerovec)
			ent:ManipulateBoneScale(boneId, diagonalvec)
		end
	else
		for i = 0, ent:GetBoneCount() - 1 do
			ent:ManipulateBoneAngles(i, zeroang)
			ent:ManipulateBonePosition(i, zerovec)
			ent:ManipulateBoneScale(i, diagonalvec)
		end
	end
end

local function MarkBoneFamilyLevel(boneId, currentLevel, family, familyLevel, cached)
	cached = cached or {}

	if cached[boneId] then 
		print('What the hell are you doing?')
		return
	end
	cached[boneId] = true

	familyLevel[boneId] = currentLevel

	if not family[boneId] then
		return
	end
	
	for childIdx, _ in pairs(family[boneId]) do
		MarkBoneFamilyLevel(childIdx, currentLevel + 1, family, familyLevel, cached)
	end
end

local function GetBonesFamilyLevel(ent, useLRU2)
	if not IsValid(ent) or not isentity(ent) or not ent:GetModel() then
		print(string.format('[UPManip.GetBonesFamilyLevel]: invaild ent "%s"', ent))
		return
	end

	if useLRU2 then
		local bonesLevel = UPar.LRU2Get(string.format('BonesFamilyLevel_%s', ent:GetModel()))
		if istable(bonesLevel) then
			return bonesLevel
		end
	end

	ent:SetupBones()

    local boneCount = ent:GetBoneCount()
    local family = {} 
    local familyLevel = {}

    for boneIdx = 0, boneCount - 1 do
        local parentIdx = ent:GetBoneParent(boneIdx)
        
        if not family[parentIdx] then
            family[parentIdx] = {}
        end
        family[parentIdx][boneIdx] = true
    end

	if not family[-1] then
		print(string.format('[UPManip.GetBonesFamilyLevel]: ent "%s" no root bone', ent))
		return
	end

    MarkBoneFamilyLevel(-1, 0, family, familyLevel)

	if useLRU2 then
		UPar.LRU2Set(string.format('BonesFamilyLevel_%s', ent:GetModel()), familyLevel)
	end

	return familyLevel
end

local function GetBoneMappingKeysSorted(ent, boneMapping, useLRU2)
	local keys = {}

    for boneName, _ in pairs(boneMapping) do 
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		table.insert(keys, boneName) 
	end

	local familyLevel = GetBonesFamilyLevel(ent, useLRU2)
	if not familyLevel then
		print(string.format('[UPManip.GetBoneMappingKeysSorted]: ent "%s" no family level', ent))
		return
	end

    table.sort(keys, function(a, b)
		local boneIdA = ent:LookupBone(a)
		local boneIdB = ent:LookupBone(b)

        local levelA = familyLevel[boneIdA] or 999
        local levelB = familyLevel[boneIdB] or 999

        if levelA ~= levelB then
            return levelA < levelB
        end

        return boneIdA < boneIdB
    end)

	return keys
end

local function Snapshot(ent, boneMapping)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	local snapshot = {}
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		local transform = ent:GetBoneMatrix(boneId)
		snapshot[boneId] = {
			ent:WorldToLocal(transform:GetTranslation()),
			ent:WorldToLocalAngles(transform:GetAngles())
		} 
	end
	
	return snapshot
end

local function GetSnapshot(ent, pack)
	local bonePos, boneAng = unpack(pack or emptyTable)
	if not bonePos or not boneAng then 
		return nil, nil
	end
	return ent:LocalToWorld(bonePos), ent:LocalToWorldAngles(boneAng)
end

local function LerpBoneWorld(t, ent, target, boneMapping, boneKeys)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新
	t = math.Clamp(t, 0, 1)

	for i, boneName in ipairs(boneKeys) do
		local data = boneMapping[boneName]
		local boneId = ent:LookupBone(boneName)
		
		if not boneId then 
			continue
		end

		local boneMat = ent:GetBoneMatrix(boneId)
		if not boneMat then
			continue
		end

		local targetBoneName, offsetMatrix = UnpackBMData(data)
		local targetBoneId = target:LookupBone(targetBoneName or boneName)

		if not targetBoneId then 
			continue
		end
		
		local targetMatrix = target:GetBoneMatrix(targetBoneId)
		if not targetMatrix then 
			continue
		end
		
		if offsetMatrix then
			targetMatrix = targetMatrix * offsetMatrix
		end

		local newPos = LerpVector(t, boneMat:GetTranslation(), targetMatrix:GetTranslation())
		local newAng = LerpAngle(t, boneMat:GetAngles(), targetMatrix:GetAngles())
		local newScale = LerpVector(t, boneMat:GetScale(), targetMatrix:GetScale())

		ent:ManipulateBoneScale(boneId, newScale)
		SetBonePosition(ent, boneId, newPos, newAng)
	end
end

local function AnimFadeInIterator(dt, curTime, iteratorData)
	local boneMapping = iteratorData.boneMapping
	local boneKeys = iteratorData.boneKeys
	local speed = math.max(math.abs(iteratorData.speed), 0.01)
	local t = (iteratorData.t or 0) + dt * speed
	iteratorData.t = t

	local ent = iteratorData.ent
	if not IsValid(ent) or not isentity(ent) then 
		print(string.format('[UPManip.AnimFadeInIterator]: ent "%s" is not valid', ent))
		return true
	end

	local target = iteratorData.target
	if not IsValid(target) or not isentity(target) then 
		print(string.format('[UPManip.AnimFadeInIterator]: target "%s" is not valid', target))
		UPManip.AnimFadeOut(ent, boneMapping, 3, 2)
		return true
	end

	ent:SetupBones()
	target:SetupBones()

	LerpBoneWorld(t, ent, target, boneMapping, boneKeys)
end

local function AnimFadeOutIterator(dt, curTime, iteratorData)
	local boneMapping = iteratorData.boneMapping
	local speed = math.max(math.abs(iteratorData.speed), 0.01)
	local t = (iteratorData.t or 0) + dt * speed
	iteratorData.t = t

	local ent = iteratorData.ent
	if not IsValid(ent) then 
		print(string.format('[UPManip.AnimFadeOutIterator]: ent "%s" is not valid', ent))
		return true
	end

	ent:SetupBones()

	t = math.Clamp(t, 0, 1)
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then 
			continue
		end

		local curManipPos = ent:GetManipulateBonePosition(boneId)
		local curManipAng = ent:GetManipulateBoneAngles(boneId)
		local curManipScale = ent:GetManipulateBoneScale(boneId)

		ent:ManipulateBonePosition(boneId, LerpVector(t, curManipPos, zerovec))
		ent:ManipulateBoneAngles(boneId, LerpAngle(t, curManipAng, zeroang))
		ent:ManipulateBoneScale(boneId, LerpVector(t, curManipScale, diagonalvec))
	end

	return t <= 0
end

UPManip.SetBonePosition = SetBonePosition
UPManip.ClearManip = ClearManip
UPManip.UnpackBMData = UnpackBMData
UPManip.LerpBoneWorld = LerpBoneWorld
UPManip.Snapshot = Snapshot
UPManip.GetSnapshot = GetSnapshot
UPManip.GetBoneMappingKeysSorted = GetBoneMappingKeysSorted
UPManip.GetBonesFamilyLevel = GetBonesFamilyLevel

UPManip.AnimFadeIn = function(ent, target, boneMapping, speed, timeout)
	if not IsValid(ent) or not isentity(ent) or not ent:GetModel()
	or not IsValid(target) or not isentity(target) or not target:GetModel() then 
		return 
	end

	timeout = math.abs(isnumber(timeout) and timeout or 2)
	boneMapping = istable(boneMapping) and boneMapping or emptyTable

	ent:SetupBones()

	local boneKeys = GetBoneMappingKeysSorted(ent, boneMapping, true)
	if not boneKeys then
		return
	end

	local iteratorData = {
		ent = ent,
		target = target,
		boneMapping = boneMapping,
		boneKeys = boneKeys,
		speed = isnumber(speed) and speed or 3,
		flag = 'upmanip.anim.fadein'
	}

	local identity = ent
	UPar.PushIterator(identity, AnimFadeInIterator, iteratorData, timeout)
end

UPManip.AnimFadeOut = function(ent, boneMapping, speed, timeout)
	if not IsValid(ent) or not isentity(ent) or not ent:GetModel() then 
		return 
	end

	timeout = math.abs(isnumber(timeout) and timeout or 2)
	boneMapping = istable(boneMapping) and boneMapping or emptyTable

	ent:SetupBones()

	local iteratorData = {
		ent = ent,
		boneMapping = boneMapping,
		speed = isnumber(speed) and speed or 3,
		flag = 'upmanip.anim.fadeout'
	}

	local identityFadeIn = ent
	local identityFadeOut = ent

	UPar.PopIterator(identityFadeIn)
	UPar.PushIterator(identityFadeOut, AnimFadeOutIterator, iteratorData, timeout)
end

hook.Add('UParIteratorPop', 'upmanip.iterator.pop', function(identity, curTime, add, reason)
	if IsValid(identity) and isentity(identity) then
		if istable(add) and add.flag == 'upmanip.anim.fadeout' and reason ~= 'MANUAL' then
			ClearManip(add.ent, add.boneMapping) 
		end

		return true
	end
end)

concommand.Add('upmanip_test', function(ply)
	local Eli = ClientsideModel('models/Eli.mdl', RENDERGROUP_OTHER)
	local gman_high = ClientsideModel('models/gman_high.mdl', RENDERGROUP_OTHER)

	local speed = 1
	local timeout = 1
	local boneMapping = {
		['ValveBiped.Bip01_Head1'] = {pos = Vector(10, 0, 0), ang = Angle(20, 0, 0), scale = Vector(2, 1, 1)},
		['ValveBiped.Bip01_L_Calf'] = true,
	}

	local pos1 = ply:GetPos() + 100 * ply:EyeAngles():Forward()
	local pos2 = pos1 + 100 * ply:EyeAngles():Right()

	Eli:SetPos(pos1)
	Eli:SetupBones()

	gman_high:SetPos(pos2)
	gman_high:SetupBones()

	UPManip.AnimFadeIn(Eli, gman_high, boneMapping, speed, timeout)
	timer.Simple(timeout * 0.5, function() 
		UPManip.AnimFadeOut(Eli, boneMapping, speed, timeout) 
	end)
	
	timer.Simple(timeout + 1, function() 
		Eli:Remove()
		gman_high:Remove()
	end)
end)