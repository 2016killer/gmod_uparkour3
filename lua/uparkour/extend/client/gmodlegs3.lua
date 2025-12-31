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

g_GmodLeg3Faker = g_GmodLeg3Faker or nil

local function InitGmodLeg3Faker()
	if not g_Legs then
		print('[UPExt]: GmodLegs3 not install')
		return false
	end

	if not g_GmodLeg3Faker then
		g_GmodLeg3Faker = UPar.DeepClone(g_Legs)
		g_GmodLeg3Faker.LegEnt = nil	
	end

	g_GmodLeg3Faker:SetUP()

	return true
end

local function GmodLeg3FakeRender(self)
	// // local GmodLeg3Fake = self
	// local VMLegsParentFake = g_VMLegsParentFake 

	// -- 同步 VMLegs 动画
	// local cycle = VMLegs.Cycle
	// if isnumber(cycle) then VMLegsParentFake:SetCycle(cycle) end

	// // if IsFirstTimePredicted() then
	// self.t = math.Clamp((self.t or 0) + FrameTime() * (self.speed or 1), 0, 1)
	// // else
	// // 	self.t = self.t or 0
	// // end

	// if self.lastTarget ~= self.target then
	// 	self.t = 0
	// end

	// if IsValid(self.target) then
	// 	self.target:SetupBones()
	// 	self:SetupBones()
	// 	UPManip.LerpBoneWorld(self, self.t, self.snapshot or emptyTable, self.target, 
	// 	UPManip.BoneMappingCollect['VMLegs'], 
	// 	UPManip.BoneKeysCollect['VMLegs'])
	// end

	// // local matrix = Matrix()
	// // matrix:SetTranslation(Vector(999, 999, 999))
	// // matrix:SetAngles(Angle(100, 20, 30))
	// // cam.PushModelMatrix(matrix, true)
	// // 	self:DrawModel()
	// // cam.PopModelMatrix()

	// cam.Start3D(EyePos(), EyeAngles())
	// 	self:SetRenderOrigin(g_Legs.RenderPos)
	// 	self:SetRenderOrigin(g_Legs.RenderAngle)
	// 	self:SetupBones()
	// 	self:DrawModel()
	// 	self:SetRenderOrigin(nil)
	// 	self:SetRenderAngles(nil)
	// cam.End3D()


	// self.lastTarget = self.target
end

local function StartManip()
	// if not Condition() then
	// 	return false
	// end

	// local succ = InitGmodLeg3Faker()

	// if not succ then
	// 	print('[UPExt]: GmodLegs3Manip: InitFaker failed!')
	// 	return false
	// end

	// VMLegs.LegModel:SetNoDraw(true)
	// g_Legs.LegEnt:SetupBones()

	// GmodLeg3Fake.snapshot = UPManip.Snapshot(g_Legs.LegEnt, UPManip.BoneMappingCollect['VMLegs'])
	// GmodLeg3Fake.target = g_VMLegsParentFake
	// GmodLeg3Fake.lastTarget = nil
	// GmodLeg3Fake.RenderOverride = GmodLeg3FakeRender
end

local function ClearManip()
	// g_VMLegsParentFake:SetupBones()
	// g_GmodLeg3Fake.snapshot = UPManip.Snapshot(g_VMLegsParentFake, UPManip.BoneMappingCollect['VMLegs'])
	// g_GmodLeg3Fake.target = g_Legs.LegEnt
end

hook.Add('VMLegsPostPlayAnim', 'UPExtGmodLegs3Manip', StartManip)
hook.Add('VMLegsPreRemove', 'UPExtGmodLegs3Manip', ClearManip)
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