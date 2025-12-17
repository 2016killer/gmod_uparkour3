--[[
	作者:白狼
	2025 12 09
--]]

local lightblue = Color(0, 170, 255)
-- ==================== 特效管理器 ===============
local EffectManager = {}

EffectManager.EditorKVVisible = function(key, val) 
	if key == 'linkName' or key == 'linkAct' or key == 'Name' then
		return false
	end

	return !(isfunction(val) or ismatrix(val) or isentity(val) or ispanel(val) or istable(val))
end

EffectManager.PreviewKVVisible = {
	AAAACreat = lightblue,
	AAAContrib = lightblue,
	AAADesc = lightblue,
}

local function CreateCustomEffectByDerma(actName, tarName, effManager)
	Derma_StringRequest(
		'#upgui.derma.filename',           
		'',  
		string.format('Custom-%s', os.time()),         
		function(text)    
			if string.find(text, '[\\/:*?"<>|]') then
				error(string.format('Invalid name "%s" (contains invalid filename characters)', text))
			end

			local exist = true
			for i = 0, 2 do
				local suffix = i == 0 and '' or ('_' .. tostring(i))
				local newFileName = string.format('%s%s', text, suffix)
				if not UPar.GetCustEffExist(actName, newFileName) then 
					text = newFileName
					exist = false
					break
				end
			end

			if exist then
				notification.AddLegacy(string.format('Custom Effect "%s" already exist', text), NOTIFY_ERROR, 5)
				surface.PlaySound('Buttons.snd10')

				return
			end

			local custom = UPar.CreateUserCustEff(actName, tarName, text, true)
			UPar.InitCustomEffect(custom)

			effManager.Effects[text] = custom
			effManager:AddCustEffNode(text .. '.json')
		end,
		nil,
		'#upgui.derma.submit',                    
		'#upgui.derma.cancel'
	)
end

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
		CreateCustomEffectByDerma(self.actName, effect.Name, self)
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

	end

	local playButton = vgui.Create('DButton', mainPanel)
	playButton:Dock(TOP)
	playButton:DockMargin(0, 5, 0, 5)
	playButton:SetText('#upgui.play')
	playButton:SetIcon('icon16/cd_go.png')
	playButton.DoClick = function()
		// UPar.EffectTest(LocalPlayer(), self.actName, effName)
		// UPar.CallServerEffectTest(self.actName, effName)

		// local cfg = {[self.actName] = effName}
		// UPar.SaveUserEffCfgToDisk()
		// UPar.PushPlyEffSetting(LocalPlayer(), cfg, nil)
		// UPar.CallServerPushPlyEffSetting(cfg, nil)
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
	end

	tree.OnDoubleClick = function(_, node)
		self:HitNode(node)
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

function EffectManager:AddEffNode(effect)
	local effName = effect.Name
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

		self:HitNode(node)
	end

	if UPar.IsPlyUsingEffect(LocalPlayer(), self.actName, effect) then
		self:HitNode(node)
	end
end

function EffectManager:AddCustEffNode(filename)
	local label = filename
	local icon = 'icon64/tool.png'

	local node = self.tree:AddNode(label, icon)
	node.effName = filename
	node.icon = icon

	self.Effects[filename] = filename
end

function EffectManager:Refresh()
	local keys = {}
	local Effects = {}
	for k, v in pairs(UPar.GetEffects(self.actName)) do 
		Effects[k] = v
		table.insert(keys, k) 
	end
	table.sort(keys)

	local customFiles = UPar.GetUserCustEffFiles(self.actName) or UPar.emptyTable
	table.sort(customFiles)

	self.Effects = Effects

	for _, effName in pairs(keys) do
		local effect = Effects[effName]

		if not istable(effect) then
			ErrorNoHaltWithStack(string.format('Invalid effect named "%s" (not table)', effName))
			continue
		end

		self:AddEffNode(effect)
	end

	for _, filename in pairs(customFiles) do
		self:AddCustEffNode(filename)
	end
end

function EffectManager:HitNode(node)
	if IsValid(self.curSelNode) then
		self.curSelNode:SetIcon(self.curSelNode.icon)
	end

	self.curSelNode = node
	node:SetIcon('icon16/accept.png')
end

function EffectManager:OnRemove()
	local widthCacheKey = 'EffectEditor_LeftWidth'
	local w = IsValid(self.div) and self.div:GetLeftWidth() or 200
	UPar.LRUSet(widthCacheKey, w)

	self.Effects = nil
	self.tree = nil
	self.div = nil
	self.curSelNode = nil
end

vgui.Register('UParEffectManager', EffectManager, 'DPanel')
EffectManager = nil
