--[[
	作者:白狼
	2025 12 29
--]]

local upeff_gmodlegs3_compat = CreateClientConVar('upeff_gmodlegs3_compat', '1', true, false, '')
local upeff_gmodlegs3_manip = CreateClientConVar('upeff_gmodlegs3_manip', '1', true, false, '')

-- ==============================================================
-- 兼容 GmodLegs3 (启动 VMLegs 时 禁用 GmodLegs3)
-- ==============================================================
local function ShouldDisableLegs()
	return not upeff_gmodlegs3_manip:GetBool() and VMLegs and VMLegs:IsActive()
end

local function GmodLegs3CompatChange(name, old, new)
	local HOOK_IDENTITY_COMPAT = 'upar.gmodleg3.compat'
	if new == '1' then
		print('[UPar] GmodLegs3Compat enabled')
		hook.Add('ShouldDisableLegs', HOOK_IDENTITY_COMPAT, ShouldDisableLegs)
	else
		print('[UPar] GmodLegs3Compat disabled')
		hook.Remove('ShouldDisableLegs', HOOK_IDENTITY_COMPAT)
	end
end
cvars.AddChangeCallback('upeff_gmodlegs3_compat', GmodLegs3CompatChange, 'default')
GmodLegs3CompatChange('upeff_gmodlegs3_compat', '', upeff_gmodlegs3_compat:GetBool() and '1' or '0')

-- ==============================================================
-- gmodlegs3 控制
-- ==============================================================



-- ==============================================================
-- 菜单
-- ==============================================================

UPar.SeqHookAdd('UParExtendMenu', 'GmodLegs3Compat', function(panel)
	panel:CheckBox('#upgui.gmodlegs3_compat', 'upeff_gmodlegs3_compat')
	panel:ControlHelp('#upgui.gmodlegs3_compat.help')

	panel:CheckBox('#up.gmodlegs3_manip', 'upeff_gmodlegs3_manip')
	panel:ControlHelp('#upgui.gmodlegs3_manip.help')
end, 2)