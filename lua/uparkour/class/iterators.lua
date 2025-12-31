--[[
	作者:白狼
	2025 12 20
	豆包改造:支持自定义帧循环钩子，默认Think，兼容原有逻辑
--]]
UPar.Iterators = UPar.Iterators or {}
local Iterators = UPar.Iterators

-- 【改造1】：用表存储每个钩子的运行状态（替代原有单个isThinkHookAdded/thinkHookStartTime）
-- 结构：hookStatus[hookName] = { startTime = number }
local hookStatus = {}

local FRAME_HOOK_IDENTITY = 'upar.iterators'
local DEFAULT_HOOK_NAME = 'Think' -- 默认帧循环钩子
local POP_HOOK = 'UParIteratorPop'
local PUSH_HOOK = 'UParIteratorPush'
local PAUSE_HOOK = 'UParIteratorPause'
local END_TIME_CHANGED_HOOK = 'UParIteratorEndTimeChanged'
local RESUME_HOOK = 'UParIteratorResume'

-- 【改造2】：重构钩子回调函数，支持指定钩子名称，仅处理该钩子下的迭代器
local function FrameCall(hookName)
	local removeCurrentHookFlag = true
	local curTime = CurTime()
	local hookState = hookStatus[hookName]
	if not hookState then return end -- 异常防护：钩子状态不存在直接返回
	
	local dt = curTime - hookState.startTime
	hookState.startTime = curTime
	
	local removeIdentities = {}
	
	for identity, data in pairs(Iterators) do
		if data.hn ~= hookName then
			ErrorNoHaltWithStack(string.format('iterator "%s" hookName "%s" mismatch, expect "%s"', identity, data.hn, hookName))
			table.insert(removeIdentities, {identity, data, 'HOOK_MISMATCH'})
			removeCurrentHookFlag = false
			break
		end

		if data.pt then 
			continue
		end

		removeCurrentHookFlag = false

		local iterator, edtime, add = data.f, data.et, data.add
		local succ, result = pcall(iterator, dt, curTime, add)
		
		if not succ then
			ErrorNoHaltWithStack(result)
			table.insert(removeIdentities, {identity, data, 'ERROR'})
			break
		elseif result then
			table.insert(removeIdentities, {identity, data, nil})
		elseif curTime > edtime then
			table.insert(removeIdentities, {identity, data, 'TIMEOUT'})
		end
	end

	-- 多次遍历防止交叉感染，先校验迭代器数据是否未被篡改
	for i = #removeIdentities, 1, -1 do
		local identity, data, reason = unpack(removeIdentities[i])
		if Iterators[identity] ~= data then
			print(string.format('[UPar.Iterators]: warning: iterator "%s" changed in think call', identity))
			table.remove(removeIdentities, i)
			removeCurrentHookFlag = false
		else
			Iterators[identity] = nil
		end
	end

	for _, v in ipairs(removeIdentities) do
		local identity, data, reason = unpack(v)

		if Iterators[identity] ~= nil then
			print(string.format('[UPar.Iterators]: warning: iterator "%s" changed in other', identity))
			removeCurrentHookFlag = false
			continue
		end

		if isfunction(data.clear) then
			local succ, result = pcall(data.clear, identity, curTime, data.add, reason)
			if not succ then ErrorNoHaltWithStack(result) end
		end
	end

	for _, v in ipairs(removeIdentities) do
		local identity, data, reason = unpack(v)

		if Iterators[identity] ~= nil then
			print(string.format('[UPar.Iterators]: warning: iterator "%s" changed in other', identity))
			removeCurrentHookFlag = false
			continue
		end

		hook.Run(POP_HOOK, identity, curTime, data.add, reason) 
		data.add = nil
	end

	if removeCurrentHookFlag then
		hook.Remove(hookName, FRAME_HOOK_IDENTITY)
		hookStatus[hookName] = nil
	end
end

local function __Internal_StartFrameLoop(hookName)
	local hookState = hookStatus[hookName]
	if hookState then
		hookState.startTime = CurTime()
	else
		hookState = {startTime = CurTime()}
		hook.Add(hookName, FRAME_HOOK_IDENTITY, function() FrameCall(hookName) end)
		hookStatus[hookName] = hookState
	end
end

-- 【改造3】：PushIterator增加hookName参数，默认DEFAULT_HOOK_NAME（兼容原有调用）
UPar.PushIterator = function(identity, iterator, addition, timeout, clear, hookName)
	assert(isfunction(iterator), 'iterator must be a function.')
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(isnumber(timeout), 'timeout must be a number.')
	assert(isstring(hookName) or hookName == nil, 'hookName must be a string or nil.')

	-- 默认 Think
	hookName = hookName or DEFAULT_HOOK_NAME
	if timeout <= 0 then 
		print('[UPar.PushIterator]: warning: timeout <= 0!') 
		return false
	end

	local old = Iterators[identity]
	if old then hook.Run(POP_HOOK, identity, CurTime(), old.add, 'OVERRIDE') end

	local endtime = timeout + CurTime()
	addition = istable(addition) and addition or {}
	hook.Run(PUSH_HOOK, identity, endtime, addition)

	Iterators[identity] = {
		f = iterator, 
		et = endtime, 
		add = addition, 
		clear = clear,
		hn = hookName
	}
	
	__Internal_StartFrameLoop(hookName)
	
	return true
end

UPar.PopIterator = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')

	local iteratorData = Iterators[identity]
	Iterators[identity] = nil

	if not iteratorData then
		return false
	end

	if isfunction(iteratorData.clear) then
		local succ, result = pcall(iteratorData.clear, identity, CurTime(), iteratorData.add, 'MANUAL')
		if not succ then ErrorNoHaltWithStack(result) end
	end

	if not silent then
		hook.Run(POP_HOOK, identity, CurTime(), iteratorData.add, 'MANUAL')
	end

	iteratorData.add = nil
	
	return true
end

UPar.GetIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity]
end

UPar.IsIteratorExist = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity] ~= nil
end

UPar.PauseIterator = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end
	
	local pauseTime = CurTime()
	iteratorData.pt = pauseTime

	if not silent then
		hook.Run(PAUSE_HOOK, identity, pauseTime, iteratorData.add)
	end
	
	return true
end

UPar.ResumeIterator = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end

	if not iteratorData.pt then
		return false
	else
		local resumeTime = CurTime()
		local pauseTime = iteratorData.pt
		iteratorData.pt = nil
		
		-- 更新超时时间：补偿暂停时长
		iteratorData.et = resumeTime + (iteratorData.et - pauseTime)
		
		if not silent then
			hook.Run(RESUME_HOOK, identity, resumeTime, iteratorData.add)
		end

		local hookName = iteratorData.hn
		__Internal_StartFrameLoop(hookName)
		
		return true
	end
end

UPar.SetIterAddiKV = function(identity, ...)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end

	local target = iteratorData.add

	local total = select('#', ...)
	assert(total >= 2, 'at least 2 arguments required')

	local keyValue = {...}
	
	for i = 1, total - 2 do
		target = target[keyValue[i]]
		if not istable(target) then return false end
	end

	target[keyValue[total - 1]] = keyValue[total]
	return true
end

UPar.GetIterAddiKV = function(identity, ...)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return nil
	end

	local target = iteratorData.add

	local total = select('#', ...)
	assert(total >= 2, 'at least 2 arguments required')

	local keyValue = {...}
	
	for i = 1, total - 2 do
		target = target[keyValue[i]]
		if not istable(target) then return nil end
	end

	return target[keyValue[total - 1]]
end

UPar.SetIterEndTime = function(identity, endTime, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end

	iteratorData.et = endTime
		
	if not silent then
		hook.Run(END_TIME_CHANGED_HOOK, identity, endTime, iteratorData.add)
	end

	return true
end

UPar.MergeIterAddiKV = function(identity, data)
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(istable(data), 'data must be a table.')

	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end

	table.Merge(iteratorData.add, data)
	
	return true
end