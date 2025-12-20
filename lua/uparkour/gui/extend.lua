--[[
	作者:白狼
	2025 12 10
--]]


local function CreateMenu(panel)
	panel:Clear()

	UPar.SeqHookRunAllSafe('UParExtendMenu', panel)

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