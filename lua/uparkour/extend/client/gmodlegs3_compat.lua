--[[
	作者:白狼
	2025 12 29
--]]

local upext_gmodlegs3_compat = CreateClientConVar('upext_gmodlegs3_compat', '1', true, false, '')

-- ==============================================================
-- 兼容 GmodLegs3 (启动 VMLegs 时 禁用 GmodLegs3)
-- ==============================================================
local function ShouldDisableLegs()
	return VMLegs and VMLegs:IsActive()
end

local function GmodLegs3CompatChange(name, old, new)
	local HOOK_IDENTITY_COMPAT = 'upar.gmodleg3.compat'
	if new == '1' then
		print('[UPExt]: GmodLegs3Compat enabled')
		hook.Add('ShouldDisableLegs', HOOK_IDENTITY_COMPAT, ShouldDisableLegs)
	else
		print('[UPExt]: GmodLegs3Compat disabled')
		hook.Remove('ShouldDisableLegs', HOOK_IDENTITY_COMPAT)
	end
end
cvars.AddChangeCallback('upext_gmodlegs3_compat', GmodLegs3CompatChange, 'default')
GmodLegs3CompatChange(nil, nil, upext_gmodlegs3_compat:GetBool() and '1' or '0')


-- ==============================================================
-- UPManip 控制 玩家模型
-- ==============================================================
local upext_gmodlegs3_manip = CreateClientConVar('upext_gmodlegs3_manip', '1', true, false, '')

UPManip.BoneMappingCollect['VMLegs'] = {
	['ValveBiped.Bip01_Pelvis'] = true,
	['ValveBiped.Bip01_Spine'] = true,
	['ValveBiped.Bip01_Spine1'] = true,
	['ValveBiped.Bip01_Spine2'] = true,

	['ValveBiped.Bip01_L_Thigh'] = true,
	['ValveBiped.Bip01_L_Calf'] = true,
	['ValveBiped.Bip01_L_Foot'] = true,
	['ValveBiped.Bip01_L_Toe0'] = true,
	
	['ValveBiped.Bip01_R_Thigh'] = true,
	['ValveBiped.Bip01_R_Calf'] = true,
	['ValveBiped.Bip01_R_Foot'] = true,
	['ValveBiped.Bip01_R_Toe0'] = true
}

UPManip.BoneKeysCollect['VMLegs'] = {
	'ValveBiped.Bip01_Pelvis',
	'ValveBiped.Bip01_Spine',
	'ValveBiped.Bip01_Spine1',
	'ValveBiped.Bip01_Spine2',
	'ValveBiped.Bip01_L_Thigh',
	'ValveBiped.Bip01_L_Calf',
	'ValveBiped.Bip01_L_Foot',
	'ValveBiped.Bip01_L_Toe0',
	'ValveBiped.Bip01_R_Thigh',
	'ValveBiped.Bip01_R_Calf',
	'ValveBiped.Bip01_R_Foot',
	'ValveBiped.Bip01_R_Toe0'
}

g_GmodLeg3Fake = g_GmodLeg3Fake or nil
g_VMLegsParentFake = g_VMLegsParentFake or nil

local function InitFaker()
	local ent = g_GmodLeg3Fake
	if not IsValid(ent) or not isentity(ent) then 
		ent = ClientsideModel(LocalPlayer():GetModel(), RENDERGROUP_OTHER)
	else
		ent:SetModel(LocalPlayer():GetModel())
	end

	ent:SetParent(nil)
    ent:SetNoDraw(false)

	for k, v in pairs(LocalPlayer():GetBodyGroups()) do
		local current = LocalPlayer():GetBodygroup(v.id)
		ent:SetBodygroup(v.id,  current)
	end

	for k, v in ipairs(LocalPlayer():GetMaterials()) do
		ent:SetSubMaterial(k - 1, LocalPlayer():GetSubMaterial(k - 1))
	end

	ent:SetSkin(LocalPlayer():GetSkin())
	ent:SetMaterial(LocalPlayer():GetMaterial())
	ent:SetColor(LocalPlayer():GetColor())
	ent.GetPlayerColor = function()
		return LocalPlayer():GetPlayerColor()
	end

	for i = 0, ent:GetBoneCount() - 1 do
		local boneName = ent:GetBoneName(i)
		if not UPManip.BoneMappingCollect['VMLegs'][boneName] then
			ent:ManipulateBoneScale(i, Vector(0, 0, 0))
		end
	end

	ent:SetRenderOrigin(nil)
	ent:SetRenderAngles(nil)
	ent:SetPos(Vector(0, 0, 0))
	ent:SetAngles(Angle(0, 0, 0))

	g_GmodLeg3Fake = ent

	local ent2 = g_VMLegsParentFake
	if not IsValid(ent2) or not isentity(ent2) then 
		ent2 = ClientsideModel(VMLegs.LegParent:GetModel(), RENDERGROUP_OTHER)
	else
		ent2:SetModel(VMLegs.LegParent:GetModel())
	end

	ent2:SetParent(nil)
    ent2:SetNoDraw(false)

	local VMLegsGrandpa = LocalPlayer() -- 妈的笑死我了
	if IsValid(VMLegsGrandpa) then
		VMLegs.LegParent:SetupBones()
		VMLegsGrandpa:SetupBones()
		ent2:SetPos(VMLegsGrandpa:WorldToLocal(VMLegs.LegParent:GetPos()))
		ent2:SetAngles(VMLegsGrandpa:WorldToLocalAngles(VMLegs.LegParent:GetAngles()))
		
		print(VMLegsGrandpa:WorldToLocal(VMLegs.LegParent:GetPos()))
		print(VMLegsGrandpa:WorldToLocalAngles(VMLegs.LegParent:GetAngles()))
	
	else
		ent2:SetPos(Vector(0, 0, 0))
		ent2:SetAngles(Angle(0, 0, 0))
	end
	
	ent2:ResetSequenceInfo()
	ent2:SetPlaybackRate(1)
	ent2:ResetSequence(VMLegs.SeqID)

	g_VMLegsParentFake = ent2

	return ent, ent2
end

local identity = 'UPExtGmodLegs3Manip'
local t = 0
local speed = 10
local target = nil
local lastTarget = nil
local snapshot = {}
local function Controller(dt, curtime, data)
	local ent = g_GmodLeg3Fake
	local ent2 = g_VMLegsParentFake

	if not IsValid(ent) then 
		print('[UPExt]: GmodLegs3Compat: PlayerModel is not valid')
		return true
	end

	ent2:SetCycle(VMLegs.Cycle)

	t = math.Clamp(t + dt * speed, 0, 1)

	if lastTarget ~= target then
		t = 0
	end

	if IsValid(target) then
		target:SetupBones()
		ent:SetupBones()
		UPManip.LerpBoneWorld(ent, t, snapshot, target, 
		UPManip.BoneMappingCollect['VMLegs'], 
		UPManip.BoneKeysCollect['VMLegs'])
	end

	ent:SetRenderOrigin(nil)
	ent:SetRenderAngles(nil)
	ent:DrawModel()

	lastTarget = target
end

local function StartManip()
	if not upext_gmodlegs3_manip:GetBool() then return end
	if g_Legs and IsValid(g_Legs.LegEnt) and IsValid(VMLegs.LegParent) and IsValid(VMLegs.LegModel) then
		InitFaker()

		VMLegs.LegModel:SetNoDraw(true)
		target = g_VMLegsParentFake
		lastTarget = nil
		snapshot = UPManip.Snapshot(g_Legs.LegEnt, UPManip.BoneMappingCollect['VMLegs'])
		UPar.PushRenderIterator(identity, Controller, nil, 10)
	end
end

local function ClearManip()
	g_VMLegsParentFake:SetupBones()
	snapshot = UPManip.Snapshot(g_VMLegsParentFake, UPManip.BoneMappingCollect['VMLegs'])
	target = g_Legs.LegEnt
end

hook.Add('VMLegsPostPlayAnim', 'UPExtGmodLegs3Manip', StartManip)
hook.Add('VMLegsPreRemove', 'UPExtGmodLegs3Manip', ClearManip)

hook.Add('UParIteratorPop', 'upunch.out', function(identity, endtime, addition, reason)
	print('UParIteratorPop', identity, reason)
end)

hook.Add('UParRenderIteratorPop', 'upunch.out', function(identity, endtime, addition, reason)
	print('UParRenderIteratorPop', identity, reason)
end)



-- ==============================================================
-- 菜单
-- ==============================================================

UPar.SeqHookAdd('UParExtendMenu', 'GmodLegs3Compat', function(panel)
	panel:Help('·························· GmodLegs3 ··························')
	panel:CheckBox('#upext.gmodlegs3_compat', 'upext_gmodlegs3_compat')
	panel:ControlHelp('#upext.gmodlegs3_compat.help')

	panel:CheckBox('#upext.gmodlegs3_manip', 'upext_gmodlegs3_manip')
	panel:ControlHelp('#upext.gmodlegs3_manip.help')
	local help2 = panel:ControlHelp('#upext.gmodlegs3_manip.help2')
	help2:SetTextColor(Color(255, 170, 0))

end, 1)