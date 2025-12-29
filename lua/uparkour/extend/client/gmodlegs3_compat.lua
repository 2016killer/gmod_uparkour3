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

-- ==============================================================
-- 拦截 VMLegs.PlayAnim 和 VMLegs.Remove 使用 UPManip 控制方案代替
-- ==============================================================
hook.Add('VMLegsPostPlayAnim', 'UPExtGmodLegs3Manip', function(anim)
	print('play', anim)
end)

hook.Add('VMLegsRemove', 'UPExtGmodLegs3Manip', function(anim)
	print('remove', anim)
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