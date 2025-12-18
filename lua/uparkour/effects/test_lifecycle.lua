--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 生命周期 ===============
if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end

local effect = UPEffect:Register(
	'test_lifecycle', 
	'default', 
	{label = '#default', AAAACreat = '白狼'}
)

function effect:Start(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/activated.wav')
end

function effect:Rhythm(ply, customData)
	print('customData:', customData)
	if SERVER then return end
	surface.PlaySound(customData or 'hl1/fvox/blip.wav')
end

function effect:Clear(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/deactivated.wav')
end

local example = UPEffect:Register('test_lifecycle', 'example', effect)
example.label = '#upgui.dev.example'

UPEffect:Register('test_lifecycle_t1', 'default', effect)
