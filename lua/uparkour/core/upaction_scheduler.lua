--[[
	作者:白狼
	2025 11 5
--]]
local SeqHookRun = UPar.SeqHookRun
local emptyTable = UPar.emptyTable
local EffInstances = UPar.EffInstances
local DeepClone = UPar.DeepClone

local function GetPlayerUsingEffect(ply, actName)
	if actName == nil then
		print(string.format('[UPar]: Warning: GetPlayerUsingEffect: actName is nil'))
		return nil
	end

    local effName = ply.upeff_cfg[actName] or 'default'
    if effName == 'CACHE' then
        return ply.upeff_cache[actName]
    else
        return EffInstances[actName][effName]
    end
end


local function ActStart(ply, action, checkResult)
	local actName = action.Name
	action:Start(ply, checkResult)

	local resultCopy = DeepClone(checkResult)

	local effect = GetPlayerUsingEffect(ply, actName)
	if effect then effect:Start(ply, resultCopy) end

	SeqHookRun('UParActStartOut_' .. actName, ply, resultCopy)
	SeqHookRun('UParActStartOut', actName, ply, resultCopy)
end

local function ActClear(ply, playing, playingData, mv, cmd, external)
	local playingName = playing.Name
	playing:Clear(ply, playingData, mv, cmd, external)

	local resultCopy = DeepClone(playingData)

	local effect = GetPlayerUsingEffect(ply, playingName)
	if effect then effect:Clear(ply, playingData, external) end

	SeqHookRun('UParClearOut_' .. playingName, ply, playingData, mv, cmd, external)
	SeqHookRun('UParClearOut', playingName, ply, playingData, mv, cmd, external)
end

local START_FLAG = 0
local CLEAR_FLAG = 1
local INTERRUPT_FLAG = 2
local RHYTHM_FLAG = 3
local END_FLAG = 4

UPar.GetPlayerUsingEffect = GetPlayerUsingEffect

UPar.ActStart = ActStart
UPar.ActClear = ActClear

local GetAction = UPar.GetAction
if SERVER then
    util.AddNetworkString('UParCallClientAction')
	util.AddNetworkString('UParStart')

	local function Trigger(ply, action, data, checkResult)
        if not IsValid(ply) or not ply:IsPlayer() then
            error('Invalid ply\n') 
        end

		if action:GetDisabled() then
			return
		end

		local actName = action.Name
		local trackId = action.TrackId
		local playing, playingData = unpack(ply.uptracks[trackId] or emptyTable)

		if playing and not SeqHookRun('UParInterrupt', ply, playing, playingData, action) then
			return
		end

		checkResult = checkResult or action:Check(ply, data)
		if not istable(checkResult) or SeqHookRun('UParPreStart', ply, action, checkResult) then
			return
		end

		net.Start('UParCallClientAction')
		if playing then
			ply.uptracks[trackId] = nil

			local succ, err = pcall(ActClear, ply, playing, playingData, nil, nil, action, checkResult)
			if not succ then
				ErrorNoHaltWithStack(err)
			end

			net.WriteInt(CLEAR_FLAG, 3)
			net.WriteTable({playing.Name, playingData, actName})
		end

		local succ, err = pcall(ActStart, ply, action, checkResult)
		if not succ then
			ErrorNoHaltWithStack(err)
		end

		net.WriteInt(START_FLAG, 3)
		net.WriteTable({actName, checkResult})

		ply.uptracks[trackId] = {action, checkResult}

		net.WriteInt(END_FLAG, 3)
        net.Send(ply)

		return checkResult
	end

	local function ForceEnd(ply, trackId)
		local playing, playingData = unpack(ply.uptracks[trackId] or emptyTable)

		ply.uptracks[trackId] = nil

		local succ, err = pcall(ActClear, ply, playing, playingData, nil, nil, true, nil)
		if not succ then
			ErrorNoHaltWithStack(err)
		end

		net.Start('UParCallClientAction')
			net.WriteInt(CLEAR_FLAG, 3)
			net.WriteTable({playing.Name, playingData, true})
			net.WriteInt(END_FLAG, 3)
		net.Send(ply)
	end

	local function ForceEndAll(ply)
		local netData = {}

		net.Start('UParCallClientAction')
		for trackId, trackContent in pairs(ply.uptracks or emptyTable) do
			local playing, playingData = unpack(trackContent or emptyTable)

			ply.uptracks[trackId] = nil

			local succ, err = pcall(ActClear, ply, playing, playingData, nil, nil, true, nil)
			if not succ then
				ErrorNoHaltWithStack(err)
			end

			net.WriteInt(CLEAR_FLAG, 3)
			net.WriteTable({playing.Name, playingData, true}, true)
		end

		
		net.WriteInt(END_FLAG, 3)
		net.Send(ply)
	end

	UPar.ForceEnd = ForceEnd
	UPar.ForceEndAll = ForceEndAll

	UPar.Trigger = Trigger
	UPar.CallClientAction = CallClientAction

	net.Receive('UParStart', function(len, ply)
		local actName = net.ReadString()
		local checkResult = net.ReadTable()

		local action = GetAction(actName)
		if not action then 
			return 
		end

		Trigger(ply, action, nil, checkResult)
	end)

	hook.Add('SetupMove', 'upar.think', function(ply, mv, cmd)
		for trackId, trackContent in pairs(ply.uptracks or emptyTable) do
			local action, checkResult = unpack(trackContent or emptyTable)

			if not action then
				continue
			end

			local succ, err = pcall(action.Think, action, ply, mv, cmd, checkResult)
			if not succ then
				ForceEnd(ply, trackId)
				error(string.format('action named "%s" Think error: %s\n', action.Name, err))
			end

			local toclear = err
			if not toclear then
				continue
			end

			ply.uptracks[trackId] = nil
			
			succ, err = pcall(ActClear, ply, action, checkResult, mv, cmd, nil, nil)
			if not succ then
				ErrorNoHaltWithStack(err)
			end

			local netData = {
				{
					method = 'Clear',
					actName = action.Name,
					args = checkResult,
					iactName = nil,
					iargs = nil,
				}
			}

			net.Start('UParCallClientAction')
				net.WriteTable(netData)
			net.Send(ply)
		end
	end)

	hook.Add('PlayerInitialSpawn', 'upar.init.tracks', function(ply)
		ply.uptracks = {}
	end)

	hook.Add('PlayerSpawn', 'upar.clear', ForceEndAll)
	hook.Add('PlayerDeath', 'upar.clear', ForceEndAll)
	hook.Add('PlayerSilentDeath', 'upar.clear', ForceEndAll)
elseif CLIENT then
	UPar.Trigger = function(ply, action, data, checkResult)
		if action:GetDisabled() then
			return
		end

		local actName = action.Name
		
		checkResult = checkResult or action:Check(ply, data)
		if not istable(checkResult) then
			return
		end

		net.Start('UParStart')
			net.WriteString(actName)
			net.WriteTable(checkResult)
		net.SendToServer()

		return checkResult
	end

	local MoveControl = {
		enable = false,
		ClearMovement = false,
		RemoveKeys = 0,
		AddKeys = 0,
	}
	
	hook.Add('CreateMove', 'upar.move.control', function(cmd)
		if not MoveControl.enable then return end
		if MoveControl.ClearMovement then
			cmd:ClearMovement()
		end

		local RemoveKeys = MoveControl.RemoveKeys
		if isnumber(RemoveKeys) and RemoveKeys ~= 0 then
			cmd:RemoveKey(RemoveKeys)
		end

		local AddKeys = MoveControl.AddKeys
		if isnumber(AddKeys) and AddKeys ~= 0 then
			cmd:AddKey(AddKeys)
		end
	end)

	UPar.MoveControl = MoveControl
	UPar.SetMoveControl = function(enable, clearMovement, removeKeys, addKeys)
		MoveControl.enable = enable
		MoveControl.ClearMovement = clearMovement
		MoveControl.RemoveKeys = removeKeys
		MoveControl.AddKeys = addKeys
	end

    net.Receive('UParCallClientAction', function()
        local data = net.ReadTable()
		local ply = LocalPlayer()

        for _, v in ipairs(data) do
			local action = GetAction(v.actName)
			local checkResult = v.args
			if not action then 
				continue 
			end

			if v.method == 'Start' then
				local succ, err = pcall(ActStart, ply, action, checkResult)
				if not succ then
					ErrorNoHaltWithStack(err)
				end
			elseif v.method == 'Clear' then
				local iactName = v.iactName
				local interruptSource = isbool(iactName) and iactName or GetAction(iactName)
				local interruptData = v.iargs
				local succ, err = pcall(ActClear, ply, action, checkResult, nil, nil, interruptSource, interruptData)
				if not succ then
					ErrorNoHaltWithStack(err)
				end
			elseif v.method == 'ChangeRhythm' then
	
			end
        end
    end)
end