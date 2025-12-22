--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 总调度器 ===============
local ClimbDetector = UPar.ClimbDetector
local IsStartSolid = UPar.IsStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec

local action = UPAction:Register('upctrl', {
	AAAACreat = '白狼',
	AAADesc = 'upgui.act.ctrl.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upgui.act.ctrl',
	defaultDisabled = false,
	defaultPredictionMode = false
})

action:InitConVars({
	{
		name = 'los_cos',
		label = '#upgui.act.los_cos',
		default = '0.64',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2,
		help = '#upgui.act.los_cos.help'
	},

	{
		name = 'tick_time',
		label = '#upgui.act.tick_time',
		default = '0.1',
		widget = 'NumSlider',
		min = 0, max = 3600, decimals = 2
	},

})

function action:Trigger()

end

if SERVER then
	hook.Add('PlayerButtonDown', 'upar.act.ctrl', function(ply, button)
		print(ply)
		// print(input.GetKeyName(button))
		print(button)
	end)
end

if CLIENT then


	UPar.SeqHookAdd('UParActCVarWidget_upctrl', 'default', function(cvCfg, panel)
		if cvCfg.name == 'los_cos' then
			local created = UPar.SeqHookRun('UParActCVarWidget', 'upctrl', cvCfg, panel)
			if not created then
				return
			end

			local predi = panel:ControlHelp('')
			predi.Think = function(self)
				if CurTime() < (self.NextThinkTime or 0) then
					return
				end

				self.NextThinkTime = CurTime() + 0.5
	
				self:SetText(string.format('%s: %s °', 
					language.GetPhrase('#upgui.predi'), 
					math.Round(math.acos(action.ConVars.los_cos:GetFloat()) * 180 / math.pi, 2)
				))
			end

			predi.OnRemove = function(self)
				self.NextThinkTime = nil
			end

			return true
		end
	end)
end

