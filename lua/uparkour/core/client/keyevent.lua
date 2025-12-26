--[[
	作者:白狼
	2025 12 22
--]]

UPKeyboard = UPKeyboard or {}
UPKeyboard.KEY_EVENT_FLAGS = {
    UNHANDLED = 0,
    HANDLED = 1,
    SKIPPED = 2
}

UPKeyboard.KeyState = UPKeyboard.KeyState or {}
UPKeyboard.KeySet = UPKeyboard.KeySet or {}

local FLAGS_UNHANDLED = UPKeyboard.KEY_EVENT_FLAGS.UNHANDLED
local FLAGS_HANDLED = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
local FLAGS_SKIPPED = UPKeyboard.KEY_EVENT_FLAGS.SKIPPED

local KeyState = UPKeyboard.KeyState
local KeySet = UPKeyboard.KeySet
local SeqHookRunAllSafe = UPar.SeqHookRunAllSafe

local nextThinkTime = 0
local interval = 0.03

local function Register(flag, label, default)
    assert(isstring(flag), string.format('Invalid flag "%s" (not a string)', flag))
    assert(not string.find(flag, '[\\/:*?"<>|]'), string.format('Invalid flag "%s" (contains invalid filename characters)', flag))

    local cvName = 'upkey_' .. string.gsub(flag, '[\\/:*?"<>|]', '_')
    local cvar = CreateClientConVar(cvName, default, true, false, '')

    KeySet[flag] = {
        label = isstring(label) and label or flag,
        cvar = cvar
    }

    hook.Run('UParRegisterKey', flag, label, default)
end

local function GetKeys(flag)
    if not KeySet[flag] then return nil end
    local keys = util.JSONToTable(KeySet[flag]:GetString())
    return istable(keys) and keys or nil
end

local function SetKeys(flag, keys)
    local val = nil
    if isstring(keys) then
        val = keys
    elseif istable(keys) and table.IsSequential(keys) then
        val = util.TableToJSON(keys) or '[0]'
    else
        print(string.format('[UPKeyEvent]: Invalid keys "%s" (not a string or sequential table)', keys))
        return
    end

    if not KeySet[flag] then Register(flag, flag, val) end

    KeySet[flag]:SetString(val)
end


hook.Add('Think', 'upar.key.event', function()
    local curTime = RealTime()
    if curTime < nextThinkTime then
        return
    end
    nextThinkTime = curTime + interval

    local PressedSet = {}
    local ReleasedSet = {}
    for flag, data in pairs(KeySet) do
        local keys = util.JSONToTable(data.cvar:GetString())

        if istable(keys) then
            local pressAll = #keys > 0

            // local temp = {flag}
            for _, keycode in ipairs(keys) do
                if not isnumber(keycode) then continue end
                pressAll = pressAll and (input.IsKeyDown(keycode) or input.IsMouseDown(keycode))
         
                // table.insert(temp, input.GetKeyName(keycode))
                // table.insert(temp, tostring(input.IsKeyDown(keycode) or input.IsMouseDown(keycode)))
            end

            // print(table.concat(temp, ' '))

            if pressAll and not KeyState[flag] then
                PressedSet[flag] = FLAGS_UNHANDLED
            elseif not pressAll and KeyState[flag] then
                ReleasedSet[flag] = FLAGS_UNHANDLED
            end

            KeyState[flag] = pressAll
        end
    end

    if not table.IsEmpty(PressedSet) then
        SeqHookRunAllSafe('UParKeyPress', PressedSet)
    end

    if not table.IsEmpty(ReleasedSet) then
        SeqHookRunAllSafe('UParKeyRelease', ReleasedSet)
    end
end)

UPKeyboard.ClearKeyState = function()
    KeyState = {}
    UPKeyboard.KeyState = KeyState
end