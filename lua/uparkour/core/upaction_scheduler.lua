--[[
	作者:白狼
	2025 11 5
--]]
local SeqHookRun = UPar.SeqHookRun




if SERVER then
    util.AddNetworkString('UParCallClientAction')

    UPar.CallClientAction = function(ply, data)
        if not IsValid(ply) or not ply:IsPlayer() then
            error('Invalid ply\n') 
        end

        net.Start('UParCallClientAction')
            net.WriteTable(data)
        net.Send(ply)
    end

	util.AddNetworkString('UParStart')
	
	net.Receive('UParStart', function(len, ply)
		local actName = net.ReadString()
		local trackId = net.ReadString()
		local checkResult = net.ReadTable()

		local action = GetAction(actName)
		if not action then 
			return 
		end

		UPar.Trigger(ply, action, nil, checkResult, trackId)
	end)

elseif CLIENT then
    net.Receive('UParCallClientAction', function()
        local data = net.ReadTable()
		local ply = LocalPlayer()
        for _, v in ipairs(data) do
			local action = UPar.GetAction(v.actName)
			local checkResult = v.args
			if not action then 
				continue 
			end

			if v.method == 'Start' then
				local prevent = SeqHookRun('UParStart', ply, action, checkResult)
				if not prevent then
					action:Start(ply, checkResult)
					local effect = action:GetPlayerUsingEffect(ply)
					if effect then effect:Start(ply, checkResult) end
				end
			elseif v.method == 'Clear' then
				local iSource = UPar.GetAction(v.isource)
				local iData = v.iargs
				 
				local prevent = SeqHookRun('UParClear', ply, action, checkResult, nil, nil, iSource, iData)
				if not prevent then
					action:Clear(ply, checkResult, nil, nil, iSource, iData)
					local effect = action:GetPlayerUsingEffect(ply)
					if effect then effect:Clear(ply, checkResult, iSource, iData) end
				end
			elseif v.method == 'RhythmChange' then
				
			end
        end
    end)
end

if SERVER then
	// function a1() return 1 end
	// function a2() return 1, nil end
	// function a3() return 1, nil, nil end

	// local a1, a1size = PackResult(a1())
	// local a2, a2size = PackResult(a2())
	// local a3, a3size = PackResult(a3())

	// local ply = Entity(1)
	// UPar.NWBatchInit(ply, nil)
	// 	UPar.NWWriteBatch(ply, nil, UPNW_FLAG_START, 'testAction', a1, a1size)
	// 	UPar.NWWriteBatch(ply, nil, UPNW_FLAG_END, 'testAction', a2, a2size)
	// 	UPar.NWWriteBatch(ply, nil, UPNW_FLAG_INTERRUPT, 'testAction', a3, a3size)
	// 	UPar.NWWriteBatch(ply, nil, UPNW_FLAG_RHYTHM_CHANGE, 'testAction', a3, a3size)
		
	// 	PrintTable(ply['upnwbatch_'])
	// UPar.NWSendBatch(ply, nil)
end

local CreateTrack = function(trackId)
	local timeout =
	return 'uptrack_' .. (trackId or '')
end
UPar.CreateTrack = CreateTrack


UPar.Trigger = function(ply, action, data, checkResult, trackId)
	if action:GetDisabled() then
		return
	end

	-- checkResult 用于绕过 Check直接跳转
	local actName = action.Name
	
	if SERVER then
		local trackKey = 'uptrack_' .. (trackId or '')
		local trackDataKey = trackKey .. '_data'
		local playing = ply[trackKey]
		local playingData = ply[trackDataKey]

		if playing and not SeqHookRun('UParInterrupt', ply, playing, playingData, action) then
			return
		end

		checkResult = checkResult or action:Check(ply, data)
		if not istable(checkResult) or SeqHookRun('UParPreStart', ply, action, checkResult) then
			return
		end

		local netData = {}
		if playing then
			ply[trackKey] = nil
			ply[trackDataKey] = nil

			local prevent = SeqHookRun('UParClear', ply, playing, playingData, nil, nil, action, checkResult)
			if not prevent then
				playing:Clear(ply, playingData, nil, nil, action, checkResult)
				local effect = playing:GetPlayerUsingEffect(ply)
				if effect then effect:Clear(ply, playingData, action, checkResult) end
			end

			table.insert(netData, {
				method = 'Clear',
				actName = playing.Name,
				args = playingData,
				iactName = action.Name,
				iargs = checkResult,
			})
		end

		local prevent = SeqHookRun('UParStart', ply, action, checkResult)
		if not prevent then
			action:Start(ply, checkResult)
			local effect = action:GetPlayerUsingEffect(ply)
			if effect then effect:Start(ply, checkResult) end
		end

		ply[trackKey] = action
		ply[trackDataKey] = checkResult

		table.insert(netData, {
			method = 'Start',
			actName = actName,
			args = checkResult,
		})
	
		CallClientAction(ply, netData)
		
		return checkResult
	elseif CLIENT then
		checkResult = checkResult or action:Check(ply, data)
		if not istable(checkResult) then
			return
		end

		net.Start('UParStart')
			net.WriteString(actName)
			net.WriteString(trackId or '')
			net.WriteTable(checkResult)
		net.SendToServer()

		return checkResult
	end
end


if SERVER then
	hook.Add('SetupMove', 'upar.play', function(ply, mv, cmd)
		local playing = ply.upar_playing
		if not playing then 
			return 
		end

		local playingData = ply.upar_playing_data

		local endReason = table.Pack(pcall(playing.Play, playing, ply, mv, cmd, unpack(playingData)))

		-- 异常处理
		local succ, err = endReason[1], endReason[2]
		if not succ then
			ForceEnd(ply)
			error(string.format('Action "%s" Play error: %s\n', playing.Name, err))
			return
		end

		if not endReason[2] then
			return
		end

		if endReason then
			ply.upar_playing = nil
			ply.upar_playing_data = nil
			StartTriggerNet(ply)
				playing:Clear(ply, mv, cmd, unpack(endReason, 2))

				local effect = GetPlayerCurrentEffect(ply, playing)
				if effect then 
					effect:clear(ply, unpack(endReason, 2)) 
				end

				-- 这里endReason第一位是pcall的返回值, 客户端需要去掉
				WriteEnd(ply, playing.Name, endReason)
				WriteMoveControl(ply, false, false, 0, 0)
			SendTriggerNet(ply)

			hook.Run('UParEnd', ply, playing, endReason)
		end
	end)

	UPar.GetPlaying = function(ply, trackId)
		local trackKey = 'uptrack_' .. (trackId or '')
		local trackDataKey = trackKey .. '_data'

		return ply[trackKey], ply[trackDataKey]
	end

	UPar.SetPlaying = function(ply, action, data, trackId)
		local trackKey = 'uptrack_' .. (trackId or '')
		local trackDataKey = trackKey .. '_data'

		ply[trackKey] = action
		ply[trackDataKey] = data
	end
elseif CLIENT then
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
end


