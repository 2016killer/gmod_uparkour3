--[[
	作者:白狼
	2025 12 17
--]]


-- ==================== 特效树 ===============
local CustEffTree = {}

function CustEffTree:Init2(actName)
	self.actName = actName
	self:Refresh()
end

function CustEffTree:OnDoubleClick(node)
	self:Take(node)
	self:Play(node) 
	self:HitNode(node)
end

function CustEffTree:Refresh()
	local keys = UPar.GetUserCustEffFiles(self.actName) or UPar.emptyTable
	table.sort(keys)

	self.EffNames = keys
	
	local actName = self.actName
	local usingName = UPar.GetPlyUsingEffName(LocalPlayer(), actName)
	local cache = UPar.GetPlyEffCache(LocalPlayer(), actName)

	for _, effName in pairs(keys) do
		local node = self:AddNode2(effName, 'icon64/tool.png')

		if istable(cache) and usingName == 'CACHE' and cache.Name == effName then
			self.curSelNode = node
			node:SetIcon('icon16/accept.png')
		end
	end
end

function CustEffTree:AddNode2(effName)
	local effect = UPar.LRUGet(string.format('UI_CE_%s', effName))

	local label = nil
	local icon = nil
	if istable(effect) then
		label = isstring(effect.label) and effect.label or effName
		icon = isstring(effect.icon) and effect.icon or 'icon64/tool.png'
	else
		label = effName
		icon = 'icon64/tool.png'
	end

	local node = self:AddNode(label, icon)
	node.effName = effName
	node.icon = icon

	return node
end

function CustEffTree:InitNode(node)
	local actName = self.actName
	local effName = node.effName

	local effect = UPar.LRUGet(string.format('UI_CE_%s', effName))

	if not istable(effect) then
		effect = UPar.LoadUserCustEffFromDisk(actName, effName)

		if not istable(effect) then
			print(string.format('[UPar]: custom effect init failed, can not find custom effect named "%s" from disk', effName))
			return
		end

		UPar.InitCustomEffect(effect)

		local label = isstring(effect.label) and effect.label or effName
		local icon = isstring(effect.icon) and effect.icon or 'icon64/tool.png'
		
		node:SetText(label)
		node:SetIcon(icon)

		UPar.LRUSet(string.format('UI_CE_%s', effName), effect)
	end

	return effect
end

function CustEffTree:Play(node)
	local actName = self.actName
	local effName = node.effName

	UPar.EffectTest(LocalPlayer(), actName, effName)
	UPar.CallServerEffectTest(actName, effName)

	self:OnPlay(node)
end

function CustEffTree:Take(node)
	local actName = self.actName
	local effName = node.effName

	local effect = self:InitNode(node)

	local cfg = {[actName] = 'CACHE'}
	local cache = {[actName] = effect}

	UPar.SaveUserEffCacheToDisk()
	UPar.PushPlyEffSetting(LocalPlayer(), cfg, cache)
	UPar.CallServerPushPlyEffSetting(cfg, cache)
		
	self:OnTake(effect, node)
end

function CustEffTree:OnSelectedChange(node)
	return self:InitNode(node)
end

function CustEffTree:HitNode(node)
	if IsValid(self.curSelNode) then
		self.curSelNode:SetIcon(self.curSelNode.icon)
	end

	if IsValid(node) then
		node:SetIcon('icon16/accept.png')
	end

	self.curSelNode = node
	self:OnHitNode(node)
end

function CustEffTree:OnRemove()
	self.actName = nil
	self.curSelNode = nil
	self.EffNames = nil
end

CustEffTree.OnHitNode = UPar.emptyfunc
CustEffTree.OnPlay = UPar.emptyfunc
CustEffTree.OnTake = UPar.emptyfunc

vgui.Register('UParCustEffTree', CustEffTree, 'UParEasyTree')
CustEffTree = nil
