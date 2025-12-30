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
local MAX_ACT_EVENT = 50

local function GetPlyUsingEffect(ply, actName)
	if actName == nil then
		print(string.format('[UPar]: Warning: GetPlyUsingEffect: actName is nil'))
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

	local effect = GetPlyUsingEffect(ply, actName)
	if effect then effect:Start(ply, checkResult) end

	SeqHookRun('UParActStartOut_' .. actName, ply, checkResult, action.TrackId)
	SeqHookRun('UParActStartOut', actName, ply, checkResult, action.TrackId)
end

local function ActClear(ply, playing, playingData, mv, cmd, interruptSource)
	local playingName = playing.Name
	playing:Clear(ply, playingData, mv, cmd, interruptSource)

	local effect = GetPlyUsingEffect(ply, playingName)
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

	local effect = GetPlyUsingEffect(ply, actName)
	if effect then effect:Rhythm(ply, customData) end

	SeqHookRun('UParActEffRhythmChange_' .. actName, ply, effect, customData)
	SeqHookRun('UParActEffRhythmChange', actName, ply, effect, customData)
end

UPar.GetPlyUsingEffect = GetPlyUsingEffect

UPar.ActStart = ActStart
UPar.ActClear = ActClear
UPar.ActEffRhythmChange = ActEffRhythmChange

UPar.CallAct = function(actName, methodName, ...)
    local action = ActInstances[actName]
    if not action then
		print(string.format('not found act named "%s"', actName))
		return
    end

    local method = action[methodName]
    if not isfunction(method) then
		print(string.format('not found method "%s" in act "%s"', methodName, actName))
		return
    end

	return method(action, ...)
end

UPar.GetActKV = function(actName, key)
    local action = ActInstances[actName]
    if not action then
		print(string.format('not found act named "%s"', actName))
		return
    end

	return action[key]
end

UPar.CallEff = function(actName, effName, methodName, ...)
    local effects = EffInstances[actName]
    if not effects then
		print(string.format('not found effs in act "%s"', actName))
		return
    end

    local effect = effects[effName]
    if not effect then
		print(string.format('not found eff "%s" in act "%s"', effName, actName))
		return
    end

    local method = effect[methodName]
    if not isfunction(method) then
		print(string.format('not found method "%s" in eff "%s" of act "%s"', methodName, effName, actName))
		return
    end

	return method(effect, ...)
end

UPar.GetEffKV = function(actName, effName, key)
    local effects = EffInstances[actName]
    if not effects then
		print(string.format('not found effs in act "%s"', actName))
		return
    end

    local effect = effects[effName]
    if not effect then
		print(string.format('not found eff "%s" in act "%s"', effName, actName))
		return
    end

	return effect[key]
end

UPar.CallPlyUsingEff = function(actName, methodName, ply, ...)
    local effect = GetPlyUsingEffect(ply, actName)
    if not effect then
		print(string.format('not found eff "USING" in act "%s" for ply "%s"', actName, ply))
		return
    end

    local method = effect[methodName]
    if not isfunction(method) then
		print(string.format('not found method "%s" in eff "USING" act "%s" for ply "%s"', methodName, actName, ply))
		return
    end

	return method(effect, ...)
end

UPar.GetPlyUsingEffKV = function(actName, key, ply)
    local effect = GetPlyUsingEffect(ply, actName)
    if not effect then
		print(string.format('not found eff "USING" in act "%s" for ply "%s"', actName, ply))
		return
    end

	return effect[key]
end


if SERVER then
    util.AddNetworkString('UParCallClientAction')
	util.AddNetworkString('UParStart')

	local function Trigger(ply, actName, checkResult, ...)
        if not IsValid(ply) or not ply:IsPlayer() then
			print(string.format('Invalid ply "%s"', ply))
			return
        end

		local action = ActInstances[actName]
		if not action then
			print(string.format('not found act named "%s"', actName))
			return
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

		checkResult = checkResult or action:Check(ply, ...)
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

	local function RemoveTracks(ply, removeData, mv, cmd)
		if #removeData < 1 then
			return
		end

		if #removeData > MAX_ACT_EVENT then
			ErrorNoHaltWithStack(string.format('[UPar]: Warning: RemoveTracks: removeData count is %d, max is %d', #removeData, MAX_ACT_EVENT))
			return
		end

		for i = #removeData, 1, -1 do
			local trackId, trackContent, reason = unpack(removeData[i])
			if trackContent ~= ply.uptracks[trackId] then
				print(string.format('[UPar]: Warning: track "%s" content changed in other place', trackId))
				table.remove(removeData, i)
			else
				ply.uptracks[trackId] = nil
			end
		end

		for _, v in ipairs(removeData) do
			local _, trackContent, reason = unpack(v)
			local playing, playingData, _ = unpack(trackContent or emptyTable)

			if not playing then
				continue
			end

			local succ, err = pcall(ActClear, ply, playing, playingData or emptyTable, mv, cmd, reason or false)
			if not succ then
				ErrorNoHaltWithStack(err)
			end
		end

		net.Start('UParCallClientAction')
		for _, v in ipairs(removeData) do
			local _, trackContent, reason = unpack(v)
			local _, playingData, playingName = unpack(trackContent or emptyTable)

			if not playingName then
				continue
			end
			net.WriteInt(CLEAR_FLAG, BIT_COUNT)
			net.WriteTable({playingName, playingData or emptyTable, reason or false})
		end
		net.WriteInt(END_FLAG, BIT_COUNT)
		net.Send(ply)
	end

	local function ForceEndTarget(ply, target)
		ply.uptracks = istable(ply.uptracks) and ply.uptracks or {}
		target = istable(target) and target or emptyTable
		local removeData = {}
		for _, trackId in pairs(target) do
			local trackContent = ply.uptracks[trackId]
			if not trackContent then continue end
			table.insert(removeData, {trackId, trackContent, true})
		end

		RemoveTracks(ply, removeData, nil, nil)
	end

	local function ForceEndAllExcept(ply, filter)
		ply.uptracks = istable(ply.uptracks) and ply.uptracks or {}
		filter = istable(filter) and filter or emptyTable
		local removeData = {}
		for trackId, trackContent in pairs(ply.uptracks) do
			if filter[trackId] then continue end
			table.insert(removeData, {trackId, trackContent, true})
		end

		RemoveTracks(ply, removeData, nil, nil)
	end

	UPar.ForceEndTarget = ForceEndTarget
	UPar.ForceEndAllExcept = ForceEndAllExcept
	UPar.RemoveTracks = RemoveTracks
	UPar.Trigger = Trigger

	net.Receive('UParStart', function(len, ply)
		local actName = net.ReadString()
		local checkResult = net.ReadTable()

		local action = ActInstances[actName]
		if not action then
			print(string.format('not found act named "%s"', actName))
			return
		end

		if not action:OnValCltPredRes(ply, checkResult) then
			print(string.format('act named "%s" OnValCltPredRes failed, %s', actName, ply))
			return
		end

		Trigger(ply, actName, checkResult)
	end)

	hook.Add('SetupMove', 'upar.think', function(ply, mv, cmd)
		local removeData = {}
		for trackId, trackContent in pairs(ply.uptracks or emptyTable) do
			local action, checkResult, actName = unpack(trackContent or emptyTable)

			if not action then
				continue
			end

			local succ, result = pcall(action.Think, action, ply, checkResult, mv, cmd)
			if not succ then
				ErrorNoHaltWithStack(result)
				table.insert(removeData, {trackId, trackContent, true})
			elseif result then
				table.insert(removeData, {trackId, trackContent, false})
			end
		end

		RemoveTracks(ply, removeData, mv, cmd)
	end)

	hook.Add('PlayerInitialSpawn', 'upar.init.tracks', function(ply)
		ply.uptracks = {}
	end)

	hook.Add('PlayerSpawn', 'upar.clear', ForceEndAllExcept)
	hook.Add('PlayerDeath', 'upar.clear', ForceEndAllExcept)
	hook.Add('PlayerSilentDeath', 'upar.clear', ForceEndAllExcept)
elseif CLIENT then
	UPar.Trigger = function(ply, actName, checkResult, ...)
        if not IsValid(ply) or not ply:IsPlayer() then
			print(string.format('Invalid ply "%s"', ply))
			return
        end

		local action = ActInstances[actName]
		if not action then
			print(string.format('not found act named "%s"', actName))
			return
		end

		if action.CV_Disabled and action.CV_Disabled:GetBool() then
			return
		end
		
		checkResult = checkResult or action:Check(ply, ...)
		if not istable(checkResult) then
			return
		else
			if SeqHookRun('UParActPreStartValidate_' .. actName, ply, checkResult) 
			or SeqHookRun('UParActPreStartValidate', actName, ply, checkResult) then
				return
			end
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

	local function SetMoveControl(enable, clearMovement, removeKeys, addKeys, timeout)
		MoveControl.enable = enable
		MoveControl.ClearMovement = clearMovement
		MoveControl.RemoveKeys = isnumber(removeKeys) and removeKeys or 0
		MoveControl.AddKeys = isnumber(addKeys) and addKeys or 0

		if enable then
			if isnumber(timeout) then
				timer.Create('UParMoveControl', math.abs(timeout), 1, function()
					print('MoveControl timeout')
					SetMoveControl(false, false, 0, 0)
				end)
			end
		else
			timer.Remove('UParMoveControl')
		end
	end

	UPar.MoveControl = MoveControl
	UPar.SetMoveControl = SetMoveControl

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
				local interruptSource = batch[3] or false
		
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