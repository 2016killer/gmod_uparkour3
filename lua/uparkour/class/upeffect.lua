--[[
	作者:白狼
	2025 12 11
--]]

UPEffect = {}
UPEffect.__index = UPEffect

local function isupeffect(obj)
    if not istable(obj) then 
        return false 
    end
    local mt = getmetatable(obj)
    while mt do
        if mt == UPEffect then return true end
  
        local index = rawget(mt, "__index")
        if istable(index) then
            mt = index
        else
            mt = getmetatable(mt)
        end
    end
    return false
end

function UPEffect:new(name, initData)
    if string.find(name, '[\\/:*?"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    local self = setmetatable({}, UPEffect)

    for k, v in pairs(initData) do
        self[k] = v
    end

	self.Name = name

	self.Start = UPar.emptyfunc
	self.Clear = UPar.emptyfunc
	self.OnRhythmChange = UPar.emptyfunc

    
    self.icon = SERVER and nil or initData.icon
    self.label = SERVER and nil or initData.label
    self.AAACreate = SERVER and nil or initData.AAACreate
    self.AAADesc = SERVER and nil or initData.AAADesc
    self.AAAContrib = SERVER and nil or initData.AAAContrib

    self.EditorKVVisible = SERVER and nil or initData.EditorKVVisible
    self.PreviewKVVisible = SERVER and nil or initData.PreviewKVVisible
    
    return self
end

function UPEffect:Register(actName)
	local action = UPar.GetAction(actName)
    if not action then
        error(string.format('can not find action named "%s"', actName))
    end

    hook.Run('UParRegisterEffect', actName, self.Name, self) 

    if action.Effects[self.Name] ~= self then
        print(string.format('[UPEffect]: Warning: Effect "%s" already registered (overwritten)', self.Name))
    end

	action.Effects[self.Name] = self
end

UPar.isupeffect = isupeffect

