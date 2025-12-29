--[[
	作者:白狼
	2025 12 20
--]]
UPar.Iterators = UPar.Iterators or {}
local Iterators = UPar.Iterators

local isThinkHookAdded = false
local thinkHookStartTime = 0
local THINK_HOOK_KEY = 'upar.iterators'

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

	for _, v in ipairs(removeIdentities) do
		local identity = v[1]
		Iterators[identity] = nil
	end

	for _, v in ipairs(removeIdentities) do
		local identity, data, reason = unpack(v)
		hook.Run('UParIteratorPop', identity, curTime, data.add, reason) 
	end

	if removeThinkFlag then
		hook.Remove('Think', THINK_HOOK_KEY)
		isThinkHookAdded = false
	end
end

UPar.PushIterator = function(identity, iterator, addition, timeout)
	assert(isfunction(iterator), 'iterator must be a function.')
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(isnumber(timeout), 'timeout must be a number.')

	if timeout <= 0 then
		print('[UPar.PushIterator]: warning: timeout <= 0!')
	end

	local old = Iterators[identity]
	if old then hook.Run('UParIteratorPop', identity, CurTime(), old.add, 'OVERRIDE') end

	local endtime = timeout + CurTime()
	
	hook.Run('UParIteratorPush', identity, endtime, addition)

	Iterators[identity] = {f = iterator, et = endtime, add = addition}
	
	if not isThinkHookAdded then
		thinkHookStartTime = CurTime()
		isThinkHookAdded = true
		hook.Add('Think', THINK_HOOK_KEY, ThinkCall)
	end
end

UPar.PopIterator = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')

	local iteratorData = Iterators[identity]
	Iterators[identity] = nil

	if not silent and istable(iteratorData) then
		hook.Run('UParIteratorPop', identity, CurTime(), iteratorData.add, 'MANUAL')
	end
end

UPar.GetIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity]
end

UPar.IsIteratorExist = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity] ~= nil
end

UPar.PauseIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return
	end
	
	local pauseTime = CurTime()
	iteratorData.pt = pauseTime
	hook.Run('UParIteratorPause', identity, pauseTime, iteratorData.add)
end

UPar.ResumeIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if not iteratorData then
		return
	end

	if not iteratorData.pt then
		return
	else
		local resumeTime = CurTime()
		local pauseTime = iteratorData.pt
		iteratorData.pt = nil
		
		iteratorData.et = resumeTime + (iteratorData.et - pauseTime)
		hook.Run('UParIteratorResume', identity, resumeTime, iteratorData.add)

		if not isThinkHookAdded then
			thinkHookStartTime = CurTime()
			isThinkHookAdded = true
			hook.Add('Think', THINK_HOOK_KEY, ThinkCall)
		end
	end
end