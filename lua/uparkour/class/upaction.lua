--[[
	作者:白狼
	2025 12 10
--]]

UPar.ActInstances = UPar.ActInstances or {}
UPar.EffInstances = UPar.EffInstances or {}

UPAction = UPAction or {}
UPAction.__index = UPAction

local UPAction = UPAction
local isinstance = UPar.IsInstance
local Instances = UPar.ActInstances
local EffInstances = UPar.EffInstances

local function sanitizeConVarName(name)
    return 'upact_' .. string.gsub(name, '[\\/:*?"<>|]', '_')
end

local function isupaction(obj)
    return isinstance(obj, UPAction)
end

function UPAction:Register(name, initData, new)
    if string.find(name, '[\\/:*?"<>|]') then
        error(string.format('Invalid name "%s" (contains invalid filename characters)', name))
    end

    if not istable(initData) then
        error(string.format('Invalid initData "%s" (not a table)', initData))
    end

    local cached = Instances[name]
    local exist = istable(cached)
    if exist then print(string.format('[UPAction]: Warning: Action "%s" already registered (overwritten)', name)) end

    new = new or not exist

    local self = new and setmetatable({}, UPAction) or cached

    if not isupaction(self) then
        setmetatable(self, UPAction)
    end 

    Instances[name] = self
    EffInstances[name] = istable(EffInstances[name]) and EffInstances[name] or {}

    for k, v in pairs(initData) do
        self[k] = v
    end

    self.Name = name
 
    self.Check = self.Check or UPar.tablefunc
    self.Start = self.Start or UPar.emptyfunc
    self.Think = self.Think or UPar.tablefunc
    self.Clear = self.Clear or UPar.emptyfunc

    self:InitCVarDisabled(self.defaultDisabled)

    self.icon = CLIENT and self.icon or nil
    self.label = CLIENT and self.label or nil
    self.AAAACreat = CLIENT and self.AAAACreat or nil
    self.AAADesc = CLIENT and self.AAADesc or nil
    self.AAAContrib = CLIENT and self.AAAContrib or nil

    self.ConVarWidgetExpand = CLIENT and self.ConVarWidgetExpand or nil
    self.ConVarsPanelOverride = CLIENT and self.ConVarsPanelOverride or nil
    self.SundryPanels = CLIENT and self.SundryPanels or nil

    self.TrackId = self.TrackId or 0
    
    if not isfunction(self.Check) then
        error(string.format('Invalid field "Check" = "%s" (not a function)', self.Check))
    end

    if not isfunction(self.Start) then
        error(string.format('Invalid field "Start" = "%s" (not a function)', self.Start))
    end

    if not isfunction(self.Think) then
        error(string.format('Invalid field "Think" = "%s" (not a function)', self.Think))
    end
    
    if not isfunction(self.Clear) then
        error(string.format('Invalid field "Clear" = "%s" (not a function)', self.Clear))
    end

    if new then hook.Run('UParRegisterAction', name, self) end
    
    return self
end


function UPAction:InitCVarDisabled(default)
    local cvName = sanitizeConVarName(self.Name) .. '_disabled'
    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}

    local cvar = CreateConVar(cvName, default and '1' or '0', cvFlags, '')
    self.CV_Disabled = cvar
end

function UPAction:GetDisabled()
    if not self.CV_Disabled then return nil end
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

if CLIENT then
    function UPAction:InitCVarKeybind(default)
        local cvName = sanitizeConVarName(self.Name) .. '_keybind'
        local cvar = CreateClientConVar(cvName, tostring(default), true, false, '')

        self.CV_Keybind = cvar
    end

    function UPAction:GetKeybind()
        if not self.CV_Keybind then return nil end
        local keybind = self.CV_Keybind:GetString()
        local keys = util.JSONToTable(keybind)
        return istable(keys) and keys or {}
    end

    function UPAction:SetKeybind(keys) 
        local val = nil
        if isstring(keys) then
            val = keys
        elseif istable(keys) and table.IsSequential(keys) then
            val = util.TableToJSON(keys) or '[0]'
        else
            error(string.format('Invalid keys "%s" (not a string or sequential table)', keys))
        end

        self.CV_Keybind:SetString(val)
    end
end

function UPAction:AddConVar(cvCfg)
    if not istable(cvCfg) then
        error(string.format('Invalid cvCfg "%s" (not a table)', cvCfg))
    end

    self.ConVars = istable(self.ConVars) and self.ConVars or {}
    
    local cvName = cvCfg.name
    local cvDefault = cvCfg.default or '0'
    local isclient = cvCfg.client

    if not isstring(cvName) then
        error(string.format('Invalid field "name" (not a string), name = "%s"', cvName))
    end

    if not isstring(cvDefault) then
        error(string.format('Invalid field "default" (not a string), name = "%s"', cvName))
    end

    if isclient ~= nil and not isbool(isclient) then
        error(string.format('Invalid field "client" (must be a boolean or nil), name = "%s"', cvName))
    end

    if isclient == nil then
        self.ConVars[cvName] = CreateConVar(cvName, cvDefault, { FCVAR_ARCHIVE, FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
    elseif SERVER and isclient == false then
        self.ConVars[cvName] = CreateConVar(cvName, cvDefault, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
    elseif CLIENT and isclient == true then
        self.ConVars[cvName] = CreateClientConVar(cvName, cvDefault, true, false) 
    end

    if SERVER then
        self.ConVarsWidget = nil
    elseif CLIENT then
        self.ConVarsWidget = istable(self.ConVarsWidget) and self.ConVarsWidget or {}
        table.insert(self.ConVarsWidget, cvCfg) 
    end
end

function UPAction:RemoveConVar(cvName)
    if not isstring(cvName) then
        error(string.format('Invalid cvName "%s" (not a string)', cvName))
    end

    self.ConVarsWidget = CLIENT and (istable(self.ConVarsWidget) and self.ConVarsWidget or {}) or nil
    self.ConVars = istable(self.ConVars) and self.ConVars or {}
    
    self.ConVars[cvName] = nil
    if CLIENT then
        for i = #self.ConVarsWidget, 1, -1 do
            if self.ConVarsWidget[i].name == cvName then
                table.remove(self.ConVarsWidget, i)
            end
        end
    end
end

function UPAction:InitConVars(config)
    if not istable(config) then
        error(string.format('Invalid config "%s" (not a table)', config))
    end

    self.ConVars = {}
    self.ConVarsWidget = CLIENT and {} or nil

    for i, v in ipairs(config) do self:AddConVar(v) end
end

if CLIENT then
    function UPAction:RegisterPreset(name, preset)
        if not isstring(name) then
            error(string.format('Invalid name "%s" (not a string)', name))
        end

        if not istable(preset) then
            error(string.format('Invalid preset "%s" (not a table)', preset))
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

        self.ConVarsPreset = istable(self.ConVarsPreset) and self.ConVarsPreset or {}

        self.ConVarsPreset[name] = preset
    end
end

UPar.GetAllActions = function() return Instances end
UPar.GetAction = function(name) return Instances[name] end
UPar.isupaction = isupaction

