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

	-- 旧版本代码
	if isfunction(action.CreateOptionMenu) then
		// local scrollPanel = vgui.Create('DScrollPanel', Tabs)
		// local optionPanel = vgui.Create('DForm', scrollPanel)
		// optionPanel:SetLabel('#upgui.options')
		// optionPanel:Dock(FILL)
		// optionPanel.Paint = function(self, w, h)
		// 	draw.RoundedBox(0, 0, 0, w, h, white)
		// end

		// action.CreateOptionMenu(optionPanel)

		// Tabs:AddSheet('#upgui.options', scrollPanel, 'icon16/wrench.png', false, false, '')
	end

	if istable(action.upgui_CreateMenus) then
		// for k, v in pairs(action.upgui_CreateMenus) do
		// 	if not istable(v) then

		// 		continue
		// 	end

		// 	if not isfunction(v.func) then

		// 		continue
		// 	end

		// 	local func = v.func
		// 	local label = isstring(v.label) and v.label or k

		// 	local DScrollPanel = vgui.Create('DScrollPanel', Tabs)
		// 	local OptionPanel = vgui.Create('DForm', DScrollPanel)
		// 	OptionPanel:SetLabel(label)
		// 	OptionPanel:Dock(FILL)
		// 	OptionPanel.Paint = function(self, w, h)
		// 		draw.RoundedBox(0, 0, 0, w, h, white)
		// 	end

		// 	local success, err = pcall(func, OptionPanel)

		// 	if not success then

		// 		continue
		// 	end

		// 	Tabs:AddSheet(label, DScrollPanel, 'icon16/wrench.png', false, false, '')
		// end
	end

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
	local ctrl = vgui.Create('ControlPresets', panel)
	ctrl:SetPreset(action.Name)

	panel:AddItem(ctrl)
	for _, v in ipairs(convars) do
		local name = v.name
		local widget = v.widget or 'NumSlider'
		local default = v.default or '0'
		local label = v.label or GetConVarPhrase(name)

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
		end

		if v.help then
			if isstring(v.help) then
				panel:ControlHelp(v.help)
			else
				panel:ControlHelp(label .. '.' .. 'help')
			end
		end
	end
	
	ctrl:AddOption('#preset.default', default)
	ctrl:AddOption('关闭', Deactiave )
	for k, v in pairs(default) do 
		ctrl:AddConVar(k) 
	end

	panel:Help('')
end

function ActionEditor:OnRemove()
	self.action = nil
	self.div = nil
end

vgui.Register('UParActionEditor', ActionEditor, 'DFrame')
ActionEditor = nil