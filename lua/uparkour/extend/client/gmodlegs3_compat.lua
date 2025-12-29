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
-- 修改 gmodlegs3 以方便控制其运行状态
-- 添加一个 updateFlag 来标记是否需要更新 GmodLegs3
-- ==============================================================
concommand.Add('upext_gmodlegs3_inject', function()
	if not g_Legs then
		print('[UPExt]: can not find g_Legs')
		return
	end

	g_Legs.OriginalUpdate = isfunction(g_Legs.OriginalUpdate) and g_Legs.OriginalUpdate or g_Legs.Update
	g_Legs.Update = function(self, maxseqgroundspeed, ...)
		if self.Sleep then return end
		self:OriginalUpdate(maxseqgroundspeed, ...)
	end

	print('[UPExt]: g_Legs.Update already injected')
end)

concommand.Add('upext_gmodlegs3_recovery', function()
	if not g_Legs then
		print('[UPExt]: can not find g_Legs')
		return
	end

	g_Legs.Update = isfunction(g_Legs.OriginalUpdate) and g_Legs.OriginalUpdate or g_Legs.Update
	print('[UPExt]: g_Legs.Update already recovered')
end)

hook.Add('KeyPress', 'UPExtGmodLegs3Inject', function()
	hook.Remove('KeyPress', 'UPExtGmodLegs3Inject')
	timer.Simple(3, function() RunConsoleCommand('upext_gmodlegs3_inject') end)
end)


-- ==============================================================
-- 拦截 VMLegs.PlayAnim 和 VMLegs.Remove 使用 UPManip 控制方案代替
-- ==============================================================
UPManip.BoneMappings['gmodlegs3tovmlegs'] = {
	['ValveBiped.Bip01_Spine'] = true,
	['ValveBiped.Bip01_Spine1'] = true,

	['ValveBiped.Bip01_L_Thigh'] = true,
	['ValveBiped.Bip01_L_Calf'] = true,
	['ValveBiped.Bip01_L_Foot'] = true,
	['ValveBiped.Bip01_L_Toe0'] = true,
	
	['ValveBiped.Bip01_R_Thigh'] = true,
	['ValveBiped.Bip01_R_Calf'] = true,
	['ValveBiped.Bip01_R_Foot'] = true,
	['ValveBiped.Bip01_R_Toe0'] = true
}

hook.Add('VMLegsPostPlayAnim', 'UPExtGmodLegs3Manip', function(anim)
	if not upext_gmodlegs3_manip:GetBool() then return end
	if IsValid(g_Legs.LegEnt) and IsValid(VMLegs.LegModel) then
		local temp = ClientsideModel('models/breen.mdl', RENDERGROUP_OTHER)
		temp:SetPos(LocalPlayer():GetPos() + -100 * UPar.XYNormal(LocalPlayer():EyeAngles():Forward()))
		temp:SetParent(LocalPlayer())

		if istable(g_Legs.BonesToRemove) then
			for k, v in pairs(g_Legs.BonesToRemove) do
                local boneId = temp:LookupBone(v)
                if not boneId then continue end
				temp:ManipulateBoneScale(boneId, Vector(0,0,0))
            end
		end

		timer.Simple(10, function() temp:Remove() end)
		UPManip.AnimFadeIn(
			temp, 
			LocalPlayer(),
			UPManip.BoneMappings['gmodlegs3tovmlegs'],
			3,
			10
		)
	end
end)

hook.Add('VMLegsRemove', 'UPExtGmodLegs3Manip', function(anim)
	g_Legs.Sleep = false
	if not upext_gmodlegs3_manip:GetBool() then return end
end)

-- ==============================================================
-- 菜单
-- ==============================================================

UPar.SeqHookAdd('UParExtendMenu', 'GmodLegs3Compat', function(panel)
	panel:Help('·························· GmodLegs3 ··························')
	panel:ControlHelp('#upext.gmodlegs3_inject.help')

	panel:CheckBox('#upext.gmodlegs3_compat', 'upext_gmodlegs3_compat')
	panel:ControlHelp('#upext.gmodlegs3_compat.help')

	panel:CheckBox('#upext.gmodlegs3_manip', 'upext_gmodlegs3_manip')
	panel:ControlHelp('#upext.gmodlegs3_manip.help')
	local help2 = panel:ControlHelp('#upext.gmodlegs3_manip.help2')
	help2:SetTextColor(Color(255, 170, 0))

	panel:Button('#upext.gmodlegs3_inject', 'upext_gmodlegs3_inject')
	panel:Button('#upext.gmodlegs3_recovery', 'upext_gmodlegs3_recovery')
end, 1)