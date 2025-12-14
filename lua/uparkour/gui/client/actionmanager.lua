--[[
	作者:白狼
	2025 12 13
--]]

local function CreateActionEditor(actName)
	local action = UPar.GetAction(actName)
	local actionLabel = isstring(action.label) and action.label or actName

	if not istable(action) then 
		return 
	end

	local guiCacheKey = 'actionEditor_' .. actName
	local locationCacheKey = 'actionEditor_Location'

	local OldActionEditor = UPar.LRUGet(guiCacheKey)
	local location = UPar.LRUGet(locationCacheKey) or {}
	
	if IsValid(OldActionEditor) then 
		OldActionEditor:Remove() 
	end

	local w, h, divWidth = unpack(location)

	w = isnumber(w) and w or 600
	h = isnumber(h) and h or 400
	divWidth = isnumber(divWidth) and divWidth or 200

	local actionEditor = vgui.Create('UParActionEditor')
	actionEditor:Init2(action)
	actionEditor:SetSize(w, h)
	actionEditor:SetPos((ScrW() - w) / 2, (ScrH() - h) / 2)
	actionEditor:SetIcon(isstring(action.icon) and action.icon or 'icon32/tool.png')
	if IsValid(actionEditor.div) then
		actionEditor.div:SetLeftWidth(divWidth)
	end
		
	actionEditor.OnClose = function(self)
		local w, h = actionEditor:GetSize()
		local divWidth = IsValid(actionEditor.div) and actionEditor.div:GetLeftWidth() or 200
		
		UPar.LRUSet(locationCacheKey, {w, h, divWidth})
	end

	UPar.LRUSet(guiCacheKey, actionEditor)

	return actionEditor
end

local function CreateMenu(panel)
	panel:Clear()

	local isSuperAdmin = LocalPlayer():IsSuperAdmin()
	local actionManager = vgui.Create('UParEasyTree')
	actionManager:SetSize(200, 400)
	actionManager.OnDoubleClick = function(self, selNode)
		CreateActionEditor(selNode.actName)
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
				return
			end

			if v.Invisible then 
				continue 
			end

			local label = isstring(v.label) and v.label or k
			local icon = isstring(v.icon) and v.icon or 'icon32/tool.png'
			
			local node = self:AddNode(label, icon)
			node.actName = v.Name

			if not isSuperAdmin then 
				continue 
			end

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

			if v:GetPredictionMode() == nil then
				continue
			end

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

	actionManager:RefreshNode()
	panel:AddItem(actionManager)

	local refreshButton = panel:Button('#upgui.refresh', '')
	refreshButton.DoClick = function()
		actionManager:RefreshNode()
	end

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)

	UPar.ActionManager = actionManager

	hook.Add('UParRegisterAction', 'upar.update.actionmanager', function(actName, action)
		timer.Create('upar.update.actionmanager', 0.5, 1, function()
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
