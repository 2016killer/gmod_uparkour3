--[[
	作者:白狼
	2025 12 13

	2.1.0 版本的数据兼容
--]]

local effectConfig = UPar.LoadUserDataFromDisk('ultipar/effect_config.json')
local customEffects = UPar.LoadUserDataFromDisk('ultipar/effects_custom.json')

local targetActions = {
	'DParkour-LowClimb',
	'DParkour-HighClimb',
	'DParkour-Vault'
}

local mapping = {
	['SP-VManip-白狼'] = 'default',
	['SinglePlayer-Punch-Compat-余智博'] = 'PunchCompat',
	['Custom'] = 'CACHE'
}

print('=================数据兼容 2.1.0=================')
if effectConfig then
	print('effect_config.json')
	
	for _, actionName in ipairs(targetActions) do
		local effectName = effectConfig[actionName]

		if not effectConfig[actionName] or not mapping[effectName] then
			continue
		end

		effectConfig[actionName] = mapping[effectName]
	end
end
UPar.SaveEffectConfigToDisk(effectConfig)


if customEffects then
	print('effects_custom.json')

	for _, actionName in ipairs(targetActions) do
		local customEffect = customEffects[actionName]

		if not istable(customEffect) or not mapping[customEffect.linkName] then
			continue
		end

		customEffect.linkName = mapping[customEffect.linkName]
	end
end

UPar.SaveEffectCacheToDisk(customEffects)
print('=================转换成功=================')
