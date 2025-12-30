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

	if not isentity(ent) or not IsValid(ent) then
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
	if not isentity(ent) or not IsValid(ent) or not ent:GetModel() then
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

local function LerpBoneWorld(ent, t, snapshot, target, boneMapping, boneKeys)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	for i, boneName in pairs(boneKeys) do
		local data = boneMapping[boneName]
		local boneId = ent:LookupBone(boneName)
		
		if not boneId or not snapshot[boneName] then 
			continue
		end

		local curPos, curAng, curScale = unpack(snapshot[boneName])

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

		local newPos = LerpVector(t, curPos, targetMatrix:GetTranslation())
		local newAng = LerpAngle(t, curAng, targetMatrix:GetAngles())
		local newScale = LerpVector(t, curScale, targetMatrix:GetScale())

		ent:ManipulateBoneScale(boneId, newScale)
		SetBonePosition(ent, boneId, newPos, newAng)
	end
end

UPManip.SetBonePosition = SetBonePosition
UPManip.UnpackBMData = UnpackBMData
UPManip.LerpBoneWorld = LerpBoneWorld
UPManip.GetBoneMappingKeysSorted = GetBoneMappingKeysSorted
UPManip.GetBonesFamilyLevel = GetBonesFamilyLevel
UPManip.BoneMappingCollect = UPManip.BoneMappingCollect or {}
UPManip.BoneKeysCollect = UPManip.BoneKeysCollect or {}

UPManip.ClearManip = function(ent, snapshotManip)
	if not isentity(ent) or not IsValid(ent) then
		print(string.format('[UPManip.ClearManip]: invaild ent "%s"', ent))
		return
	end

	local snapshotSafe = nil
	if istable(snapshotManip) then
		snapshotSafe = {}
		for boneId, transformArray in pairs(snapshotManip) do
			if not isnumber(boneId) or not istable(transformArray) then continue end
			local tarManipPos, tarManipAng, tarManipScale = unpack(transformArray)
			snapshotSafe[boneId] = {
				isvector(tarManipPos) and tarManipPos or zerovec,
				isangle(tarManipAng) and tarManipAng or zeroang,
				isvector(tarManipScale) and tarManipScale or diagonalvec
			}
		end
	end

	LerpBoneManip(1, ent, snapshotSafe)
end

UPManip.LerpBoneManip = function(t, ent, snapshotManip)
	if istable(snapshotManip) then
		for boneId, transformArray in pairs(snapshotManip) do
			local curManipPos = ent:GetManipulateBonePosition(boneId)
			local curManipAng = ent:GetManipulateBoneAngles(boneId)
			local curManipScale = ent:GetManipulateBoneScale(boneId)

			local tarManipPos, tarManipAng, tarManipScale = unpack(transformArray)

			ent:ManipulateBonePosition(boneId, LerpVector(t, curManipPos, tarManipPos))
			ent:ManipulateBoneAngles(boneId, LerpAngle(t, curManipAng, tarManipAng))
			ent:ManipulateBoneScale(boneId, LerpVector(t, curManipScale, tarManipScale))
		end
	else
		for i = 0, ent:GetBoneCount() - 1 do
			local curManipPos = ent:GetManipulateBonePosition(i)
			local curManipAng = ent:GetManipulateBoneAngles(i)
			local curManipScale = ent:GetManipulateBoneScale(i)

			ent:ManipulateBoneAngles(i, LerpAngle(t, curManipAng, zeroang))
			ent:ManipulateBonePosition(i, LerpVector(t, curManipPos, zerovec))
			ent:ManipulateBoneScale(i, LerpVector(t, curManipScale, diagonalvec))
		end
	end
end

UPManip.SnapshotManip = function(ent, boneMapping)
	local snapshot = {}
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		snapshot[boneId] = {
			ent:GetManipulateBonePosition(boneId),
			ent:GetManipulateBoneAngles(boneId),
			ent:GetManipulateBoneScale(boneId),
		}
	end
	
	return snapshot
end

UPManip.Snapshot = function(ent, boneMapping)
	local snapshot = {}
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		local boneMat = ent:GetBoneMatrix(boneId)
		if not boneMat then continue end
		snapshot[boneName] = {
			boneMat:GetTranslation(),
			boneMat:GetAngles(),
			boneMat:GetScale(),
		}
	end
	
	return snapshot
end