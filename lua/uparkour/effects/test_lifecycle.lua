--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 生命周期 ===============
if not GetConVar('developer'):GetBool() then return end

local effect = UPEffect:Register(
	'test_lifecycle', 
	'default', 
	{label = '#default', AAACreat = '白狼'}
)

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

UPEffect:Register('test_lifecycle_t1', 'default', effect)
-- ==================== 变奏覆盖 ===============
// UPar.SeqHookAdd('UParOnChangeRhythm', 'test_rhythm_override', function(ply, action, effect, customData)
// 	local actName = action.Name
// 	if actName ~= 'test_lifecycle' then
// 		return
// 	end

// 	print(string.format('\n============ Rhythm Override Test, TrackId: %s ============', action.TrackId))

// 	return true
// end)