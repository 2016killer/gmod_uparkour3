--[[
	作者:白狼
	2025 12 29
--]]

local upext_gmodlegs3_compat = CreateClientConVar('upext_gmodlegs3_compat', '1', true, false, '')
local upext_gmodlegs3_manip = CreateClientConVar('upext_gmodlegs3_manip', '1', true, false, '')

-- ==============================================================
-- 兼容 GmodLegs3 (启动 VMLegs 时 禁用 GmodLegs3)
-- ==============================================================
local function ShouldDisableLegs()
	return not upext_gmodlegs3_manip:GetBool() and VMLegs and VMLegs:IsActive()
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
-- 拦截 VMLegs.PlayAnim 和 VMLegs.Remove 使用 UPManip 控制方案代替
-- ==============================================================
UPManip.BoneMappings['gmodlegs3tovmlegs'] = {
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

local function tempIter(dt, curtime, data)
	local ent = data.ent
	local tar = data.target
	local popFlag, t = UPManip.AnimFadeIterator(dt, curtime, data)

	if popFlag then
		ent:SetPos(Vector())
		ent:SetAngles(Angle())

		g_Legs.RenderPosOff = nil
	elseif isentity(tar) and IsValid(tar) then
		ent:SetPos(tar:GetPos())
		ent:SetAngles(tar:GetAngles())
		
		g_Legs.RenderPosOff = LerpVector(t, UPar.zerovec, tar:GetPos() - g_Legs.RenderPos)
	end

	return popFlag
end

hook.Add('VMLegsPostPlayAnim', 'UPExtGmodLegs3Manip', function(anim)
	if not upext_gmodlegs3_manip:GetBool() then return end
	if IsValid(g_Legs.LegEnt) and IsValid(VMLegs.LegModel) then
		local timeout = 10
		local speed = 1

		local fadeInData = UPManip.GetAnimFadeData(
			g_Legs.LegEnt, 
			VMLegs.LegModel, 
			UPManip.BoneMappings['gmodlegs3tovmlegs'], 
			speed
		)
		
		if not fadeInData then 
			return 
		end

		VMLegs.LegModel:SetNoDraw(true)
		g_Legs.Sleep = true

		local identity = UPManip.GetEntAnimFadeIdentity(g_Legs.LegEnt)
		UPar.PushPVMDIterator(identity, tempIter, fadeInData, timeout)
	end
end)


hook.Add('UParIteratorPop', 'upunch.out', function(identity, endtime, addition, reason)
	print('UParIteratorPop', identity, reason)
end)

hook.Add('UParPVMDIteratorPop', 'upunch.out', function(identity, endtime, addition, reason)
	print('UParPVMDIteratorPop', identity, reason)
end)

hook.Add('VMLegsPreRemove', 'UPExtGmodLegs3Manip', function(anim)
	g_Legs.Sleep = false
	if not upext_gmodlegs3_manip:GetBool() then return end
	local speed = 1
	local timeout = 10
	local succ = UPManip:AnimFadeOut(g_Legs.LegEnt, nil, speed, timeout)
	print('UPExtGmodLegs3Manip', succ)
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