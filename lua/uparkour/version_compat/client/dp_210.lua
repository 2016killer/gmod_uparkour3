--[[
	作者:白狼
	2025 12 13

	2.1.0 版本的数据兼容
	旧版数据的路径迁移+重命名
		'ultipar/effect_config.json' --> new
		'ultipar/effects_custom.json' --> new
	重命名仅需修改 TargetActNames 和 EffNameMapping 即可
--]]


local oldConfig = UPar.LoadUserDataFromDisk('ultipar/effect_config.json') or {}
local oldCache = UPar.LoadUserDataFromDisk('ultipar/effects_custom.json') or {}

if table.IsEmpty(oldConfig) and table.IsEmpty(oldCache) then
	return
end


local newConfig = UPar.LoadEffectConfigFromDisk() or {}
local newCache = UPar.LoadEffectCacheFromDisk() or {}


local TargetActNames = {
	'DParkour-LowClimb',
	'DParkour-HighClimb',
	'DParkour-Vault'
}

local EffNameMapping = {
	['SP-VManip-白狼'] = 'default',
	['SinglePlayer-Punch-Compat-余智博'] = 'PunchCompat',
	['Custom'] = 'CACHE'
}

print('=================数据兼容 2.1.0=================')
if not table.IsEmpty(oldConfig) then
	for _, actName in ipairs(TargetActNames) do
		local effName = oldConfig[actName]

		if not oldConfig[actName] or not EffNameMapping[effName] then
			continue
		end

		oldConfig[actName] = nil
		newConfig[actName] = EffNameMapping[effName]
	end

	UPar.SaveEffectConfigToDisk(newConfig)
	UPar.SaveUserDataToDisk(oldConfig, 'ultipar/effect_config.json', true)
else
	file.Delete('ultipar/effect_config.json')
end


if not table.IsEmpty(oldCache) then
	for _, actName in ipairs(TargetActNames) do
		local cache = oldCache[actName]

		if not istable(cache) or not EffNameMapping[cache.linkName] then
			continue
		end

		cache.linkName = EffNameMapping[cache.linkName]
		oldCache[actName] = nil
		newCache[actName] = cache
	end
	
	UPar.SaveEffectCacheToDisk(newCache)
	UPar.SaveUserDataToDisk(oldCache, 'ultipar/effects_custom.json', true)
else
	file.Delete('ultipar/effects_custom.json')
end



