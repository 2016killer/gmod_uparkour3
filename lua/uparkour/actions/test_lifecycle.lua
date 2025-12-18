--[[
	作者:白狼
	2025 12 13
]]--

if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end
-- ==================== 生命周期测试 ===============

local action = UPAction:Register('test_lifecycle', {
	AAAACreat = '白狼', 
	AAADesc = '#upgui.dev.test.desc'
})

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

end

function action:Think(ply, mv, cmd, checkResult)
	local curtime = CurTime()

	if curtime > checkResult.endtime then
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

UPAction:Register('test_lifecycle_t1', action, true)
