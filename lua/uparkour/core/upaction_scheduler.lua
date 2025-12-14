--[[
	作者:白狼
	2025 11 5
--]]
local SeqHookRun = UPar.SeqHookRun
local emptyTable = UPar.emptyTable

local function ActStart(ply, action, checkResult)
	local prevent = SeqHookRun('UParStart', ply, action, checkResult)
	if not prevent then
		action:Start(ply, checkResult)
		local effect = action:GetPlayerUsingEffect(ply)
		if effect then effect:Start(ply, checkResult) end
	end
end

local function ActClear(ply, playing, playingData, mv, cmd, interruptSource, interruptData)
	local prevent = SeqHookRun('UParClear', ply, playing, playingData, mv, cmd, interruptSource, interruptData)
	if not prevent then
		playing:Clear(ply, playingData, mv, cmd, interruptSource, interruptData)
		local effect = playing:GetPlayerUsingEffect(ply)
		if effect then effect:Clear(ply, playingData, interruptSource, interruptData) end
	end
end

local function ActChangeRhythm(ply, action, customData)
	local effect = action:GetPlayerUsingEffect(ply)
	local prevent = SeqHookRun('UParOnChangeRhythm', ply, action, effect, customData)
	if not prevent and effect then
		effect:OnRhythmChange(ply, customData)
	end

	if SERVER then
		local netData = {
			{
				method = 'ChangeRhythm',
				actName = action.Name,
				args = customData,
			}
		}

		net.Start('UParCallClientAction')
			net.WriteTable(netData)
		net.Send(ply)
	end
end

UPar.ActChangeRhythm = ActChangeRhythm
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

		local netData = {}
		if playing then
			ply.uptracks[trackId] = nil

			ActClear(ply, playing, playingData, nil, nil, action, checkResult)

			table.insert(netData, {
				method = 'Clear',
				actName = playing.Name,
				args = playingData,
				iactName = action.Name,
				iargs = checkResult,
			})
		end

		ActStart(ply, action, checkResult)

		ply.uptracks[trackId] = {action, checkResult}

		table.insert(netData, {
			method = 'Start',
			actName = actName,
			args = checkResult,
		})
	
        net.Start('UParCallClientAction')
            net.WriteTable(netData)
        net.Send(ply)

		return checkResult
	end

	local function ForceEnd(ply, trackId)
		local playing, playingData = unpack(ply.uptracks[trackId] or emptyTable)

		ply.uptracks[trackId] = nil

		ActClear(ply, playing, playingData, nil, nil, true, nil)

		local netData = {
			{
				method = 'Clear',
				actName = playing.Name,
				args = playingData,
				iactName = true,
				iargs = nil,
			}
		}

		net.Start('UParCallClientAction')
			net.WriteTable(netData)
		net.Send(ply)
	end

	local function ForceEndAll(ply)
		local netData = {}
		for trackId, trackContent in pairs(ply.uptracks or emptyTable) do
			local playing, playingData = unpack(trackContent or emptyTable)

			ply.uptracks[trackId] = nil

			ActClear(ply, playing, playingData, nil, nil, true, nil)

			table.insert(netData, {
				method = 'Clear',
				actName = playing.Name,
				args = playingData,
				iactName = true,
				iargs = nil,
			})
		end

		net.Start('UParCallClientAction')
			net.WriteTable(netData)
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
			
			ActClear(ply, action, checkResult, mv, cmd, nil, nil)

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
				ActStart(ply, action, checkResult)
			elseif v.method == 'Clear' then
				local iactName = v.iactName
				local interruptSource = isbool(iactName) and iactName or GetAction(iactName)
				local interruptData = v.iargs
				ActClear(ply, action, checkResult, nil, nil, interruptSource, interruptData)
			elseif v.method == 'ChangeRhythm' then
				local customData = checkResult
				ActChangeRhythm(ply, action, customData)
			end
        end
    end)
end