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

UPar.IsCustomEffect = function(custom) 
	if not istable(custom) then 
		return false 
	end

	return isstring(custom.Name) and isstring(custom.linkName) and isstring(custom.linkAct)
end

UPar.InitCustomEffect = function(custom)
	if not UPar.IsCustomEffect(custom) then 
		print(string.format('init custom effect failed, "%s" is not custom effect', istable(custom) and util.TableToJSON(custom, true) or custom))
		return false
	end

    local actName = custom.linkAct
    local tarName = custom.linkName

	local action = UPar.GetAction(actName)
	if not action then
		print(string.format('init custom effect failed, can not find action named "%s"', actName))
		return false
	end

	local targetEffect = action:GetEffect(tarName)
	if not targetEffect then
		print(string.format('init custom effect failed, can not find effect named "%s" from act "%s"', tarName, actName))
		return false
	end

	for k, v in pairs(targetEffect) do
		if custom[k] == nil then custom[k] = v end
	end

	return true
end

UPar.PushPlyEffCache = function(ply, custom)
	if not UPar.IsCustomEffect(custom) then 
		print(string.format('push eff cache failed, "%s" is not custom effect', istable(custom) and util.TableToJSON(custom, true) or custom))
		return false
	end

    ply.upeff_cache[custom.linkAct] = custom

	return true
end

UPar.PushPlyEffCfg = function(ply, actName, effName)
    if not isstring(actName) then
        print(string.format('push eff config failed, invalid actName "%s" (not string)', actName))
        return false
    end

    if not isstring(effName) then
        print(string.format('push eff config failed, invalid effName "%s" (not string)', effName))
		return false
    end

    ply.upeff_cfg[actName] = effName

	return true
end

UPar.InitPlyEffSetting = function(ply)
	ply.upeff_cfg = {}
	ply.upeff_cache = {}
end

UPar.PushPlyEffSetting = function(ply, cfg, cache)
	if istable(cfg) then
		for actName, effName in pairs(cfg) do
			if actName == 'AAAMetadata' then continue end
			UPar.PushPlyEffCfg(ply, actName, effName)
		end
	end

	if istable(cache) then
		for actName, cache in pairs(cache) do
			if actName == 'AAAMetadata' then continue end
			UPar.InitCustomEffect(cache)
			UPar.PushPlyEffCache(ply, cache)
		end
	end
end
 
if SERVER then
	util.AddNetworkString('SyncPlyEffSetting')

	net.Receive('SyncPlyEffSetting', function(len, ply)
		local content = net.ReadString()
		// content = util.Decompress(content)

		local data = util.JSONToTable(content or '')
		if not istable(data) then
			print('[UPar]: receive data is not table')
			return
		end

		local cfg, cache = unpack(data)
		UPar.PushPlyEffSetting(ply, cfg, cache)
	end)

	hook.Add('PlayerInitialSpawn', 'upar.init.effect', UPar.InitPlyEffSetting)
elseif CLIENT then
	file.CreateDir('uparkour_effect')
	file.CreateDir('uparkour_effect/custom')

	UPar.SaveCustomEffectToDisk = function(custom, override)
		if not UPar.IsCustomEffect(custom) then 
			ErrorNoHaltWithStack(string.format('save custom effect failed, "%s" is not custom effect', istable(custom) and util.TableToJSON(custom, true) or custom))
			return false
		end

		local dir = string.format('uparkour_effect/custom/%s', custom.linkAct)
		if not file.Exists(dir, 'DATA') then file.CreateDir(dir) end

		local path = string.format('uparkour_effect/custom/%s/%s.json', custom.linkAct, custom.Name)
		local exists = file.Exists(path, 'DATA')

		if exists and not override then
			ErrorNoHaltWithStack(string.format('save custom effect failed, "%s" already exists', path))
			return false
		end

		return UPar.SaveUserDataToDisk(custom, path)
	end

	UPar.CreateCustomEffect = function(actName, tarName, name)
		local path = string.format('uparkour_effect/custom/%s/%s.json', actName, name)
		local exists = file.Exists(path, 'DATA')

		if exists then
			ErrorNoHaltWithStack(string.format('create custom effect failed, "%s" already exists', path))
			return false
		end

		local custom = {
			Name = name,
			linkAct = actName,
			linkName = tarName,
			icon = 'icon64/tool.png',
			label = name,

			AAACreat = LocalPlayer():Nick(),
			AAAContrib = LocalPlayer():Nick(),
			AAADesc = 'Desc',
		}

		UPar.SaveCustomEffectToDisk(custom, true)

		return custom
	end

	UPar.SyncPlyEffSetting = function(ply, sendcfg, sendcache)
		local data = {
			sendcfg and ply.upeff_cfg or nil,
			sendcache and ply.upeff_cache or nil
		}

		-- 为了过滤掉一些不能序列化的数据
		local content = util.TableToJSON(data)
		if not content then
			print('[UPar]: sync player effect failed, content is not valid json')
			return
		end
		// content = util.Compress(content)

		net.Start('SyncPlyEffSetting')
			net.WriteString(content)
		net.SendToServer()
	end

	UPar.SaveUserEffCacheToDisk = function(data)
		UPar.SaveUserDataToDisk(data, 'uparkour_effect/cache.json')
	end

	UPar.SaveUserEffCfgToDisk = function(data)
		UPar.SaveUserDataToDisk(data, 'uparkour_effect/config.json')
	end

	UPar.LoadUserEffCacheFromDisk = function()
		return UPar.LoadUserDataFromDisk('uparkour_effect/cache.json')
	end

	UPar.LoadUserEffCfgFromDisk = function()
		return UPar.LoadUserDataFromDisk('uparkour_effect/config.json')
	end

	UPar.GetCustomEffectFiles = function(actName)
		local files = file.Find(string.format('uparkour_effect/custom/%s/*.json', actName), 'DATA')
		return files, actName
	end

	UPar.LoadCustomEffectFromDisk = function(filename)
		return UPar.LoadUserDataFromDisk('uparkour_effect/custom/' .. filename)
	end

	hook.Add('KeyPress', 'upar.init.effect', function(ply, key)
		hook.Remove('KeyPress', 'upar.init.effect')
		UPar.InitPlyEffSetting(ply)
		
		local cfg = UPar.LoadUserEffCfgFromDisk()
		local cache = UPar.LoadUserEffCacheFromDisk()

		UPar.PushPlyEffSetting(ply, cfg, cache)
		UPar.SyncPlyEffSetting(ply, true, true)
	end)
end
