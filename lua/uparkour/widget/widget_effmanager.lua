--[[
	作者:白狼
	2025 12 17
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
		string.format('Custom-%s-%s', tarName, os.time()),         
		function(text)    
			if string.find(text, '[\\/:*?"<>|]') then
				error(string.format('Invalid name "%s" (contains invalid filename characters)', text))
			end

			local exist = true
			for i = 0, 2 do
				local suffix = i == 0 and '' or ('_' .. tostring(i))
				local newFileName = string.format('%s%s', text, suffix)
				if not effManager.Effects[newFileName] then 
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
		preview:SetLabel(effect.Name)
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

		editor:SetLabel(language.GetPhrase('#upgui.link') .. '-' .. tostring(effect.linkName))
	end

	return mainPanel
end

function EffectManager:Init2(actName)
	self.actName = actName

	local div = vgui.Create('DHorizontalDivider', self)
	local div2 = vgui.Create('DVerticalDivider', div)
	local effTree = vgui.Create('UParEffTree', div2)
	local custTree = vgui.Create('UParCustEffTree', div2)
	

	effTree:Init2(actName)
	custTree:Init2(actName)

	div:Dock(FILL)
	div:SetLeft(div2)
	div:SetLeftWidth(250)
	div:SetDividerWidth(5)

	div2:SetDividerHeight(5)
	div2:SetTop(effTree)
	div2:SetBottom(custTree)

	self.div = div
	self.div2 = div2
	self.effTree = effTree
	self.custTree = custTree

	local oldOnSelectedChange = effTree.OnSelectedChange
	effTree.OnSelectedChange = function(self2, node)
		oldOnSelectedChange(self2, node)

		local effName = node.effName
		local effect = UPar.GetEffect(actName, effName)
		self:CreatePreview(effect)
	end

	local oldOnSelectedChange_ = custTree.OnSelectedChange
	custTree.OnSelectedChange = function(self2, node)
		local effect = oldOnSelectedChange_(self2, node)
		self:CreateEditor(effect)
	end

	local layout = UPar.LRUGet('UI_EffectEditor_Layout')
	if isvector(layout) then
		div:SetLeftWidth(math.max(20, layout[1]))
		div2:SetTopHeight(math.max(20, layout[2]))
	else
		div:SetLeftWidth(250)
		div2:SetTopHeight(200)
	end
end

function EffectManager:IsEffNameExist(effName)
	// self.effTree
end

function EffectManager:Refresh()
	self.effTree:Refresh()
	self.custTree:Refresh()

	if IsValid(self.div:GetRight()) then 
		self.div:GetRight():Remove() 
	end
end

function EffectManager:OnRemove()
	local layout = Vector()
	layout[1] = IsValid(self.div) and self.div:GetLeftWidth() or 250
	layout[2] = IsValid(self.div2) and self.div2:GetTopHeight() or 200
	UPar.LRUSet('UI_EffectEditor_Layout', layout)


	self.actName = nil
	self.div = nil
	self.div2 = nil
	self.effTree = nil
	self.custTree = nil
	self.curSelNode = nil
end

vgui.Register('UParEffectManager', EffectManager, 'DPanel')
EffectManager = nil
