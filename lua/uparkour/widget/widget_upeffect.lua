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

	if IsValid(self.div) then 
		if IsValid(self.div:GetRight()) then self.div:GetRight():Remove() end
		self.div:SetRight(mainPanel)
	end

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
	else
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
	end

	return mainPanel
end

function EffectManager:CreateEditor(effect)
	if not istable(effect) then
		ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not table)', effect))
		return
	end

	local mainPanel = vgui.Create('DPanel')
	if IsValid(self.div) then 
		if IsValid(self.div:GetRight()) then self.div:GetRight():Remove() end
		self.div:SetRight(mainPanel)
	end

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
	else
		local kVVisible = effect.EditorKVVisible or self.EditorKVVisible
		local kVExpand = effect.EditorKVExpand or self.EditorKVExpand

		local editor = vgui.Create('UParFlatTableEditor', scrollPanel)
		editor:Dock(FILL)
		editor:Init2(effect, kVVisible, kVExpand)

		editor:SetLabel(language.GetPhrase('#upgui.link') .. ':' .. tostring(effect.linkName))
	end

	return mainPanel
end

function EffectManager:Init2(actName)
	self.actName = actName

	local tree = vgui.Create('UParEasyTree')
	tree.OnSelectedChange = function(_, node)
		if IsValid(self.div) and IsValid(self.div:GetRight()) then self.div:GetRight():Remove() end

		local effect = self:GetEffectFromNode(node)

		if UPar.IsCustomEffect(effect) then
			self:CreateEditor(effect)
		else
			self:CreatePreview(effect)
		end

		self:OnSelectedEffect(self.actName, node.effName, node)
	end

	local div = vgui.Create('DHorizontalDivider', self)
	div:Dock(FILL)
	div:SetDividerWidth(10)
	div:SetLeft(tree)

	local widthCacheKey = 'EffectEditor_LeftWidth'
	local w = UPar.LRUGet(widthCacheKey)
	if isnumber(w) then
		div:SetLeftWidth(math.max(20, w))
	else
		div:SetLeftWidth(250)
	end


	self.tree = tree
	self.div = div

	self:Refresh()
end

function EffectManager:GetEffectFromNode(node)
	local effect = self.Effects[node.effName]

	if isstring(effect) then
		effect = UPar.LoadUserCustEffFromDisk(self.actName, effect)

		local label = isstring(effect.label) and effect.label or tostring(node.effName)
		node:SetText(label)
	end

	return effect
end

function EffectManager:Refresh()
	local effects = {}
	local keys = {}
	for k, v in pairs(UPar.GetEffects(self.actName)) do 
		table.insert(keys, k) 
		effects[k] = v
	end
	table.sort(keys)

	local customFiles = UPar.GetUserCustEffFiles(self.actName) or UPar.emptyTable
	for i, k in pairs(customFiles) do effects[k] = k end 
	table.sort(customFiles)

	for _, effName in pairs(keys) do
		local effect = UPar.GetEffect(self.actName, effName)

		local label = isstring(effect.label) and effect.label or effName
		local icon = isstring(effect.icon) and effect.icon or 'icon16/attach.png'

		local node = self.tree:AddNode(label, icon)
		node.effName = effName
		node.icon = icon

		local playButton = vgui.Create('DButton', node)
		playButton:SetSize(60, 18)
		playButton:Dock(RIGHT)
		playButton:SetText('#upgui.play')
		playButton:SetIcon('icon16/cd_go.png')
		playButton.DoClick = function()
			UPar.EffectTest(LocalPlayer(), self.actName, effName)
			UPar.CallServerEffectTest(self.actName, effName)

			local cfg = {[self.actName] = effName}
			UPar.SaveUserEffCfgToDisk()
			UPar.PushPlyEffSetting(LocalPlayer(), cfg, nil)
			UPar.CallServerPushPlyEffSetting(cfg, nil)
		end

		if UPar.IsPlyUsingEffect(LocalPlayer(), self.actName, effect) then
			self.curSelNode = node
			node:SetIcon('icon16/accept.png')
		end
	end

	for _, filename in pairs(customFiles) do
		local label = filename
		local icon = 'icon64/tool.png'

		local node = self.tree:AddNode(label, icon)
		node.effName = filename
		node.icon = icon
	end

	self.Effects = effects
end

function EffectManager:OnRemove()
	local widthCacheKey = 'EffectEditor_LeftWidth'
	local w = IsValid(self.div) and self.div:GetLeftWidth() or 200
	UPar.LRUSet(widthCacheKey, w)

	self.tree = nil
	self.div = nil
	self.curSelNode = nil
end


function EffectManager:OnRemove()
	local widthCacheKey = 'EffectEditor_LeftWidth'
	local w = IsValid(self.div) and self.div:GetLeftWidth() or 200
	UPar.LRUSet(widthCacheKey, w)

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
