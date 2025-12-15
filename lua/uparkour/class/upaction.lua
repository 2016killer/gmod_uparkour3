--[[
	作者:白狼
	2025 12 10
--]]


UPAction = {}
UPAction.__index = UPAction

local Instances = {}

local function sanitizeConVarName(name)
    return 'upact_' .. string.gsub(name, '[\\/:*?"<>|]', '_')
end

local function isupaction(obj)
    if not istable(obj) then 
        return false 
    end
    local mt = getmetatable(obj)
    while mt do
        if mt == UPAction then return true end
  
        local index = rawget(mt, "__index")
        if istable(index) then
            mt = index
        else
            mt = getmetatable(mt)
        end
    end
    return false
end

function UPAction:new(name, initData)
    if string.find(name, '[\\/:*?"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    local self = setmetatable({}, UPAction)

    for k, v in pairs(initData) do
        self[k] = v
    end

    self.Name = name
    self.Effects = {}

    self.Check = UPar.tablefunc
    self.Start = UPar.emptyfunc
    self.Think = UPar.tablefunc
    self.Clear = UPar.emptyfunc

    self:InitCVarDisabled(initData.disabled)

    self.icon = SERVER and nil or initData.icon
    self.label = SERVER and nil or initData.label
    self.AAACreate = SERVER and nil or initData.AAACreate
    self.AAADesc = SERVER and nil or initData.AAADesc
    self.AAAContrib = SERVER and nil or initData.AAAContrib

    self.TrackId = initData.TrackId or 0
    
    return self
end

function UPAction:Register()
    hook.Run('UParRegisterAction', self.Name, self) 
    if Instances[self.Name] and Instances[self.Name] ~= self then
        print(string.format('[UPAction]: Warning: Action "%s" already registered (overwritten)', self.Name))
    end
    Instances[self.Name] = self
end

function UPAction:GetEffect(effName)
    return self.Effects[effName]
end

function UPAction:GetPlayerEffect(ply, effName)
    if effName == 'CACHE' then
        return ply.upeff_cache[self.Name] or self.Effects.default
    else
        return self.Effects[effName] or self.Effects.default
    end
end

function UPAction:GetPlayerUsingEffect(ply)
    local effName = ply.upeff_cfg[self.Name] or 'default'
    if effName == 'CACHE' then
        return ply.upeff_cache[self.Name] or self.Effects.default
    else
        return self.Effects[effName] or self.Effects.default
    end
end

function UPAction:InitCVarDisabled(default)
    local cvName = sanitizeConVarName(self.Name) .. '_disabled'
    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}

    local cvar = CreateConVar(cvName, default and '1' or '0', cvFlags, '')
    self.CV_Disabled = cvar
end

function UPAction:GetDisabled()
    return self.CV_Disabled:GetBool()
end

function UPAction:SetDisabled(disabled)
    if SERVER then 
        self.CV_Disabled:SetBool(!!disabled)
    elseif CLIENT then
        RunConsoleCommand(self.CV_Disabled:GetName(), (!!disabled) and '1' or '0')
    end
end

function UPAction:InitCVarPredictionMode(default)
    local cvName = sanitizeConVarName(self.Name) .. '_pred_mode'
    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}

    local cvar = CreateConVar(cvName, default and '1' or '0', cvFlags, '')
    self.CV_PredictionMode = cvar
end

function UPAction:GetPredictionMode()
    if not self.CV_PredictionMode then return nil end
    return self.CV_PredictionMode:GetBool()
end

function UPAction:SetPredictionMode(predictionMode)
    if SERVER then 
        self.CV_PredictionMode:SetBool(!!predictionMode)
    elseif CLIENT then
        RunConsoleCommand(self.CV_PredictionMode:GetName(), (!!predictionMode) and '1' or '0')
    end
end

function UPAction:InitConVars(config)
    if not istable(config) then
        error(string.format('Invalid config "%s" (not a table)', config))
    end

    self.ConVars = {}
    for i, v in ipairs(config) do
        if not isstring(v.name) then
            error(string.format('Invalid field "name" (not a string), index = %d', i))
        end

        if not isstring(v.default) then
            error(string.format('Invalid field "default" (not a string), name = "%s"', v.name))
        end

        if not istable(v.flags) and not isnumber(v.flags) and v.flags ~= nil then
            error(string.format('Invalid field "flags" (not a table or number or nil), name = "%s"', v.name))
        end

        if v.client ~= nil and not isbool(v.client) then
            error(string.format('Invalid field "client" (must be a boolean or nil), name = "%s"', v.name))
        end

        if v.client == nil then
            self.ConVars[v.name] = CreateConVar(v.name, v.default, v.flags or { FCVAR_ARCHIVE, FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
        elseif SERVER and v.client == false then
            self.ConVars[v.name] = CreateConVar(v.name, v.default, v.flags or { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
        elseif CLIENT and v.client == true then
            self.ConVars[v.name] = CreateClientConVar(v.name, v.default, true, false) 
        end
    end

    if SERVER then
        return
    end

    self.ConVarsWidget = config
    self.ConVarsPresets = istable(self.ConVarsPresets) and self.ConVarsPresets or {}
    local defaultPreset = {
        name = 'default',
        label = '#default',
        values = {}
    }

    for _, v in ipairs(config) do defaultPreset.values[v.name] = v.default end
    table.insert(self.ConVarsPresets, defaultPreset)
end

if CLIENT then
    function UPAction:InitCVarKeybind(default)
        local cvName = sanitizeConVarName(self.Name) .. '_keybind'
        local cvar = CreateClientConVar(cvName, tostring(default), true, false, '')

        self.CV_Keybind = cvar
    end

    function UPAction:GetKeybind()
        if not self.CV_Keybind then 
            return nil 
        end

        local keys = string.Split(self.CV_Keybind:GetString(), ' ') 
        local result = {}
        for i, k in ipairs(keys) do
            if string.Trim(k) == '' then
                continue
            else
                result[i] = tonumber(k) or 0
            end
        end

        return result
    end

    function UPAction:SetKeybind(keynums) 
        -- Example: {0, 0, 0}
        if not istable(keynums) then
            error(string.format('Invalid keynums "%s" (not a table)', keynums))
        end

        local keys = {}
        for i, kn in ipairs(keynums) do
            if not isnumber(kn) then
                table.insert(keys, 0)
            else
                table.insert(keys, kn)
            end
        end

        self.CV_Keybind:SetString(table.concat(keys, ' '))
    end

    function UPAction:RegisterPreset(preset)
        if not istable(preset) then
            error(string.format('Invalid preset "%s" (not a table)', preset))
        end

        if not isstring(preset.name) then
            error(string.format('Invalid name "%s" (not a string)', preset.name))
        end

        if not istable(preset.values) then
            error(string.format('Invalid values "%s" (not a table)', preset.values))
        end

        for cvName, val in pairs(preset.values) do
            if not isstring(cvName) then
                error(string.format('Invalid cvName "%s" (not a string)', cvName))
            end

            if not isstring(val) then
                error(string.format('Invalid val "%s" (not a string), cvName = "%s"', val, cvName))
            end
        end

        self.ConVarsPresets = istable(self.ConVarsPresets) and self.ConVarsPresets or {}

        table.insert(self.ConVarsPresets, preset)
    end
end

UPar.GetAllActions = function() return Instances end
UPar.GetAction = function(name) return Instances[name] end
UPar.isupaction = isupaction

