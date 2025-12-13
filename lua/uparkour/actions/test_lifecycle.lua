--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 生命期 ===============
if not GetConVar('developer'):GetBool() then return end

local action = UPAction:new('test_lifecycle', {AAACreat = '白狼'})
action:Register()

function action:Check(ply, data)
	print(string.format('====== Check, TrackId: %s ======', self.TrackId))
	print('data:', data)
	return {arg1 = 1}
end

function action:Start(ply, checkResult)
	print(string.format('====== Start, TrackId: %s ======', self.TrackId))
	print('checkResult:', checkResult)
	PrintTable(checkResult)
	checkResult.endtime = CurTime() + 2
	checkResult.rhythm = 0
end

function action:Think(ply, mv, cmd, checkResult)
	local curtime = CurTime()
	if curtime > checkResult.endtime - 1 and checkResult.rhythm == 0 then
		checkResult.rhythm = 1
		UPar.ActChangeRhythm(ply, self, 'hl1/fvox/blip.wav')
	elseif curtime > checkResult.endtime then
		print(string.format('====== Think Out, TrackId: %s ======', self.TrackId))
		print('checkResult:', checkResult)
		PrintTable(checkResult)
		return true
	end

	return false
end

function action:Clear(ply, checkResult, mv, cmd, interruptSource, interruptData)
	print(string.format('====== Clear, TrackId: %s ======', self.TrackId))
	print('checkResult:', checkResult)
	PrintTable(checkResult)
	print('mv:', mv)
	print('cmd:', cmd)
	print('interruptSource:', interruptSource)
	print('interruptData:', interruptData)
end

local effect = UPEffect:new('default', {AAACreat = '白狼'})
effect:Register(action.Name)

function effect:Start(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/activated.wav')
end

function effect:OnRhythmChange(ply, customData)
	if SERVER then return end
	print('customData:', customData)
	surface.PlaySound(customData)
end

function effect:Clear(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/deactivated.wav')
end

-- ==================== 轨道1 ===============
local action_t1 = UPar.Clone(action)
table.Merge(action_t1, {Name = 'test_lifecycle_t1', TrackId = 1})
action_t1:Register()

-- ==================== 中断 ===============
local action_interrupt = UPAction:new('test_interrupt', {})
action_interrupt:Register()

UPar.SeqHookAdd('UParInterrupt', 'test_interrupt', function(ply, playing, playingData, interruptSource, interruptData)
	local playingName = playing.Name
	if playingName ~= 'test_lifecycle' then
		return
	end

	print(string.format('\n============ Interrupt Test, TrackId: %s ============', playing.TrackId))
	local interruptName = isbool(interruptSource) and 'Force' or interruptSource.Name
	local allowInterrupt = interruptName == 'test_interrupt'
	print(string.format('%s --> %s, %s\n', interruptName, playing.Name, allowInterrupt))
	if allowInterrupt then
		return true
	end
end)


if CLIENT then
	action.CreateOptionMenu = function(panel)
		local startButton = panel:Button('Test', '')
		startButton.DoClick = function()
			UPar.Trigger(LocalPlayer(), action, {'This is Shit'}, nil)
		end

		local accidentBreakTestButton = panel:Button('Accident Break Test', '')
		accidentBreakTestButton.DoClick = function()
			UPar.Trigger(LocalPlayer(), action, false, 'Shit', 'fuck')
			timer.Simple(1, function()
				RunConsoleCommand('kill')
			end)
		end

		local interruptTestButton = panel:Button('Interrupt Test', '')
		interruptTestButton.DoClick = function()
			UPar.Trigger(LocalPlayer(), action, false, 'Shit', 'fuck')
			local interruptAction = UPar.GetAction('InterruptTest')
			timer.Simple(1, function()
				UPar.Trigger(LocalPlayer(), interruptAction)
			end)
		end

	end
end

-- ==================== 随机停止 ===============
// UPar.SeqHookAdd('UParPreStart', 'test_random_stop', function(ply, action, checkResult)
// 	local actName = action.Name
// 	if actName ~= 'test_lifecycle' then
// 		return
// 	end

// 	local stop = math.random(0, 1) > 0.5
// 	if not stop then 
// 		return 
// 	end

// 	print(string.format('\n============ Random Stop Test, TrackId: %s ============', action.TrackId))

// 	return true
// end)

-- ==================== 启动覆盖 ===============
// UPar.SeqHookAdd('UParStart', 'test_start_override', function(ply, action, checkResult)
// 	local actName = action.Name
// 	if actName ~= 'test_lifecycle' then
// 		return
// 	end

// 	print(string.format('\n============ Start Override Test, TrackId: %s ============', action.TrackId))
// 	checkResult.endtime = 0

// 	return true
// end)

-- ==================== 清理覆盖 ===============
// UPar.SeqHookAdd('UParClear', 'test_clear_override', function(ply, playing, playingData, mv, cmd, interruptSource, interruptData)
// 	local playingName = playing.Name
// 	if playingName ~= 'test_lifecycle' then
// 		return
// 	end

// 	print(string.format('\n============ Clear Override Test, TrackId: %s ============', playing.TrackId))

// 	return true
// end)

-- ==================== 变奏覆盖 ===============
// UPar.SeqHookAdd('UParOnChangeRhythm', 'test_rhythm_override', function(ply, action, effect, customData)
// 	local actName = action.Name
// 	if actName ~= 'test_lifecycle' then
// 		return
// 	end

// 	print(string.format('\n============ Rhythm Override Test, TrackId: %s ============', action.TrackId))

// 	return true
// end)
