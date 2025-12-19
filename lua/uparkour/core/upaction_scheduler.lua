--[[
	作者:白狼
	2025 11 5
--]]
local SeqHookRun = UPar.SeqHookRun
local emptyTable = UPar.emptyTable
local ActInstances = UPar.ActInstances
local EffInstances = UPar.EffInstances
local DeepClone = UPar.DeepClone

local START_FLAG = 1
local CLEAR_FLAG = 2
local INTERRUPT_FLAG = 3
local RHYTHM_FLAG = 4
local END_FLAG = 5
local BIT_COUNT = 4
local MAX_ACT_EVENT = 20

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

	local effect = GetPlayerUsingEffect(ply, actName)
	if effect then effect:Start(ply, checkResult) end

	SeqHookRun('UParActStartOut_' .. actName, ply, checkResult, action.TrackId)
	SeqHookRun('UParActStartOut', actName, ply, checkResult, action.TrackId)
end

local function ActClear(ply, playing, playingData, mv, cmd, interruptSource)
	local playingName = playing.Name
	playing:Clear(ply, playingData, mv, cmd, interruptSource)

	local effect = GetPlayerUsingEffect(ply, playingName)
	if effect then effect:Clear(ply, playingData, interruptSource) end

	SeqHookRun('UParActClearOut_' .. playingName, ply, playingData, mv, cmd, interruptSource, playing.TrackId)
	SeqHookRun('UParActClearOut', playingName, ply, playingData, mv, cmd, interruptSource, playing.TrackId)
end

local function ActEffRhythmChange(ply, action, customData)
	local actName = action.Name

	if SERVER then
		net.Start('UParCallClientAction')
			net.WriteInt(RHYTHM_FLAG, BIT_COUNT)
			net.WriteTable({actName, customData})
			net.WriteInt(END_FLAG, BIT_COUNT)
		net.Send(ply)
	end

	local effect = GetPlayerUsingEffect(ply, actName)
	if effect then effect:Rhythm(ply, customData) end

	SeqHookRun('UParActEffRhythmChange_' .. actName, ply, effect, customData)
	SeqHookRun('UParActEffRhythmChange', actName, ply, effect, customData)
end

UPar.GetPlayerUsingEffect = GetPlayerUsingEffect

UPar.ActStart = ActStart
UPar.ActClear = ActClear
UPar.ActEffRhythmChange = ActEffRhythmChange

if SERVER then
    util.AddNetworkString('UParCallClientAction')
	util.AddNetworkString('UParStart')

	local function Trigger(ply, actName, data, checkResult)
        if not IsValid(ply) or not ply:IsPlayer() then
            error('Invalid ply\n') 
        end

		local action = ActInstances[actName]
		if not action then
			error(string.format('act named %s is not found', actName))
		end

		if action.CV_Disabled and action.CV_Disabled:GetBool() then
			return
		end

		local trackId = action.TrackId
		local playing, playingData, playingName = unpack(ply.uptracks[trackId] or emptyTable)
	

		if playing then
			if not (SeqHookRun('UParActAllowInterrupt_' .. playingName, ply, playingData, actName)
			or SeqHookRun('UParActAllowInterrupt', playingName, ply, playingData, actName)) then
				return
			end
		end

		checkResult = checkResult or action:Check(ply, data)
		if not istable(checkResult) then
			return
		else
			if SeqHookRun('UParActPreStartValidate_' .. actName, ply, checkResult) 
			or SeqHookRun('UParActPreStartValidate', actName, ply, checkResult) then
				return
			end
		end

		net.Start('UParCallClientAction')
		if playing then
			ply.uptracks[trackId] = nil

			net.WriteInt(CLEAR_FLAG, BIT_COUNT)
			net.WriteTable({playing.Name, playingData, actName})

			local succ, err = pcall(ActClear, ply, playing, playingData, nil, nil, actName)
			if not succ then
				ErrorNoHaltWithStack(err)
			end
		end

		net.WriteInt(START_FLAG, BIT_COUNT)
		net.WriteTable({actName, checkResult})
		
		local succ, err = pcall(ActStart, ply, action, checkResult)
		if not succ then
			ErrorNoHaltWithStack(err)
			net.WriteInt(CLEAR_FLAG, BIT_COUNT)
			net.WriteTable({actName, checkResult, true})
		end

		net.WriteInt(END_FLAG, BIT_COUNT)
        net.Send(ply)

		ply.uptracks[trackId] = {action, checkResult, actName}

		return checkResult
	end

	local function ForceEnd(ply, trackId)
		local playing, playingData, playingName = unpack(ply.uptracks[trackId] or emptyTable)

		ply.uptracks[trackId] = nil

		if not playing then
			return
		end
		net.Start('UParCallClientAction')
		net.WriteInt(CLEAR_FLAG, BIT_COUNT)
		net.WriteTable({playingName, playingData, true})

		local succ, err = pcall(ActClear, ply, playing, playingData, nil, nil, true)
		if not succ then
			ErrorNoHaltWithStack(err)
		end

		net.WriteInt(END_FLAG, BIT_COUNT)
		net.Send(ply)
	end

	local function ForceEndAll(ply)
		local netData = {}

		net.Start('UParCallClientAction')
		for trackId, trackContent in pairs(ply.uptracks or emptyTable) do
			local playing, playingData, playingName = unpack(trackContent or emptyTable)

			ply.uptracks[trackId] = nil

			if not playing then
				continue
			end

			net.WriteInt(CLEAR_FLAG, BIT_COUNT)
			net.WriteTable({playingName, playingData, true})

			local succ, err = pcall(ActClear, ply, playing, playingData, nil, nil, true)
			if not succ then
				ErrorNoHaltWithStack(err)
			end
		end

		net.WriteInt(END_FLAG, BIT_COUNT)
		net.Send(ply)
	end

	UPar.ForceEnd = ForceEnd
	UPar.ForceEndAll = ForceEndAll

	UPar.Trigger = Trigger

	net.Receive('UParStart', function(len, ply)
		local actName = net.ReadString()
		local checkResult = net.ReadTable()

		Trigger(ply, actName, nil, checkResult)
	end)

	hook.Add('SetupMove', 'upar.think', function(ply, mv, cmd)
		for trackId, trackContent in pairs(ply.uptracks or emptyTable) do
			local action, checkResult, actName = unpack(trackContent or emptyTable)

			if not action then
				continue
			end

			local succ, err = pcall(action.Think, action, ply, mv, cmd, checkResult)
			if not succ then
				ForceEnd(ply, trackId)
				error(string.format('action named "%s" Think error: %s\n', actName, err))
			end

			local toclear = err
			if not toclear then
				continue
			end

			ply.uptracks[trackId] = nil
			
			net.Start('UParCallClientAction')
			net.WriteInt(CLEAR_FLAG, BIT_COUNT)
			net.WriteTable({actName, checkResult, false})

			succ, err = pcall(ActClear, ply, action, checkResult, mv, cmd, false)
			if not succ then
				ErrorNoHaltWithStack(err)
			end

			net.WriteInt(END_FLAG, BIT_COUNT)
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
	UPar.Trigger = function(ply, actName, data, checkResult)
        if not IsValid(ply) or not ply:IsPlayer() then
            error('Invalid ply\n') 
        end

		local action = ActInstances[actName]
		if not action then
			print(string.format('act named "%s" is not found', actName))
			return
		end

		if action.CV_Disabled and action.CV_Disabled:GetBool() then
			return
		end
		
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
		if not MoveControl.enable then 
			return 
		end

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
		MoveControl.RemoveKeys = isnumber(removeKeys) and removeKeys or 0
		MoveControl.AddKeys = isnumber(addKeys) and addKeys or 0
	end

    net.Receive('UParCallClientAction', function()
		local ply = LocalPlayer()

		for i = 1, MAX_ACT_EVENT do
			local flag = net.ReadInt(BIT_COUNT)

			if flag == END_FLAG or flag == 0 then
				break
			end
			
			local batch = net.ReadTable()
			local actName = batch[1]
			local checkResult = batch[2]
			local action = ActInstances[actName]

			if not action then
				print(string.format('[UPar]: cl_act: act named %s is not found', actName))
				continue
			end

			if flag == START_FLAG then
				local succ, err = pcall(ActStart, ply, action, checkResult)
				if not succ then
					ErrorNoHaltWithStack(err)
					succ, err = pcall(ActClear, ply, action, checkResult, nil, nil, true)
					if not succ then
						ErrorNoHaltWithStack(err)
					end
				end
			elseif flag == CLEAR_FLAG then
				local interruptSource = batch[3]
		
				local succ, err = pcall(ActClear, ply, action, checkResult, nil, nil, interruptSource)
				if not succ then
					ErrorNoHaltWithStack(err)
				end
			elseif flag == RHYTHM_FLAG then
				local customData = checkResult
				local succ, err = pcall(ActEffRhythmChange, ply, action, customData)
				if not succ then
					ErrorNoHaltWithStack(err)
				end
			end
		end
    end)
end