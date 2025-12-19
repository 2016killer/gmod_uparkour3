--[[
	作者:白狼
	2025 12 18
]]--

-- ==================== 测试其他面板 ===============
if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end

UPAction:Register('test_interrupt', {invisible = true})

if SERVER then 
	UPar.SeqHookAdd('UParActAllowInterrupt_test_lifecycle', 'example.interrupt', function(ply, playingData, interruptSource)
		if interruptSource == 'test_interrupt' then
			return true
		end
	end)
end
// UPar.SeqHookAdd('UParActAllowInterrupt', 'example.interrupt', function(playingName, ply, playingData, interruptSource)
// 	if playingName == 'test_lifecycle' and interruptSource == 'test_interrupt' then
// 		return true
// 	end
// end)


-- 随机停止
// UPar.SeqHookAdd('UParActPreStartValidate_test_lifecycle', 'example.prestart.validate', function(...)
// 	return math.random() > 0.5
// end)

-- 随机停止所有
// UPar.SeqHookAdd('UParActPreStartValidate', 'example.prestart.validate', function(...)
// 	return math.random() > 0.5
// end)

-- 启动后
// UPar.SeqHookAdd('UParActStartOut_test_lifecycle', 'example.prestart.out', function(ply, checkResult)
// end)

// UPar.SeqHookAdd('UParActStartOut', 'example.prestart.out', function(actName, ply, checkResult)
// end)

-- 清除后
// UPar.SeqHookAdd('UParActClearOut_test_lifecycle', 'example.prestart.out', function(ply, checkResult, mv, cmd, interruptSource)
// end)

// UPar.SeqHookAdd('UParActClearOut', 'example.prestart.out', function(actName, ply, checkResult, mv, cmd, interruptSource)
// end)