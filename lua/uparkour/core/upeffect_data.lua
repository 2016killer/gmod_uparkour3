--[[
	作者:白狼
	2025 11 1
--]]

UPar.RegisterEffectEasy = function(actName, tarName, name, initData)
	local action = UPar.GetAction(actName)
	if not action then
		error(string.format('Invalid action "%s"', actName))
	end

	local targetEffect = action:GetEffect(tarName)
	if not targetEffect then
		error(string.format('Invalid effect "%s" for action "%s"', tarName, actName))
	end

	local effect = table.Merge(table.Copy(targetEffect), initData)
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
		error(string.format('custom "%s" is not table', custom))
	end

	return !!custom.linkName
end

UPar.InitCustomEffect = function(actName, custom)
	if not UPar.IsCustomEffect(custom) then 
		return true
	end

    local tarName = custom.linkName
	local action = UPar.GetAction(actName)
	if not action then
		print(string.format('[UPar]: init custom effect failed, invalid action "%s"', actName))
		return false
	end

	local targetEffect = action:GetEffect(tarName)
	if not targetEffect then
		print(string.format('[UPar]: init custom effect failed, invalid effect "%s" for action "%s"', tarName, actName))
		return false
	end

	for k, v in pairs(targetEffect) do
		if custom[k] == nil then custom[k] = v end
	end

	return true
end

UPar.PushEffectCache = function(ply, actName, custom)
	if not UPar.IsCustomEffect(custom) then 
		print(string.format('[UPar]: push cache failed, effect "%s" is not custom effect', custom.Name))
		return false
	end

    ply.upeff_cache[actName] = custom

	return true
end

UPar.PushEffectConfig = function(ply, actName, effName)
    if not actName then
        print(string.format('[UPar]: push config failed, invalid actName "%s"', actName))
        return false
    end

    if not effName then
        print(string.format('[UPar]: push config failed, invalid effName "%s"', effName))
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
	file.CreateDir('uparkour3_effect')
	file.CreateDir('uparkour3_effect/custom')

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
		return UPar.LoadUserDataFromDisk('uparkour3_effect/config.json')
	end

	UPar.LoadEffectCacheFromDisk = function()
		return UPar.LoadUserDataFromDisk('uparkour3_effect/cache.json')
	end

	UPar.SaveEffectConfigToDisk = function(data)
		UPar.SaveUserDataToDisk(data, 'uparkour3_effect/config.json')
	end

	UPar.SaveEffectCacheToDisk = function(data)
		UPar.SaveUserDataToDisk(data, 'uparkour3_effect/cache.json')
	end

	UPar.GetCustomEffectFile = function()
		return file.Find('uparkour3_effect/custom/*.json', 'DATA')
	end

	UPar.LoadCustomEffectFromDisk = function(filename)
		return UPar.LoadUserDataFromDisk('uparkour3_effect/custom/' .. filename)
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
