--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 生命周期 ===============
if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end

local effect = UPEffect:Register('test_lifecycle', 'default', {
	label = '#default', 
	AAAACreat = '白狼',
	rhythm_1_sound = 'hl1/fvox/blip.wav',
	rhythm_2_sound = 'hl1/fvox/blip.wav'
})

function effect:Start(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/activated.wav')
end

function effect:Rhythm(ply, customData)
	print('\n')
	print('customData:', customData)
	print('\n')
	if SERVER then return end
	if customData == 1 then
		surface.PlaySound(self.rhythm_1_sound)
	elseif customData == 2 then
		surface.PlaySound(self.rhythm_2_sound)
	else
		surface.PlaySound(self.rhythm_1_sound)
	end
end

function effect:Clear(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/deactivated.wav')
end

local example = UPEffect:Register('test_lifecycle', 'example', effect)
example.label = '#upgui.dev.example'

UPEffect:Register('test_lifecycle_t1', 'default', effect)
