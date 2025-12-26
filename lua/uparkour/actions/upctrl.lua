--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 总控制 ===============
local ClimbDetector = UPar.ClimbDetector
local IsPlyStartSolid = UPar.IsPlyStartSolid
local SetMoveControl = UPar.SetMoveControl
local unitzvec = UPar.unitzvec

local controller = UPAction:Register('upctrl', {
	AAAACreat = '白狼',
	AAADesc = '#upctrl.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upctrl',
	defaultDisabled = false,
	defaultPredictionMode = false
})

controller:InitConVars({
	{
		name = 'upctrl_vault_th',
		default = '0.6',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'upctrl_los_cos',
		default = '0.64',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2,
		help = true
	},

	{
		name = 'upctrl_tick_time',
		default = '0.1',
		widget = 'NumSlider',
		min = 0, max = 3600, decimals = 2
	}
})

if CLIENT then
	UPKeyboard.Register('test_uplowclimb', '[]')
	UPar.SeqHookAdd('UParKeyPress', 'test_uplowclimb', function(flags)
		if flags['test_uplowclimb'] then 
			UPar.Trigger(LocalPlayer(), 'uplowclimb')
		end
	end)

	UPKeyboard.Register('test_uphighclimb', '{}')
	UPar.SeqHookAdd('UParKeyPress', 'test_uphighclimb', function(flags)
		if flags['test_uphighclimb'] then 
			UPar.Trigger(LocalPlayer(), 'uphighclimb')
		end
	end)

	UPKeyboard.Register('test_upvault', '[]')
	UPar.SeqHookAdd('UParKeyPress', 'test_upvault', function(flags)
		if flags['test_upvault'] then 
			local obsTrace, climbTrace = UPar.CallAct('uplowclimb', 'Detector', LocalPlayer())
			UPar.Trigger(LocalPlayer(), 'upvault', nil, obsTrace, climbTrace)
		end
	end)


	UPar.SeqHookAdd('UParActCVarWidget_upctrl', 'default', function(cvCfg, panel)
		if cvCfg.name == 'upctrl_los_cos' then
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
					math.Round(math.acos(controller.ConVars.upctrl_los_cos:GetFloat()) * 180 / math.pi, 2)
				))
			end

			predi.OnRemove = function(self)
				self.NextThinkTime = nil
			end

			return true
		end
	end)
end

