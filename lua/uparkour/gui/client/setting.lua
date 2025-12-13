--[[
	作者:白狼
	2025 12 10
--]]


local function CreateMenu(panel)
	panel:Clear()

	local button = panel:Button('#upgui.menu.loadluafile')
	button.DoClick = function()
		UPar.LoadLuaFiles('class')
		UPar.LoadLuaFiles('core')
		UPar.LoadLuaFiles('actions')
		UPar.LoadLuaFiles('effects')
		UPar.LoadLuaFiles('effectseasy')
		UPar.LoadLuaFiles('expansion')
		UPar.LoadLuaFiles('gui')
		UPar.LoadLuaFiles('version_compat')
	end

	panel:CheckBox('#up.gmodlegs3_compat', 'up_gmodlegs3_compat')
	panel:ControlHelp('#up.gmodlegs3_compat.help')

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)
end

hook.Add('PopulateToolMenu', 'upar.menu.cl_setting', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour', 
		'upar.menu.cl_setting', 
		'#upgui.menu.cl_setting', '', '', 
		CreateMenu
	)
end)