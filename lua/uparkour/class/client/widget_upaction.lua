--[[
	作者:白狼
	2025 12 09
--]]


local white = Color(255, 255, 255)

-- ==================== 动作编辑器 ===============
local ActionEditor = {}

function ActionEditor:Init2(action)
	local actName = action.Name

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
	Tabs:AddSheet('#upgui.effect', effectManager, 'icon16/user.png', false, false, '')

	-- 旧版本代码
	if isfunction(action.CreateOptionMenu) then
		local scrollPanel = vgui.Create('DScrollPanel', Tabs)
		local optionPanel = vgui.Create('DForm', scrollPanel)
		optionPanel:SetLabel('#upgui.options')
		optionPanel:Dock(FILL)
		optionPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, white)
		end

		action.CreateOptionMenu(optionPanel)

		Tabs:AddSheet('#upgui.options', scrollPanel, 'icon16/wrench.png', false, false, '')
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

	self.div = effectManager.div
end

vgui.Register('UParActionEditor', ActionEditor, 'DFrame')
ActionEditor = nil