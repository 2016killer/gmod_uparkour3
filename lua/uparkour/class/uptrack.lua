--[[
	作者:白狼
	2025 12 12
--]]

local Instances = {}

UPar.AddTrack = function(trackId, appendData)
    local self = Instances[trackId]

    if self then
        self.AppendData = appendData
        return self
    else
        self = {}
        self.AppendData = appendData

        local eventName = SERVER and 'SetupMove' or 'Think'
        local trackDataId = trackId .. '_data'
        hook.Add('SetupMove', trackId, function(ply, mv, cmd)
            local action = ply[trackId]
            if not action then
                return
            end

            local checkResult = ply[trackDataId]
            local succ, err = pcall(action.Think, action, ply, mv, cmd, checkResult)
            if not succ then
                error(err)
                hook.Remove(eventName, trackId)
            end

            local toclear = err
            if toclear then
                local clearData = action:GetClearData(toclear)
                if clearData then
                    ply[trackDataId] = clearData
                end
            end

        end)

        Instances[trackId] = self

        return self
    end
end

UPar.RemoveTrack = function(trackId) 
    Instances[trackId] = nil 
    hook.Remove('SetupMove', trackId)
end

UPar.Tracks = Instances
