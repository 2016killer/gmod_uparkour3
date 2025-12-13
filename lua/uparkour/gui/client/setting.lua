--[[
	作者:白狼
	2025 12 10
--]]


local function CreateMenu(panel)
	panel:Clear()

	local loadclButton = panel:Button('#upgui.loadcllua')
	loadclButton.DoClick = function()
		UPar.LoadAllLuaFiles()
	end
	panel:ControlHelp('#upgui.loadcllua.help')

	if LocalPlayer():IsSuperAdmin() then
		local loadsvButton = panel:Button('#upgui.loadsvlua')
		loadsvButton.DoClick = function()
			UPar.SendLoadAllLuaFiles()
		end
	end

	panel:CheckBox('#up.gmodlegs3_compat', 'up_gmodlegs3_compat')
	panel:ControlHelp('#up.gmodlegs3_compat.help')

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)
end

hook.Add('PopulateToolMenu', 'upar.menu.setting', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour', 
		'upar.menu.setting', 
		'#upgui.menu.setting', '', '', 
		CreateMenu
	)
end)