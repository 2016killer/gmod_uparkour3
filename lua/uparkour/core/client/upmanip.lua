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

local function SnapshotManip(ent, boneMapping)
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

local function LerpBoneManip(t, ent, snapshot)
	if istable(snapshot) then
		for boneId, transformArray in pairs(snapshot) do
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

local function LerpBoneWorld(t, ent, target, boneMapping, boneKeys)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

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
		// local newScale = LerpVector(t, boneMat:GetScale(), targetMatrix:GetScale())

		// ent:ManipulateBoneScale(boneId, newScale)
		SetBonePosition(ent, boneId, newPos, newAng)
	end
end

local function ClearManip(ent, snapshot)
	if not isentity(ent) or not IsValid(ent) then
		print(string.format('[UPManip.ClearManip]: invaild ent "%s"', ent))
		return
	end

	local snapshotSafe = nil
	if istable(snapshot) then
		snapshotSafe = {}
		for boneId, transformArray in pairs(snapshot) do
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

UPManip.SetBonePosition = SetBonePosition
UPManip.ClearManip = ClearManip
UPManip.UnpackBMData = UnpackBMData
UPManip.LerpBoneWorld = LerpBoneWorld
UPManip.SnapshotManip = SnapshotManip
UPManip.GetBoneMappingKeysSorted = GetBoneMappingKeysSorted
UPManip.GetBonesFamilyLevel = GetBonesFamilyLevel
UPManip.BoneMappings = UPManip.BoneMappings or {}
UPManip.LerpBoneManip = LerpBoneManip

UPManip.FADE_SUB_IDENTITY = 'upmanip.anim.fade'

UPManip.AnimFadeIterator = function(dt, curTime, additive)
	local boneMapping = additive.boneMapping
	local boneKeys = additive.boneKeys
	local speed = additive.speed
	local t = additive.t
	local ent = additive.ent
	local target = additive.target

	speed = math.max(math.abs(speed), 0.01)
	t = math.Clamp((t or 0) + dt * speed, 0, 1) 

	additive.t = t

	if not isentity(ent) or not IsValid(ent) then 
		print(string.format('[UPManip.AnimFadeIterator]: ent "%s" is not valid', ent))
		return true, t
	end

	if istable(target) then 
		LerpBoneManip(t, ent, target)
	elseif isentity(target) and IsValid(target) then
		ent:SetupBones()
		target:SetupBones()
		LerpBoneWorld(t, ent, target, boneMapping, boneKeys)
	else
		local snapshot = additive.snapshot
		LerpBoneManip(t, ent, snapshot)
		
		return t >= 1, t
	end

	return nil, t
end

UPManip.GetAnimFadeData = function(ent, target, boneMapping, speed)
	if not isentity(ent) or not IsValid(ent) then 
		print(string.format('[UPManip.GetAnimFadeData]: ent "%s" is not valid or not entity', ent))
		return nil
	end

	if not istable(target) and (not isentity(target) or not IsValid(target)) then
		print(string.format('[UPManip.GetAnimFadeData]: target "%s" is not valid or not entity', target))
		return nil
	end

	boneMapping = istable(boneMapping) and boneMapping or emptyTable

	ent:SetupBones()
	local snapshot = SnapshotManip(ent, boneMapping)
	local boneKeys = GetBoneMappingKeysSorted(ent, boneMapping, true)
	if not boneKeys then 
		return nil 
	end

	speed = isnumber(speed) and speed or 3

	return {
		ent = ent,
		target = target,
		boneMapping = boneMapping,
		speed = speed,

		boneKeys = boneKeys,
		snapshot = snapshot,
		sudId = UPManip.FADE_SUB_IDENTITY
	}
end

UPManip.GetEntAnimFadeIdentity = function(ent)
	assert(isentity(ent) and IsValid(ent), 'ent is not valid or not entity')
	return ent
end

UPManip.IsEntAnimFade = function(ent)
	local identity = UPManip.GetEntAnimFadeIdentity(ent)
	local iter = UPar.GetPVMDIterator(identity)
	return !!iter and iter.add.subId == UPManip.FADE_SUB_IDENTITY
end

function UPManip:AnimFadeIn(ent, target, boneMapping, speed, timeout)
	speed = isnumber(speed) and speed or 3
	timeout = isnumber(timeout) and timeout or 2

	local data = self.GetAnimFadeData(ent, target, boneMapping, speed)
	if not data then 
		return false 
	end

	local identity = self.GetEntAnimFadeIdentity(ent)
	local iter = self.AnimFadeIterator
	
	return UPar.PushPVMDIterator(identity, iter, data, timeout)
end

function UPManip:AnimFadeOut(ent, snapshot, speed, timeout)
	-- 必须先淡入, 否则无效
	speed = isnumber(speed) and speed or 3
	timeout = isnumber(timeout) and timeout or 2

	local identity = self.GetEntAnimFadeIdentity(ent)

	local succ = UPar.SetPVMDIterEndTime(identity, CurTime() + timeout)
	succ = succ and UPar.MergePVMDIterAddiKV(identity, {
		t = 0,
		speed = speed,
		target = false,
		snapshot = snapshot,
	})

	return succ
end

concommand.Add('upmanip_test', function(ply)
	local Eli = ClientsideModel('models/Eli.mdl', RENDERGROUP_OTHER)
	local gman_high = ClientsideModel('models/gman_high.mdl', RENDERGROUP_OTHER)

	local speed = 1
	local timeout = 10
	local boneMapping = {
		['ValveBiped.Bip01_Head1'] = {pos = Vector(10, 0, 0), ang = Angle(0, 90, 0), scale = Vector(2, 1, 1)},
		['ValveBiped.Bip01_L_Calf'] = true,
	}

	local pos1 = ply:GetPos() + 100 * UPar.XYNormal(ply:EyeAngles():Forward())
	local pos2 = pos1 + 100 * UPar.XYNormal(ply:EyeAngles():Right())

	Eli:SetPos(pos1)
	Eli:SetupBones()
	Eli:ManipulateBonePosition(Eli:LookupBone('ValveBiped.Bip01_Head1'), Vector(10, 10, 10))
	Eli:ManipulateBoneAngles(Eli:LookupBone('ValveBiped.Bip01_Head1'), Angle(10, 10, 10))
	Eli:ManipulateBoneScale(Eli:LookupBone('ValveBiped.Bip01_Head1'), Vector(2, 1, 1))

	gman_high:SetupBones()
	gman_high:ResetSequenceInfo()
	gman_high:SetPlaybackRate(1)
	gman_high:ResetSequence(gman_high:LookupSequence('crouch_reload_pistol'))
	gman_high:SetPos(pos2)

	UPar.PushIterator('upmanip_test', function(dt)
		if not IsValid(gman_high) then return true end
		local cycle = (gman_high:GetCycle() + dt) % 1
		gman_high:SetCycle(cycle)
	end, nil, timeout)

	UPManip:AnimFadeIn(Eli, gman_high, boneMapping, speed, timeout)
	timer.Simple(timeout * 0.5, function() 
		UPManip:AnimFadeOut(Eli, nil, speed, timeout) 
	end)
	
	timer.Simple(timeout + 1, function() 
		Eli:Remove()
		gman_high:Remove()
	end)
end)