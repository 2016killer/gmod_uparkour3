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
        local nextMt = getmetatable(mt)
        if nextMt and nextMt.__index then
            mt = nextMt.__index
        else
            break
        end
    end
    return false
end

function UPEffect:new(name, initData)
    if string.find(name, '[\\/:*?\"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    local self = setmetatable({}, UPEffect)

	self.Name = name
	self.Start = self.Start or UPar.emptyfunc
	self.Clear = self.Clear or UPar.emptyfunc
	self.OnRhythmChange = self.OnRhythmChange or UPar.emptyfunc

    self:SetIcon(initData.icon)
    self:SetLabel(initData.label)

    return self
end

function UPEffect:SetIcon(icon)
    if SERVER or icon == nil then return end
    if not isstring(icon) then
        error(string.format('Invalid icon "%s" (not a string)', icon))
    end
    self.icon = icon
end

function UPEffect:SetLabel(label)
    if SERVER or label == nil then return end
    if not isstring(label) then
        error(string.format('Invalid label "%s" (not a string)', label))
    end
    self.label = label
end

function UPEffect:Register(actName)
	local action = UPar.GetAction(actName)
    if not action then
        error(string.format('Invalid action "%s"', actName))
    end

    if hook.Run('UParRegisterEffect', actName, self.Name, self) then 
        return 
    end
    
	action.Effects[self.Name] = self
end

UPar.isupeffect = isupeffect

