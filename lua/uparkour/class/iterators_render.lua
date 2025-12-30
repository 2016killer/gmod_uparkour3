--[[
	作者:白狼
	2025 12 30
--]]

UPar.RenderIterators = UPar.RenderIterators or {}
local Iterators = UPar.RenderIterators

local isThinkHookAdded = false
local thinkHookStartTime = 0
local THINK_HOOK_KEY = 'upar.iterators'
local THINK_HOOK = 'PostRender'
local POP_HOOK = 'UParRenderIteratorPop'
local PUSH_HOOK = 'UParRenderIteratorPush'
local PAUSE_HOOK = 'UParRenderIteratorPause'
local END_TIME_CHANGED_HOOK = 'UParRenderIteratorEndTimeChanged'
local RESUME_HOOK = 'UParRenderIteratorResume'

local function ThinkCall()
	local removeThinkFlag = true
	local curTime = CurTime()
	local dt = curTime - thinkHookStartTime
	
	thinkHookStartTime = curTime
	
	local removeIdentities = {}
	for identity, data in pairs(Iterators) do
		if data.pt then 
			continue
		end

		removeThinkFlag = false

		local iterator, edtime, add = data.f, data.et, data.add
		local succ, result = pcall(iterator, dt, curTime, add)
		
		if not succ then
			ErrorNoHaltWithStack(result)
			table.insert(removeIdentities, {identity, data, 'ERROR'})
		elseif result then
			table.insert(removeIdentities, {identity, data, nil})
		elseif curTime > edtime then
			table.insert(removeIdentities, {identity, data, 'TIMEOUT'})
		end
	end

	for i = #removeIdentities, 1, -1 do
		local identity, data, _ = unpack(removeIdentities[i])
		if Iterators[identity] ~= data then
			print(string.format('[UPar.Iterators]: warning: iterator "%s" changed in think call', identity))
			table.remove(removeIdentities, i)
		else
			Iterators[identity] = nil
		end
	end

	for _, v in ipairs(removeIdentities) do
		local identity, data, reason = unpack(v)
		hook.Run(POP_HOOK, identity, curTime, data.add, reason) 
	end

	if removeThinkFlag then
		hook.Remove(THINK_HOOK, THINK_HOOK_KEY)
		isThinkHookAdded = false
	end
end

UPar.PushRenderIterator = function(identity, iterator, addition, timeout)
	assert(isfunction(iterator), 'iterator must be a function.')
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(isnumber(timeout), 'timeout must be a number.')
	if timeout <= 0 then 
		print('[UPar.PushRenderIterator]: warning: timeout <= 0!') 
		return false
	end

	local old = Iterators[identity]
	if old then hook.Run(POP_HOOK, identity, CurTime(), old.add, 'OVERRIDE') end

	local endtime = timeout + CurTime()
	addition = istable(addition) and addition or {}
	hook.Run(PUSH_HOOK, identity, endtime, addition)

	Iterators[identity] = {f = iterator, et = endtime, add = addition}
	
	if not isThinkHookAdded then
		thinkHookStartTime = CurTime()
		isThinkHookAdded = true
		hook.Add(THINK_HOOK, THINK_HOOK_KEY, ThinkCall)
	end
	
	return true
end

UPar.PopRenderIterator = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')

	local iteratorData = Iterators[identity]
	Iterators[identity] = nil

	if not iteratorData then
		return false
	end

	if not silent then
		hook.Run(POP_HOOK, identity, CurTime(), iteratorData.add, 'MANUAL')
	end
	
	return true
end

UPar.GetRenderIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity]
end

UPar.IsRenderIteratorExist = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity] ~= nil
end

UPar.PauseRenderIterator = function(identity, silent)
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

UPar.ResumeRenderIterator = function(identity, silent)
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
		
		iteratorData.et = resumeTime + (iteratorData.et - pauseTime)
		
		if not silent then
			hook.Run(RESUME_HOOK, identity, resumeTime, iteratorData.add)
		end

		if not isThinkHookAdded then
			thinkHookStartTime = CurTime()
			isThinkHookAdded = true
			hook.Add(THINK_HOOK, THINK_HOOK_KEY, ThinkCall)
		end
		
		return true
	end
end

UPar.SetRenderIterAddiKV = function(identity, ...)
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

UPar.GetRenderIterAddiKV = function(identity, ...)
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

UPar.SetRenderIterEndTime = function(identity, endTime, silent)
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

UPar.MergeRenderIterAddiKV = function(identity, data)
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(istable(data), 'data must be a table.')

	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end

	table.Merge(iteratorData.add, data)
	
	return true
end