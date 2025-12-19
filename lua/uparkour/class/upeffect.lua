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
    assert(isstring(actName), string.format('Invalid actName "%s" (not a string)', actName))
    assert(isstring(name), string.format('Invalid name "%s" (not a string)', name))
    assert(not string.find(actName, '[\\/:*?"<>|]'), string.format('Invalid actName "%s" (contains invalid filename characters)', actName))
    assert(not string.find(name, '[\\/:*?"<>|]'), string.format('Invalid name "%s" (contains invalid filename characters)', name))
    assert(istable(initData), string.format('Invalid initData "%s" (not a table)', initData))

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

    assert(isfunction(self.Start), string.format('Invalid field "Start" = "%s" (not a function)', self.Start))
    assert(isfunction(self.Clear), string.format('Invalid field "Clear" = "%s" (not a function)', self.Clear))
    
    if not isfunction(self.Rhythm) then
        print(string.format('[UPEffect]: Warning: Invalid field "Rhythm" = "%s" (not a function)', self.Rhythm))
    end

    if new then hook.Run('UParRegisterEffect', actName, name, self) end

    return self
end



UPar.isupeffect = isupeffect

