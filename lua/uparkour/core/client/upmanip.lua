--[[
	作者:白狼
	2025 12 28
--]]

local zerovec = UPar.zerovec
local zeroang = UPar.zeroang
local diagonalvec = UPar.diagonalvec
local emptyTable = UPar.emptyTable

UPManip = UPManip or {}

local playermodelbonesupper = {
	["ValveBiped.Bip01_Head1"] = true,
}

local function SetBoneAngles(ent, boneId, ang)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	if boneId == -1 then
		ent:SetAngles(ang)
		return true
	end

	local _, boneAngWorld = ent:GetBonePosition(boneId)
	if not boneAngWorld then 
		string.format('[SetBoneAngles]: ent "%s" boneId "%s" no angles', ent, boneId)
		return false
	end

	local boneRotateWorld = Matrix()
	boneRotateWorld:SetAngles(boneAngWorld)

	local rotateManip = Matrix()
	rotateManip:SetAngles(ent:GetManipulateBoneAngles(boneId))

	local rotateAng = Matrix()
	rotateAng:SetAngles(ang)

	local boneRotate = boneRotateWorld * rotateManip:GetTransposed()
	local rotateNewManip = boneRotate:GetTransposed() * rotateAng


	local boneAng = boneRotate:GetAngles()
	local angNewManip = rotateNewManip:GetAngles()
	ent:ManipulateBoneAngles(boneId, angNewManip)

	return angNewManip, boneAng
end

local function SetBonePos(ent, boneId, pos)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新, 并且位移有限 (128)

	if boneId == -1 then
		ent:SetPos(pos)
		return true
	end

	local bonePosWorld = ent:GetBonePosition(boneId)
	if not bonePosWorld then 
		string.format('[SetBonePos]: ent "%s" boneId "%s" no position', ent, boneId)
		return false
	end

	local parentboneId = ent:GetBoneParent(boneId)
	local parentMat = parentboneId == -1 and ent:GetWorldTransformMatrix() or ent:GetBoneMatrix(parentboneId)
	if not parentMat then 
		string.format('[SetBonePos]: ent "%s" boneId "%s" no parent', ent, boneId)
		return false
	end

	local bonePos = ent:WorldToLocal(bonePosWorld) - ent:GetManipulateBonePosition(boneId)
	local posNewManip = ent:WorldToLocal(pos) - bonePos
	ent:ManipulateBonePosition(boneId, posNewManip)

	return posNewManip, bonePos
end

local function SetBonePosition(ent, boneId, pos, ang)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	if boneId == -1 then
		if pos then ent:SetPos(pos) end
		if ang then ent:SetAngles(ang) end
		return true
	end

	local bonePosWorld, boneAngWorld = ent:GetBonePosition(boneId)
	if not bonePosWorld then 
		string.format('[SetBonePosition]: ent "%s" boneId "%s" no position', ent, boneId)
		return false
	end

	local boneAng = nil
	local angNewManip = nil
	if ang then
		local boneRotateWorld = Matrix()
		boneRotateWorld:SetAngles(boneAngWorld)

		local rotateManip = Matrix()
		rotateManip:SetAngles(ent:GetManipulateBoneAngles(boneId))

		local rotateAng = Matrix()
		rotateAng:SetAngles(ang)

		local boneRotate = boneRotateWorld * rotateManip:GetTransposed()
		local rotateNewManip = boneRotate:GetTransposed() * rotateAng


		boneAng = boneRotate:GetAngles()
		angNewManip = rotateNewManip:GetAngles()
		ent:ManipulateBoneAngles(boneId, angNewManip)
	end
	
	local bonePos = nil
	local posNewManip = nil
	if pos then
		local parentboneId = ent:GetBoneParent(boneId)
		local parentMat = parentboneId == -1 and ent:GetWorldTransformMatrix() or ent:GetBoneMatrix(parentboneId)
		if not parentMat then 
			string.format('[SetBonePos]: ent "%s" boneId "%s" no parent', ent, boneId)
			return false
		end

		bonePos = ent:WorldToLocal(bonePosWorld) - ent:GetManipulateBonePosition(boneId)
		posNewManip = ent:WorldToLocal(pos) - bonePos
		ent:ManipulateBonePosition(boneId, posNewManip)
	end

	return posNewManip, angNewManip, bonePos, boneAng
end

local function Clear(ent)
	ent:SetAngles(zeroang)
	ent:SetPos(zerovec)
	for i = 0, ent:GetBoneCount() - 1 do
		ent:ManipulateBoneAngles(i, zeroang)
		ent:ManipulateBonePosition(i, zerovec)
		ent:ManipulateBoneScale(i, diagonalvec)
	end
end

local function UnpackBMData(bmdata)
	-- 返回 骨骼名称, 偏移矩阵

	if istable(bmdata) then 
		local boneName = isstring(bmdata.boneName) and bmdata.boneName or nil
		
		local offsetMatrix = nil
		local offsetAng = bmdata.ang
		local offsetPos = bmdata.pos

		if isangle(offsetAng) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetAngles(offsetAng)
		end

		if isvector(offsetPos) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetTranslation(offsetPos)
		end

		return boneName, offsetMatrix
	elseif isstring(bmdata) then 
		return bmdata, nil
	else
		return nil, nil
	end
end

local function SnapshotWorld(ent)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	local snapshot = {}
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		snapshot[boneId] = {ent:GetBonePosition(boneId)} 
	end
	
	return snapshot
end

local function SnapshotWorld(ent)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	local snapshot = {}
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		snapshot[boneId] = {ent:GetBonePosition(boneId)} 
	end
	
	return snapshot
end

local function SnapshotLocal(ent)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	local snapshot = {}
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		local posWorld, angWorld = ent:GetBonePosition(boneId)
		snapshot[boneId] = {ent:WorldToLocal(posWorld), ent:WorldToLocalAngles(angWorld)} 
	end

	return snapshot
end

local function LerpBoneWorld(t, ent, target, boneMapping, snapshot)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新
	t = math.Clamp(t, 0, 1)

	for boneName, data in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		
		if not boneId then 
			continue
		end

		local bonePos, boneAng = snapshot[boneId]
		if not bonePos or not boneAng then 
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

		local newPos = LerpVector(t, boneMatrix:GetTranslation(), targetMatrix:GetTranslation())
		local newAng = LerpAngle(t, boneMatrix:GetAngles(), targetMatrix:GetAngles())
		SetBonePosition(ent, boneId, newPos, newAng)

		// local newScale = LerpVector(t, boneMatrix:GetScale(), targetMatrix:GetScale())
	end

end

local function LerpBoneLocal(t, ent, target, boneMapping)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

end

local function LerpBoneWorldIterator(dt, curTime, iteratorData)
	local ent = iteratorData.ent
	local target = iteratorData.target
	local boneMapping = iteratorData.boneMapping
	local t = iteratorData.t + dt * iteratorData.speed
	iteratorData.t = t

	ent:SetupBones()
	target:SetupBones()

	LerpBoneWorld(t, ent, target, boneMapping)
end


UPManip.SetBoneAngles = SetBoneAngles
UPManip.SetBonePos = SetBonePos
UPManip.SetBonePosition = SetBonePosition
UPManip.Clear = Clear
UPManip.UnpackBMData = UnpackBMData
UPManip.LerpBoneWorld = LerpBoneWorld
UPManip.LerpBoneLocal = LerpBoneLocal

UPManip.FadeIn = function(ent, target, boneMapping, speed, method, timeout)
	if not IsValid(ent) or not isentity(ent) or not ent:GetModel()
	or not IsValid(target) or not isentity(target) or not target:GetModel() then 
		return 
	end

	method = isstring(method) and method or 'WORLD'
	timeout = isnumber(timeout) and timeout or 2
	boneMapping = istable(boneMapping) and boneMapping or emptyTable

	ent:SetupBones()
	local snapshot = {}
	for boneName, _ in pairs(boneMapping) do
		local boneId = ent:LookupBone(boneName)
		if not boneId then continue end
		snapshot[boneId] = {ent:GetBonePosition(boneId)} 
	end

	local iteratorData = {
		ent = ent,
		target = target,
		boneMapping = boneMapping,
		speed = isnumber(speed) and speed or 3,
		t = 0,
		snapshot = snapshot
	}

	local identity = string.format('upmanip.fadein.%s', ent:EntIndex())
	local iterator = method == 'WORLD' and LerpBoneWorldIterator or LerpBoneLocalIterator
	
	UPar.PushIterator(identity, iterator, iteratorData, timeout)
end

hook.Add('UParIteratorPop', 'upmanip.iterator.pop', function(identity, curTime, add, reason)
	if string.StartWith(identity, 'upmanip.fadein.') 
	or string.StartWith(identity, 'upmanip.fadeout.')
	then
		Clear(add.ent)
		return true
	end
end)

UPManip.FadeOut = function(ent)

end


aaaa = aaaa or ClientsideModel('models/Eli.mdl', RENDERGROUP_OTHER)
bbbb = bbbb or ClientsideModel('models/gman_high.mdl', RENDERGROUP_OTHER)

bbbb:SetPos(Vector(100, 0, 0))

UPManip.FadeIn(aaaa, LocalPlayer(), playermodelbonesupper, 3, 'WORLD', 2)


