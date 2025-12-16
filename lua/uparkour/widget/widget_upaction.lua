--[[
	作者:白狼
	2025 12 09
--]]


local white = Color(255, 255, 255)

-- ==================== 动作编辑器 ===============
local ActionEditor = {}

function ActionEditor:Init2(action)
	if not UPar.isupaction(action) then
		ErrorNoHaltWithStack(string.format('Invalid action "%s" (not upaction)', action))
		return
	end

	local actName = action.Name
	self.action = action

	self:SetSize(600, 400)
	self:SetPos(0, 0)
	self:MakePopup()
	self:SetSizable(true)
	self:SetDeleteOnClose(true)
	self:SetTitle(string.format(
		'%s   %s', 
		language.GetPhrase('#upgui.menu.actionmanager'), 
		language.GetPhrase(isstring(action.label) and action.label or actName)
	))

	local Tabs = vgui.Create('DPropertySheet', self)
	Tabs:Dock(FILL)

	local effectManager = vgui.Create('UParEffectManager')
	effectManager:Init2(action)
	effectManager:SetLeftWidth(0.5 * self:GetWide())
	self.div = effectManager.div
	Tabs:AddSheet('#upgui.effect', effectManager, 'icon16/user.png', false, false, '')


	if istable(action.ConVarsWidget) then
		local mainPanel = vgui.Create('DPanel', Tabs)
		local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
		scrollPanel:Dock(FILL)
		local optionPanel = vgui.Create('DForm', scrollPanel)
		optionPanel:SetLabel('#upgui.options')
		optionPanel:Dock(FILL)

		local CreateConVarsPanel = isfunction(action.ConVarsPanelOverride) and action.ConVarsPanelOverride or UPar.CreateConVarsPanel

		local succ, err = pcall(CreateConVarsPanel, action, optionPanel)
		if succ then
			Tabs:AddSheet('#upgui.options', mainPanel, 'icon16/wrench.png', false, false, '')
		else
			ErrorNoHaltWithStack(string.format('CreateConVarsPanel failed: %s', err))
			mainPanel:Remove()
			scrollPanel:Remove()
			optionPanel:Remove()			
		end
	end

	if istable(action.SundryPanels) then
		for k, panelData in pairs(action.SundryPanels) do
			if not istable(panelData) then
				print(string.format('[UPar]: Warning: SundryPanels must be a table of tables, but got %s', type(panelData)))
				continue
			end

			if not isfunction(panelData.func) then
				print(string.format('[UPar]: Warning: panelData.func must be a function, but got %s', type(panelData.func)))
				continue
			end

			local label = isstring(panelData.label) and panelData.label or tostring(k)
			local icon = isstring(panelData.icon) and panelData.icon or 'icon16/add.png'

			local mainPanel = vgui.Create('DPanel', Tabs)
			local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
			scrollPanel:Dock(FILL)
			local optionPanel = vgui.Create('DForm', scrollPanel)
			optionPanel:SetLabel(label)
			optionPanel:Dock(FILL)

			local succ, err = pcall(panelData.func, action, optionPanel)

			if succ then
				Tabs:AddSheet(label, mainPanel, icon, false, false, '')
			else
				ErrorNoHaltWithStack(string.format('SundryPanel idx "%s", label "%s" failed: %s', k, label, err))
				mainPanel:Remove()
				scrollPanel:Remove()
				optionPanel:Remove()
			end
		end
	end

	local mainPanel = vgui.Create('DPanel', Tabs)
	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	scrollPanel:Dock(FILL)
	local descriptionPanel = vgui.Create('UParDescription', scrollPanel)
	descriptionPanel:Dock(FILL)
	descriptionPanel:SetLabel('#upgui.desc')
	descriptionPanel:Init2(action)

	Tabs:AddSheet('#upgui.desc', mainPanel, 'icon16/information.png', false, false, '')
end

local function GetConVarPhrase(name)
	-- 替换第一个下划线为点号
	local start, ending, phrase = string.find(name, "_", 1)

	if start == nil then
		return name
	else
		return '#' .. name:sub(1, start - 1) .. '.' .. name:sub(ending + 1)
	end
end

UPar.CreateConVarsPanel = function(action, panel)
	if not istable(action.ConVarsPreset) or not istable(action.ConVarsPreset[1]) then
		error('action.ConVarsPreset must be a table of tables')
		return
	end

	if not istable(action.ConVarsWidget) then
		error('action.ConVarsWidget must be a table')
		return
	end

	local ctrl = vgui.Create('ControlPresets', panel)
	ctrl:SetPreset(action.Name)
	panel:AddItem(ctrl)

	for i, presetdata in pairs(action.ConVarsPreset) do
		local label = isstring(presetdata.label) and presetdata.label or 'UNKNOWN'
		local values = presetdata.values

		-- 1被默认占用, 除非通过非法接口对ConVarsPreset进行修改
		if i == 1 then
			for cvName, _ in pairs(values) do ctrl:AddConVar(cvName) end
		end

		ctrl:AddOption(label, values)
	end

	local isAdmin = not LocalPlayer():IsAdmin()

	for _, v in ipairs(action.ConVarsWidget) do
		local name = v.name
		local widget = v.widget or 'NumSlider'
		local default = v.default or '0'
		local label = v.label or GetConVarPhrase(name)
		local invisible = v.invisible
		local admin = v.admin

		if invisible then 
			continue 
		end

		if admin and not isAdmin then 
			continue 
		end

		if widget == 'NumSlider' then
			panel:NumSlider(
				label, 
				name, 
				v.min or 0, v.max or 1, 
				v.decimals or 2
			)
		elseif widget == 'CheckBox' then
			panel:CheckBox(label, name)
		elseif widget == 'ComboBox' then
			panel:ComboBox(
				label, 
				name, 
				v.choices or {}
			)
		elseif widget == 'TextEntry' then
			panel:TextEntry(label, name)
		elseif widget == 'KeyBinder' then
			panel:KeyBinder(label, name)
		elseif widget == 'UParColorEditor' then
			local colorEditor = vgui.Create('UParColorEditor', panel)
			colorEditor:SetConVar(name)

			panel:Help(label)
			panel:AddItem(colorEditor)
		elseif widget == 'UParAngEditor' then
			local angEditor = vgui.Create('UParAngEditor', panel)
			angEditor:SetMin(v.min or -10000)
			angEditor:SetMax(v.max or 10000)
			angEditor:SetDecimals(v.decimals or 2)
			angEditor:SetInterval(v.interval or 0.5)
			angEditor:SetConVar(name)

			panel:Help(label)
			panel:AddItem(angEditor)
		elseif widget == 'UParVecEditor' then
			local vecEditor = vgui.Create('UParVecEditor', panel)
			vecEditor:SetMin(v.min or -10000)
			vecEditor:SetMax(v.max or 10000)
			vecEditor:SetDecimals(v.decimals or 2)
			vecEditor:SetInterval(v.interval or 0.5)
			vecEditor:SetConVar(name)

			panel:Help(label)
			panel:AddItem(vecEditor)
		elseif widget == 'UParKeyBinder' then
			local keyBinder = vgui.Create('UParKeyBinder', panel)
			keyBinder:SetConVar(name)

			panel:Help(label)
			panel:AddItem(keyBinder)
		end

		if v.help then
			if isstring(v.help) then
				panel:ControlHelp(v.help)
			else
				panel:ControlHelp(label .. '.' .. 'help')
			end
		end
	end
	
	panel:Help('')
end

function ActionEditor:OnRemove()
	self.action = nil
	self.div = nil
end

vgui.Register('UParActionEditor', ActionEditor, 'DFrame')
ActionEditor = nil