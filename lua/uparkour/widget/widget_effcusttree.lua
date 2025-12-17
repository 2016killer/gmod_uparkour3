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
	for _, effName in pairs(keys) do
		local node = self:AddNode(effName, 'icon64/tool.png')
		node.effName = effName
		node.icon = 'icon64/tool.png'

		if usingName ~= 'CACHE' and effName == usingName then
			self.curSelNode = node
			node:SetIcon('icon16/accept.png')
		end
	end
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

	local cfg = {[actName] = effName}
	UPar.SaveUserEffCfgToDisk()
	UPar.PushPlyEffSetting(LocalPlayer(), cfg, nil)
	UPar.CallServerPushPlyEffSetting(cfg, nil)
		
	self:OnTake(node)
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
