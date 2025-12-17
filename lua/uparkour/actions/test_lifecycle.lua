--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 生命周期 ===============
if not GetConVar('developer'):GetBool() then return end

local action = UPAction:Register('test_lifecycle', {AAACreat = '白狼', AAADesc = '#upgui.dev.test.desc'})

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
            name = 'example_keybinder',
            default = '[9, 1]',
            widget = 'UParKeyBinder',
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

action:AddConVar({
	name = 'example_other',
	widget = 'NumSlider',
})

if CLIENT then
	-- 注册预设
	action:RegisterPreset(
		'example',
		{
			AAACreat = 'Miss DouBao',
			AAAContrib = 'Zack',

			label = '#upgui.dev.example',
			values = {
				['example_numslider'] = '0.5'
			}
		}
	) 

	action:InitCVarKeybind('0 0 0')
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

-- 创建其他菜单
if CLIENT then
	local function TriggerPanel(self, panel)
		local run = panel:Button('#upgui.dev.run_track_0', '')
		run.DoClick = function()
			local act = UPar.GetAction('test_lifecycle')
			UPar.Trigger(LocalPlayer(), act, 'oh shit')
		end
		
		local changerhythm = panel:Button('#upgui.dev.change_rhythm_0', '')
		changerhythm.DoClick = function()
			local act = UPar.GetAction('test_lifecycle')
			UPar.ActChangeRhythm(LocalPlayer(), act, 'hl1/fvox/blip.wav')
		end

		local run_t1 = panel:Button('#upgui.dev.run_track_1', '')
		run_t1.DoClick = function()
			local act = UPar.GetAction('test_lifecycle_t1')
			UPar.Trigger(LocalPlayer(), act, 'oh good')
		end

		local interrupt = panel:Button('#upgui.dev.run_interrupt_0', '')
		interrupt.DoClick = function()
			local act = UPar.GetAction('test_interrupt')
			UPar.Trigger(LocalPlayer(), act)
		end

		local killself = panel:Button('#upgui.dev.killself', '')
		killself.DoClick = function()
			RunConsoleCommand('kill')
		end

		panel:Help('')
	end

	action.SundryPanels = {
		{
			label = '#upgui.dev.trigger',
			func = TriggerPanel,
		}
	}
end

-- ==================== 轨道1 ===============
local action_t1 = UPAction:Register('test_lifecycle_t1', action)
action_t1.Invisible = false
action_t1.TrackId = 1

-- 覆盖ConVarsPanel
if CLIENT then
    function action_t1:ConVarsPanelOverride(panel)
        panel:Help('#upgui.dev.cv_panel_override')
		panel:Help('')
    end
end
-- ==================== 中断 ===============
local action_interrupt = UPAction:Register('test_interrupt', {Invisible = true})

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

-- 拓展控件
if CLIENT then
    function action:ConVarWidgetExpand(idx, cvCfg, originWidget, panel)
		if IsValid(originWidget) and ispanel(originWidget) and idx == 1 then
			local label = vgui.Create('DLabel')
			label:SetText('#upgui.dev.cv_widget_expand')
			label:SetTextColor(Color(0, 150, 0))

			return label
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
