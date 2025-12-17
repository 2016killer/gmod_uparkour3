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
	self.Tabs = Tabs

	local effectManager = vgui.Create('UParEffectManager')
	effectManager:Init2(action)
	effectManager:SetLeftWidth(0.5 * self:GetWide())
	self.div = effectManager.div
	Tabs:AddSheet('#upgui.effect', effectManager, 'icon16/user.png', false, false, '')


	if istable(action.ConVarsWidget) then
		self:AddSheet(
			'#upgui.options', 
			'icon16/wrench.png', 
			isfunction(action.ConVarsPanelOverride) and action.ConVarsPanelOverride or self.CreateConVarsPanel
		)
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

			self:AddSheet(
				panelData.label, 
				'icon16/add.png', 
				panelData.func
			)
		end
	end

	local descriptionPanel = vgui.Create('UParDescription')
	descriptionPanel:SetLabel('#upgui.desc')
	descriptionPanel:Init2(action)

	self:AddSheet(
		'#upgui.desc', 
		'icon16/information.png', 
		descriptionPanel
	)
end

function ActionEditor:AddSheet(label, icon, panel)
	if not ispanel(panel) and not isfunction(panel) then
		ErrorNoHaltWithStack(string.format('panel must be a panel or function, but got %s', type(panel)))
		return
	end

	label = isstring(label) and label or tostring(k)
	icon = isstring(icon) and icon or 'icon16/add.png'

	local mainPanel = vgui.Create('DPanel', self.Tabs)
	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	scrollPanel:Dock(FILL)

	if isfunction(panel) then
		local func = panel
		local contentPanel = vgui.Create('DForm', scrollPanel)
		contentPanel:SetLabel('#upgui.options')
		contentPanel:Dock(FILL)

		local succ, err = pcall(func, self.action, contentPanel)
		if not succ then
			ErrorNoHaltWithStack(string.format('AddSheet failed: %s', err))			
		end
	elseif ispanel(panel) then
		panel:SetParent(scrollPanel)
		panel:Dock(FILL)
	end

	self.Tabs:AddSheet(label, mainPanel, icon, false, false, '')
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

ActionEditor.CreateConVarsPanel = function(action, panel)
	if not istable(action.ConVarsWidget) then
		error('action.ConVarsWidget must be a table')
		return
	end

	local ctrl = vgui.Create('ControlPresets', panel)
	ctrl:SetPreset(action.Name)
	panel:AddItem(ctrl)

	local isAdmin = not LocalPlayer():IsAdmin()

	local defaultPreset = {}
	for idx, v in ipairs(action.ConVarsWidget) do
		local name = v.name
		local widgetClass = v.widget or 'NumSlider'
		local default = v.default or '0'
		local label = v.label or UPar.GetConVarPhrase(name)
		local invisible = v.invisible
		local admin = v.admin

		ctrl:AddConVar(name)
		defaultPreset[name] = default

		if invisible then 
			continue 
		end

		if admin and not isAdmin then 
			continue 
		end

		local widget = nil

		if widgetClass == 'NumSlider' then 
			widget = panel:NumSlider(
				label, 
				name, 
				isnumber(v.min) and v.min or 0, 
				isnumber(v.max) and v.max or 1, 
				isnumber(v.decimals) and v.decimals or 2
			)
		elseif widgetClass == 'CheckBox' then
			widget = panel:CheckBox(label, name)
		elseif widgetClass == 'ComboBox' then
			widget = panel:ComboBox(label, name)

			if istable(v.choices) then
				for _, choice in ipairs(v.choices) do
					if isstring(choice) then
						widget:AddChoice(choice)
					elseif istable(choice) then
						widget:AddChoice(unpack(choice))
					else
						print(string.format('[UPar]: Warning: ComboBox choice must be a string or a table, but got %s', type(choice)))
					end
				end
			end
		elseif widgetClass == 'TextEntry' then
			widget = panel:TextEntry(label, name)
		elseif widgetClass == 'KeyBinder' then
			widget = panel:KeyBinder(label, name)
		elseif widgetClass == 'UParColorEditor' then
			widget = vgui.Create('UParColorEditor', panel)
			widget:SetConVar(name)

			panel:Help(label)
			panel:AddItem(widget)
		elseif widgetClass == 'UParAngEditor' then
			widget = vgui.Create('UParAngEditor', panel)
			widget:SetMin(isnumber(v.min) and v.min or -10000)
			widget:SetMax(isnumber(v.max) and v.max or 10000)
			widget:SetDecimals(isnumber(v.decimals) and v.decimals or 2)
			widget:SetInterval(isnumber(v.interval) and v.interval or 0.5)
			widget:SetConVar(name)

			panel:Help(label)
		elseif widgetClass == 'UParVecEditor' then
			widget = vgui.Create('UParVecEditor', panel)
			widget:SetMin(isnumber(v.min) and v.min or -10000)
			widget:SetMax(isnumber(v.max) and v.max or 10000)
			widget:SetDecimals(isnumber(v.decimals) and v.decimals or 2)
			widget:SetInterval(isnumber(v.interval) and v.interval or 0.5)
			widget:SetConVar(name)

			panel:Help(label)
		elseif widgetClass == 'UParKeyBinder' then
			widget = vgui.Create('UParKeyBinder', panel)
			widget:SetConVar(name)

			panel:Help(label)
		end

		local expanded = nil
		if isfunction(action.ConVarWidgetExpand) then
			local succ, err = pcall(action.ConVarWidgetExpand, action, idx, v, widget, panel)
			if succ then
				expanded = err
			else
				ErrorNoHaltWithStack(string.format('ConVarWidgetExpand label "%s" failed: %s', label, err))
			end
		end

		if IsValid(widget) and ispanel(widget) then
			panel:AddItem(widget)
		end
		
		if IsValid(expanded) and ispanel(expanded) then
			panel:AddItem(expanded)
		end

		if isstring(v.help) then
			panel:ControlHelp(v.help)
		elseif v.help then
			panel:ControlHelp(label .. '.' .. 'help')
		end
	end
	
	ctrl:AddOption('#preset.default', defaultPreset)

	for pname, pdata in pairs(action.ConVarsPreset) do
		local label = isstring(pdata.label) and pdata.label or pname
		local values = pdata.values

		ctrl:AddOption(label, values)
	end

	panel:Help('')
end

function ActionEditor:OnRemove()
	self.action = nil
	self.div = nil
	self.Tabs = nil
end

vgui.Register('UParActionEditor', ActionEditor, 'DFrame')
ActionEditor = nil