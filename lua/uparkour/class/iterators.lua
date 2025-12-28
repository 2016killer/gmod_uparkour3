--[[
	作者:白狼
	2025 12 20
--]]
UPar.Iterators = UPar.Iterators or {}
local Iterators = UPar.Iterators

local isThinkHookAdded = false
local thinkHookStartTime = 0
local THINK_HOOK_KEY = 'upar.iterators'


UPar.PushIterator = function(identity, iterator, addition, timeout)
	assert(isfunction(iterator), 'iterator must be a function.')
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(isnumber(timeout), 'timeout must be a number.')

	local endtime = timeout + CurTime()
	
	hook.Run('UParIteratorPush', identity, endtime, addition)

	Iterators[identity] = {f = iterator, et = endtime, add = addition}
	
	if not isThinkHookAdded then
		thinkHookStartTime = CurTime()
		isThinkHookAdded = true
		hook.Add('Think', THINK_HOOK_KEY, function()
			local removeFlag = true
			local curTime = CurTime()
			local dt = curTime - thinkHookStartTime
			
			thinkHookStartTime = curTime

			for identity, data in pairs(Iterators) do
				removeFlag = false

				local iterator, edtime, add = data.f, data.et, data.add
				local succ, result = pcall(iterator, dt, curTime, add)
				
				if not succ then
					ErrorNoHaltWithStack(result)
					Iterators[identity] = nil
					hook.Run('UParIteratorPop', identity, curTime, add, 'ERROR')
				elseif result then
					Iterators[identity] = nil
					hook.Run('UParIteratorPop', identity, curTime, add, nil)
				elseif curTime > edtime then
					Iterators[identity] = nil
					hook.Run('UParIteratorPop', identity, curTime, add, 'TIMEOUT')
				end
			end

			if removeFlag then
				hook.Remove('Think', THINK_HOOK_KEY)
				isThinkHookAdded = false
			end
		end)
	end
end

UPar.PopIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	local iteratorData = Iterators[identity]
	if istable(iteratorData) then
		hook.Run('UParIteratorPop', identity, CurTime(), iteratorData.add, 'MANUAL')
	end
	Iterators[identity] = nil
end

UPar.GetIterator = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity]
end

UPar.IsIteratorExist = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return Iterators[identity] ~= nil
end