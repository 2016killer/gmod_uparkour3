--[[
	作者:白狼
	2025 12 22
--]]

UPar.ActKeyPress = {}
UPar.ACT_KEY_EVENT_FLAGS = {
    UNHANDLED = 0,
    HANDLED = 1,
    SKIPPED = 2
}


local FLAGS_UNHANDLED = UPar.ACT_KEY_EVENT_FLAGS.UNHANDLED
local FLAGS_HANDLED = UPar.ACT_KEY_EVENT_FLAGS.HANDLED
local FLAGS_SKIPPED = UPar.ACT_KEY_EVENT_FLAGS.SKIPPED

local ActKeyPress = UPar.ActKeyPress
local ActInstances = UPar.ActInstances
local SeqHookRunAllSafe = UPar.SeqHookRunAllSafe

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

    local PressedActs = {}
    local ReleasedActs = {}
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
                PressedActs[actName] = FLAGS_UNHANDLED
            elseif not pressAll and ActKeyPress[actName] then
                ReleasedActs[actName] = FLAGS_UNHANDLED
            end

            ActKeyPress[actName] = pressAll
        end
    end

    if not table.IsEmpty(PressedActs) then
        SeqHookRunAllSafe('UParActKeyPress', PressedActs)
    end

    if not table.IsEmpty(ReleasedActs) then
        SeqHookRunAllSafe('UParActKeyRelease', ReleasedActs)
    end
end)

UPar.ClearKeyPress = function()
    ActKeyPress = {}
    UPar.ActKeyPress = ActKeyPress
end
