--[[
	作者:白狼
	2025 12 13
--]]



local function CreateMenu(panel)
	panel:Clear()

	local isAdmin = LocalPlayer():IsAdmin()
	local actionManager = vgui.Create('UParEasyTree')
	actionManager:SetSize(200, 400)
	actionManager.OnDoubleClick = function(self, selNode)
		local action = UPar.GetAction(selNode.actName)
		local actionEditor = vgui.Create('UParActionEditor')
		actionEditor:Init2(action)
	end

	actionManager.RefreshNode = function(self)
		actionManager:Clear()

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

			local label = isstring(v.label) and v.label or k
			local icon = isstring(v.icon) and v.icon or 'icon32/tool.png'
			
			local node = self:AddNode(label, icon)
			node.actName = v.Name

			if not isAdmin then 
				continue 
			end

			if v:GetDisabled() ~= nil then
				local disableButton = vgui.Create('DButton', node)
				disableButton:SetSize(20, 18)
				disableButton:Dock(RIGHT)
				
				disableButton:SetText('')
				disableButton:SetIcon(v:GetDisabled() and 'icon16/delete.png' or 'icon16/accept.png')
				
				disableButton.DoClick = function()
					local newValue = not v:GetDisabled()
					v:SetDisabled(newValue)
					disableButton:SetIcon(newValue and 'icon16/delete.png' or 'icon16/accept.png')
				end
			end


			if v:GetPredictionMode() ~= nil then
				local predictionModeButton = vgui.Create('DButton', node)
				predictionModeButton:SetSize(20, 18)
				predictionModeButton:Dock(RIGHT)
				
				predictionModeButton:SetText('')
				predictionModeButton:SetIcon(v:GetPredictionMode() and 'upgui/client.jpg' or 'upgui/server.jpg')
				
				predictionModeButton.DoClick = function()
					local newValue = not v:GetPredictionMode()
					v:SetPredictionMode(newValue)
					predictionModeButton:SetIcon(newValue and 'upgui/client.jpg' or 'upgui/server.jpg')
				end
			end

		end
	end

	actionManager:RefreshNode()
	panel:AddItem(actionManager)

	local refreshButton = panel:Button('#upgui.refresh', '')
	refreshButton.DoClick = function()
		actionManager:RefreshNode()
	end

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)

	UPar.GUI_ActionManager = actionManager

	hook.Add('UParRegisterAction', 'upar.update.actionmanager', function(actName, action)
		timer.Create('upar.update.actionmanager', 0.5, 1, function()
			if not IsValid(panel) then
				hook.Remove('UParRegisterAction', 'upar.update.actionmanager')
				timer.Remove('upar.update.actionmanager')
				return 
			end

			actionManager:RefreshNode()
		end)
	end)
end

hook.Add('PopulateToolMenu', 'upar.menu.actionmanager', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour', 
		'upar.menu.actionmanager', 
		'#upgui.menu.actionmanager', '', '', 
		CreateMenu
	)
end)
