--[[
	作者:白狼
	2025 12 22
--]]

UPar.ActKeyPress = UPar.ActKeyPress or {}

local ActKeyPress = UPar.ActKeyPress
local ActInstances = UPar.ActInstances

local nextThinkTime = 0
local interval = GetConVar('up_act_keydt') and GetConVar('up_act_keydt'):GetFloat() or 0.03

CreateClientConVar('up_act_keydt', '0.03', true, false, '', 0, 1)
cvars.AddChangeCallback('up_act_keydt', function(_, _, newValue)
    interval = tonumber(newValue) or 0.03
end, 'interval')

hook.Add('Think', 'upar.key.event', function()
    local curTime = CurTime()
    if curTime < nextThinkTime then
        return
    end
    nextThinkTime = curTime + interval

    for actName, act in pairs(ActInstances) do
        local keybind = act:GetKeybind()
        if istable(keybind) then
            local pressAll = true
            for _, keycode in ipairs(keybind) do
                if not isnumber(keycode) then
                    continue
                end

                pressAll = pressAll and (input.IsKeyDown(keycode) or input.IsMouseDown(keycode))
            end

            if pressAll and not ActKeyPress[actName] then
                local success, err = pcall(act.OnKeyPress, act)
                if not success then ErrorNoHaltWithStack(err) end
            elseif not pressAll and ActKeyPress[actName] then
                local success, err = pcall(act.OnKeyRelease, act)
                if not success then ErrorNoHaltWithStack(err) end
            end

            ActKeyPress[actName] = pressAll
        end
    end
end)

UPar.ClearKeyPress = function()
    ActKeyPress = {}
    UPar.ActKeyPress = ActKeyPress
end
