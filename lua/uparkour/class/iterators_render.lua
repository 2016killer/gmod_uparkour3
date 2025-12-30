--[[
	作者:白狼
	2025 12 30
--]]

UPar.PDVMIterators = UPar.PDVMIterators or {}
local Iterators = UPar.PDVMIterators

local isThinkHookAdded = false
local thinkHookStartTime = 0
local THINK_HOOK_KEY = 'upar.iterators'
local THINK_HOOK = 'PreDrawViewModel'
local POP_HOOK = 'UParPDVMIteratorPop'
local PUSH_HOOK = 'UParPDVMIteratorPush'
local PAUSE_HOOK = 'UParPDVMIteratorPause'
local END_TIME_CHANGED_HOOK = 'UParPDVMIteratorEndTimeChanged'
local RESUME_HOOK = 'UParPDVMIteratorResume'

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

	-- 多次遍历防止交叉感染
	for i = #removeIdentities, 1, -1 do
		local identity, data, _ = unpack(removeIdentities[i])
		if Iterators[identity] ~= data then
			print(string.format('[UPar.PDVMIterators]: warning: iterator "%s" changed in think call', identity))
			table.remove(removeIdentities, i)
			removeThinkFlag = false
		else
			Iterators[identity] = nil
		end
	end

	for _, v in ipairs(removeIdentities) do
		local identity, data, reason = unpack(v)

		if Iterators[identity] ~= nil then
			print(string.format('[UPar.PDVMIterators]: warning: iterator "%s" changed in other', identity))
			removeThinkFlag = false
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
			print(string.format('[UPar.PDVMIterators]: warning: iterator "%s" changed in other', identity))
			removeThinkFlag = false
			continue
		end

		hook.Run(POP_HOOK, identity, curTime, data.add, reason) 
		data.add = nil
	end

	if removeThinkFlag then
		hook.Remove(THINK_HOOK, THINK_HOOK_KEY)
		isThinkHookAdded = false
	end
end

UPar.PushPDVMIterator = function(identity, iterator, addition, timeout, clear)
	assert(isfunction(iterator), 'iterator must be a function.')
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(isnumber(timeout), 'timeout must be a number.')
	if timeout <= 0 then 
		print('[UPar.PushPDVMIterator]: warning: timeout <= 0!') 
		return false
	end

	local old = Iterators[identity]
	if old then hook.Run(POP_HOOK, identity, CurTime(), old.add, 'OVERRIDE') end

	local endtime = timeout + CurTime()
	addition = istable(addition) and addition or {}
	hook.Run(PUSH_HOOK, identity, endtime, addition)

	Iterators[identity] = {f = iterator, et = endtime, add = addition, clear = clear}
	
	if not isThinkHookAdded then
		thinkHookStartTime = CurTime()
		isThinkHookAdded = true
		hook.Add(THINK_HOOK, THINK_HOOK_KEY, ThinkCall)
	end
	
	return true
end

UPar.PopPDVMIterator = function(identity, silent)
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

UPar.GetPDVMIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity]
end

UPar.IsPDVMIteratorExist = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity] ~= nil
end

UPar.PausePDVMIterator = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end
	
	if iteratorData.pt then
		return 0
	end

	local pauseTime = CurTime()
	iteratorData.pt = pauseTime

	if not silent then
		hook.Run(PAUSE_HOOK, identity, pauseTime, iteratorData.add)
	end
	
	return true
end

UPar.ResumePDVMIterator = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end

	if not iteratorData.pt then
		return 0
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

UPar.SetPDVMIterAddiKV = function(identity, ...)
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

UPar.GetPDVMIterAddiKV = function(identity, ...)
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

UPar.SetPDVMIterEndTime = function(identity, endTime, silent)
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

UPar.MergePDVMIterAddiKV = function(identity, data)
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(istable(data), 'data must be a table.')

	local iteratorData = Iterators[identity]
	if not iteratorData then
		return false
	end

	table.Merge(iteratorData.add, data)
	
	return true
end