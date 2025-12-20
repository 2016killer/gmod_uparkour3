--[[
	作者:白狼
	2025 12 10
--]]

local function CreateMenu(panel)
	panel.RefreshNode = function(self)
		self:Clear()

		local refreshButton = panel:Button('#upgui.refresh', '')
		refreshButton.DoClick = function()
			panel:RefreshNode()
		end

		panel:Help('')
		panel:ControlHelp('#upgui.menu.keybinder.help')

		panel:Help('=========================')

		local ActionSet = UPar.GetAllActions()
		local keys = {}
		for k, v in pairs(ActionSet) do table.insert(keys, k) end
		table.sort(keys)

		for i, k in ipairs(keys) do
			local v = ActionSet[k]
			if not UPar.isupaction(v) then
				ErrorNoHaltWithStack(string.format('Invalid action "%s" named "%s" (not upaction)', action, k))
				continue
			end

			if v.Invisible then 
				continue 
			end

			if v:GetKeybind() == nil then
				continue
			end

			local label = isstring(v.label) and v.label or k

			local keybinder = vgui.Create('UParKeyBinder')
			keybinder:SetConVar(v.CV_Keybind:GetName())

			self:Help(label)
			self:AddItem(keybinder)
		end

		panel:Help('==========Version==========')
		panel:ControlHelp(UPar.Version)
	end

	panel:RefreshNode()

	UPar.GUI_KeyBinder = panel

	hook.Add('UParRegisterAction', 'upar.update.keybinder', function(actName, action)
		timer.Create('upar.update.keybinder', 0.5, 1, function()
			if not IsValid(panel) then
				hook.Remove('UParRegisterAction', 'upar.update.keybinder')
				timer.Remove('upar.update.keybinder')
				return 
			end
			panel:RefreshNode()
		end)
	end)
end


hook.Add('PopulateToolMenu', 'upar.menu.keybinder', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour', 
		'upar.menu.keybinder', 
		'#upgui.menu.keybinder', '', '', 
		CreateMenu
	)
end)
