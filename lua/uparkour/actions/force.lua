--[[
	作者:白狼
	2025 12 12
]]--

-- ==================== 强制中断 ===============
local action = UPAction:new({
	Name = 'Force',
	Check = UPar.tablefunc,
	Think = UPar.tablefunc,
})
action:Register()

UPar.SeqHookAdd('UParInterrupt', 'force', function(ply, _, _, action)
    if action.Name == 'Force' then return true end
end, 0)


concommand.Add('up_forceend', ForceEnd)
hook.Add('PlayerSpawn', 'upar.clear', ForceEnd)
hook.Add('PlayerDeath', 'upar.clear', ForceEnd)
hook.Add('PlayerSilentDeath', 'upar.clear', ForceEnd)