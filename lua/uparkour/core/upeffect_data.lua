--[[
	作者:白狼
	2025 11 1
--]]

UPar.RegisterEffectEasy = function(actName, tarName, name, initData)
	local action = UPar.GetAction(actName)
	if not action then
		error(string.format('can not find action named "%s"', actName))
	end

	local targetEffect = action:GetEffect(tarName)
	if not targetEffect then
		error(string.format('can not find effect named "%s" from act "%s"', tarName, actName))
	end

	local effect = table.Merge(UPar.Clone(targetEffect), initData)
	effect.Name = name
	effect:Register()
	
	return effect
end

UPar.CreateCustomEffect = function(tarName, name)
	return {
		Name = name,
        linkName = tarName,
		icon = 'icon64/tool.png',
		label = '',
	}
end

UPar.IsCustomEffect = function(custom) 
	if not istable(custom) then 
		return false 
	end

	return !!custom.linkName
end

UPar.InitCustomEffect = function(actName, custom)
	if not UPar.IsCustomEffect(custom) then 
		print(string.format('[UPar]: init custom effect failed, "%s" is not custom effect', custom))
		return false
	end

    local tarName = custom.linkName
	local action = UPar.GetAction(actName)
	if not action then
		print(string.format('[UPar]: init custom effect failed, can not find action named "%s"', actName))
		return false
	end

	local targetEffect = action:GetEffect(tarName)
	if not targetEffect then
		print(string.format('[UPar]: init custom effect failed, can not find effect named "%s" from act "%s"', tarName, actName))
		return false
	end

	for k, v in pairs(targetEffect) do
		if custom[k] == nil then custom[k] = v end
	end

	return true
end

UPar.PushEffectCache = function(ply, actName, custom)
	if not UPar.IsCustomEffect(custom) then 
		print(string.format('[UPar]: push cache failed, effect "%s" is not custom effect', custom))
		return false
	end

    ply.upeff_cache[actName] = custom

	return true
end

UPar.PushEffectConfig = function(ply, actName, effName)
    if not actName then
        print(string.format('[UPar]: push effect config failed, can not find action named "%s"', actName))
        return false
    end

    if not effName then
        print(string.format('[UPar]: push effect config failed, can not find effect named "%s" from act "%s"', effName, actName))
        return false
    end

    ply.upeff_cfg[actName] = effName

	return true
end

if SERVER then
	util.AddNetworkString('UParEffectCache')
	util.AddNetworkString('UParEffectConfig')

	net.Receive('UParEffectCache', function(len, ply)
		local content = net.ReadString()
		// content = util.Decompress(content)

		local data = util.JSONToTable(content or '')
		if not istable(data) then
			print('[UPar]: receive data is not table')
			return
		end

		-- 初始化自定义特效
		for actName, custom in pairs(data) do
			UPar.InitCustomEffect(actName, custom)
		end

		table.Merge(ply.upeff_cache, data)
	end)

	net.Receive('UParEffectConfig', function(len, ply)
		local content = net.ReadString()
		// content = util.Decompress(content)

		local data = util.JSONToTable(content or '')
		if not istable(data) then
			print('[UPar]: receive data is not table')
			return
		end

		table.Merge(ply.upeff_cfg, data)
	end)

	hook.Add('PlayerInitialSpawn', 'upar.init.effect', function(ply)
		ply.upeff_cfg = ply.upeff_cfg or {}
		ply.upeff_cache = ply.upeff_cache or {}
	end)

elseif CLIENT then
	file.CreateDir('uparkour_effect')
	file.CreateDir('uparkour_effect/custom')

	UPar.SendEffectCacheToServer = function(data)
		-- 为了过滤掉一些不能序列化的数据
		local content = util.TableToJSON(data)
		if not content then
			print('[UPar]: send effect cache to server failed, content is not valid json')
			return
		end
		// content = util.Compress(content)

		net.Start('UParEffectCache')
			net.WriteString(content)
		net.SendToServer()
	end

	UPar.SendEffectConfigToServer = function(data)
		local content = util.TableToJSON(data)
		if not content then
			print('[UPar]: send effect config to server failed, content is not valid json')
			return
		end
		// content = util.Compress(content)

		net.Start('UParEffectConfig')
			net.WriteString(content)
		net.SendToServer()
	end

	UPar.LoadEffectConfigFromDisk = function()
		return UPar.LoadUserDataFromDisk('uparkour_effect/config.json')
	end

	UPar.LoadEffectCacheFromDisk = function()
		return UPar.LoadUserDataFromDisk('uparkour_effect/cache.json')
	end

	UPar.SaveEffectConfigToDisk = function(data)
		UPar.SaveUserDataToDisk(data, 'uparkour_effect/config.json')
	end

	UPar.SaveEffectCacheToDisk = function(data)
		UPar.SaveUserDataToDisk(data, 'uparkour_effect/cache.json')
	end

	UPar.GetCustomEffectFile = function(actName)
		return file.Find(string.format('uparkour_effect/custom/%s/*.json', actName), 'DATA')
	end

	UPar.LoadCustomEffectFromDisk = function(filename)
		return UPar.LoadUserDataFromDisk('uparkour_effect/custom/' .. filename)
	end

	UPar.SaveCustomEffectToDisk = function(actName, custom)
		UPar.SaveUserDataToDisk(custom, string.format('uparkour_effect/custom/%s/%s.json', actName, custom.Name))
	end

	hook.Add('KeyPress', 'upar.init.effect', function(ply, key)
		hook.Remove('KeyPress', 'upar.init.effect')

		local effectCache = UPar.LoadEffectCacheFromDisk()
		local effectConfig = UPar.LoadEffectConfigFromDisk()
		
		UPar.SendEffectCacheToServer(effectCache)
		UPar.SendEffectConfigToServer(effectConfig)

		for actName, custom in pairs(effectCache) do
			UPar.InitCustomEffect(actName, custom)
		end

		ply.upeff_cfg = effectConfig or {}
		ply.upeff_cache = effectCache or {}
	end)
end
