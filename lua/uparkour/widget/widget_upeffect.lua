--[[
	作者:白狼
	2025 12 09
--]]

local lightblue = Color(0, 170, 255)
-- ==================== 特效管理器 ===============
local EffectManager = {}

EffectManager.EditorKVVisible = function(key, val) 
	if key == 'linkName' then
		return false
	end

	return !(isfunction(val) or ismatrix(val) or isentity(val) or ispanel(val) or istable(val))
end

EffectManager.PreviewKVVisible = {
	AAACreat = lightblue,
	AAAContrib = lightblue,
	AAADesc = lightblue,
}

function EffectManager:CreatePreview(effect)
	if not istable(effect) then
		ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not table)', effect))
		return
	end

	local mainPanel = vgui.Create('DPanel')
	local customButton = vgui.Create('DButton', mainPanel)
	customButton:SetText('#upgui.custom')
	customButton:SetIcon('icon64/tool.png')
	customButton.DoClick = function()
		self:OnCreateCustom()
	end
	customButton:Dock(TOP)
	customButton:DockMargin(0, 5, 0, 5)

	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	scrollPanel:Dock(FILL)

	if isfunction(effect.PreviewPanelOverride) then
		effect:PreviewPanelOverride(scrollPanel, self)
		return mainPanel
	end

	local kVVisible = effect.PreviewKVVisible or self.PreviewKVVisible
	local kVExpand = effect.PreviewKVExpand or self.PreviewKVExpand

	local preview = vgui.Create('UParFlatTablePreview', scrollPanel)
	preview:Dock(FILL)
	preview:Init2(effect, kVVisible, kVExpand)
	preview:SetLabel(string.format('%s %s %s', 
		effect.Name, 
		language.GetPhrase('#upgui.property'),
		''
	))

	return mainPanel
end

function EffectManager:CreateEditor(effect)
	if not istable(effect) then
		ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not table)', effect))
		return
	end

	local mainPanel = vgui.Create('DPanel')

	local saveButton = vgui.Create('DButton', mainPanel)
	saveButton:Dock(TOP)
	saveButton:DockMargin(0, 5, 0, 5)
	saveButton:SetText('#upgui.save')
	saveButton:SetIcon('icon16/application_put.png')
	saveButton.DoClick = function()
		self:OnSave()
	end

	local playButton = vgui.Create('DButton', mainPanel)
	playButton:Dock(TOP)
	playButton:DockMargin(0, 5, 0, 5)
	playButton:SetText('#upgui.play')
	playButton:SetIcon('icon16/cd_go.png')
	playButton.DoClick = function()
		self:OnPlay()
	end

	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	scrollPanel:Dock(FILL)

	if isfunction(effect.EditorPanelOverride) then
		effect:EditorPanelOverride(scrollPanel, self)
		return mainPanel
	end

	local kVVisible = effect.EditorKVVisible or self.EditorKVVisible
	local kVExpand = effect.EditorKVExpand or self.EditorKVExpand

	local editor = vgui.Create('UParFlatTableEditor', scrollPanel)
	editor:Dock(FILL)
	editor:Init2(effect, kVVisible, kVExpand)

	editor:SetLabel(language.GetPhrase('#upgui.link') .. ':' .. tostring(effect.linkName))

	return mainPanel
end

function EffectManager:Init2(action)
	if not UPar.isupaction(action) then
		ErrorNoHaltWithStack(string.format('Invalid action "%s" (not upaction)', action))
		return
	end

	local actName = action.Name


	local tree = vgui.Create('UParEasyTree')
	tree.OnSelectedChange = function(_, node)
		self:CreateEditor(action.Effects[node.effName])
		self:OnSelectedEffect(node.effName, node)
	end

	local div = vgui.Create('DHorizontalDivider', self)
	div:Dock(FILL)
	div:SetDividerWidth(10)
	div:SetLeft(tree)

	self.tree = tree
	self.div = div
end

function EffectManager:Refresh()
	local keys = {}
	for k, _ in pairs(self.action.Effects) do table.insert(keys, k) end
	table.sort(keys)

	local customFiles = UPar.GetUserCustomEffectFiles(actName)
	table.sort(customFiles)

	for _, effName in pairs(keys) do
		local effect = action.Effects[effName]

		local label = isstring(effect.label) and effect.label or effName
		local icon = isstring(effect.icon) and effect.icon or 'icon16/attach.png'

		local node = tree:AddNode(label, icon)
		node.effName = effName
		node.icon = icon

		local playButton = vgui.Create('DButton', node)
		playButton:SetSize(60, 18)
		playButton:Dock(RIGHT)
		playButton:SetText('#upgui.play')
		playButton:SetIcon('icon16/cd_go.png')
		playButton.DoClick = function()
			UPar.EffectTest(LocalPlayer(), actName, effName)
		end

		if UPar.IsPlyUsingEffect(LocalPlayer(), actName, effect) then
			self.curSelNode = node
			node:SetIcon('icon16/accept.png')
		end
	end

	for _, filename in pairs(customFiles) do
		local label = filename
		local icon = 'icon64/tool.png'

		local node = tree:AddNode(label, icon)
	end
end


function EffectManager:SetLeftWidth(w)
	if not IsValid(self.div) then return end
	self.div:SetLeftWidth(w)
end

function EffectManager:OnRemove()
	self.tree = nil
	self.div = nil
	self.curSelNode = nil
end

EffectManager.OnSelectedEffect = function(self, ...) print('OnSelectedEffect', ...) end

EffectManager.OnPlay = function(self, ...) print('OnPlay', ...) end
EffectManager.OnSave = function(self, ...) print('OnSave', ...) end
EffectManager.OnCreateCustom = function(self, ...) print('OnCreateCustom', ...) end

vgui.Register('UParEffectManager', EffectManager, 'DPanel')
EffectManager = nil
