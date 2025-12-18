--[[
	作者:白狼
	2025 12 11
--]]

UPar.EffInstances = UPar.EffInstances or {}

UPEffect = UPEffect or {}
UPEffect.__index = UPEffect

local UPEffect = UPEffect
local isinstance = UPar.IsInstance
local EffInstances = UPar.EffInstances

local function isupeffect(obj)
    return isinstance(obj, UPEffect)
end

function UPEffect:Register(actName, name, initData, new)
    if string.find(actName, '[\\/:*?"<>|]') then
        error(string.format('Invalid actName "%s" (contains invalid filename characters)', actName))
    end

    if string.find(name, '[\\/:*?"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    EffInstances[actName] = istable(EffInstances[actName]) and EffInstances[actName] or {}

    local cached = EffInstances[actName][name]
    local exist = istable(cached)
    if exist then print(string.format('[UPEffect]: Warning: Effect "%s" already registered (overwritten)', name)) end

    new = new or not exist

    local self = new and setmetatable({}, UPEffect) or cached

    if not isupeffect(self) then
        setmetatable(self, UPEffect)
    end 

    EffInstances[actName][name] = self

    for k, v in pairs(initData) do
        self[k] = v
    end

	self.Name = name

	self.Start = self.Start or UPar.emptyfunc
	self.Clear = self.Clear or UPar.emptyfunc
	self.Rhythm = self.Rhythm or UPar.emptyfunc

    self.icon = CLIENT and self.icon or nil
    self.label = CLIENT and self.label or nil
    self.AAAACreat = CLIENT and self.AAAACreat or nil
    self.AAADesc = CLIENT and self.AAADesc or nil
    self.AAAContrib = CLIENT and self.AAAContrib or nil

    self.EditorKVVisible = CLIENT and self.EditorKVVisible or nil
    self.EditorKVExpand = CLIENT and self.EditorKVExpand or nil
    self.PreviewKVVisible = CLIENT and self.PreviewKVVisible or nil
    self.PreviewKVExpand = CLIENT and self.PreviewKVExpand or nil

    self.EditorPanelOverride = CLIENT and self.EditorPanelOverride or nil
    self.PreviewPanelOverride = CLIENT and self.PreviewPanelOverride or nil

    if not isfunction(self.Start) then
        error(string.format('Invalid field "Start" = "%s" (not a function)', self.Start))
    end

    if not isfunction(self.Clear) then
        error(string.format('Invalid field "Clear" = "%s" (not a function)', self.Clear))
    end

    if not isfunction(self.Rhythm) then
        print(string.format('[UPEffect]: Warning: Invalid field "Rhythm" = "%s" (not a function)', self.Rhythm))
    end

    if new then hook.Run('UParRegisterEffect', actName, name, self) end

    return self
end



UPar.isupeffect = isupeffect

