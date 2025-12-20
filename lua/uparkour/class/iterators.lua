--[[
	作者:白狼
	2025 12 20
--]]
UPar.Iterators = UPar.Iterators or {}
local Iterators = UPar.Iterators

local isThinkHookAdded = false
local thinkHookStartTime = 0
local THINK_HOOK_KEY = 'upar.iterators'


UPar.PushIterator = function(identity, iterator, timeout)
	assert(isfunction(iterator), 'iterator must be a function.')
	assert(isstring(identity), 'identity must be a string.')
	assert(isnumber(timeout), 'timeout must be a number.')

	local endtime = timeout + CurTime()
	
	hook.Run('UParIteratorPush', identity, endtime)

	Iterators[identity] = {f = iterator, et = endtime}
	
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

				local iterator, edtime = data.f, data.et
				local succ, result = pcall(iterator, dt, curTime)
				
				if not succ then
					ErrorNoHaltWithStack(result)
					Iterators[identity] = nil
					hook.Run('UParIteratorPop', identity, curTime, 'ERROR')
				elseif result then
					Iterators[identity] = nil
					hook.Run('UParIteratorPop', identity, curTime, nil)
				elseif curTime > edtime then
					Iterators[identity] = nil
					hook.Run('UParIteratorPop', identity, curTime, 'TIMEOUT')
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
	assert(isstring(identity), 'identity must be a string.')

	Iterators[identity] = nil
	hook.Run('UParIteratorPop', identity, CurTime(), 'MANUAL')
end

UPar.GetIterator = function(identity)
	assert(isstring(identity), 'identity must be a string.')
	return Iterators[identity]
end

UPar.IsIteratorExist = function(identity)
	assert(isstring(identity), 'identity must be a string.')
	return Iterators[identity] ~= nil
end