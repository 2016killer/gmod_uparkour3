--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 生命期 ===============
if not GetConVar('developer'):GetBool() then return end

local action = UPAction:new('test_lifecycle', {AAACreat = '白狼'})
action:Register()

-- 注册控制台变量
action:InitConVars(
    {
        {
            name = 'example_numslider',
            default = '0',
            widget = 'NumSlider',
            min = 0, max = 1, decimals = 2,
            help = true
        },

	    {
            name = 'example_color',
            default = '0',
            widget = 'UParColorEditor'
        },

	    {
            name = 'example_ang',
            default = '0',
            widget = 'UParAngEditor',
			min = -1, max = 1, decimals = 1, interval = 0.1,
        },

	    {
            name = 'example_vec',
            default = '0',
            widget = 'UParVecEditor',
			min = -2, max = 2, decimals = 2, interval = 0.5,
        },

	    {
            name = 'example_invisible',
            default = '0',
            widget = 'NumSlider',
			invisible = true,
        },

	    {
            name = 'example_admin',
            default = '0',
            widget = 'NumSlider',
			admin = true,
        }
    }
) 

if CLIENT then
	-- 注册预设
	action:RegisterPreset(
		{
			AAACreat = 'Miss DouBao',
			AAAContrib = 'Zack',

			label = '#upgui.example',
			values = {
				['example_numslider'] = '0.5'
			}
		}
	) 
end

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
	surface.PlaySound(customData or 'hl1/fvox/blip.wav')
end

function effect:Clear(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/deactivated.wav')
end

-- ==================== 轨道1 ===============
local action_t1 = UPar.DeepClone(action)
action_t1.Name = 'test_lifecycle_t1'
action_t1.Invisible = true
action_t1.TrackId = 1
action_t1:InitCVarDisabled()
action_t1:Register()

-- ==================== 中断 ===============
local action_interrupt = UPAction:new('test_interrupt', {Invisible = true})
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
	-- 创建其他菜单
	local function TriggerPanel(self, panel)
		local run = panel:Button(UPar.SnakeTranslate_2('run_track', nil, '_', ' ') .. ' 0', '')
		run.DoClick = function()
			UPar.Trigger(LocalPlayer(), action, 'oh shit')
		end

		local changerhythm = panel:Button(UPar.SnakeTranslate_2('change_rhythm', nil, '_', ' '), '')
		changerhythm.DoClick = function()
			UPar.ActChangeRhythm(LocalPlayer(), action, 'hl1/fvox/blip.wav')
		end

		local run_t1 = panel:Button(UPar.SnakeTranslate_2('run_track', nil, '_', ' ') .. ' 1', '')
		run_t1.DoClick = function()
			UPar.Trigger(LocalPlayer(), action_t1, 'oh good')
		end

		local interrupt = panel:Button('#upgui.interrupt', '')
		interrupt.DoClick = function()
			UPar.Trigger(LocalPlayer(), action_interrupt)
		end

		local killself = panel:Button('#upgui.killself', '')
		killself.DoClick = function()
			RunConsoleCommand('kill')
		end

		panel:Help('')
	end

	action.SundryPanels = {
		{
			label = '#upgui.trigger',
			func = TriggerPanel,
		}
	}
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
// 	// print('checkResult:', checkResult)
// 	// PrintTable(checkResult)
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
