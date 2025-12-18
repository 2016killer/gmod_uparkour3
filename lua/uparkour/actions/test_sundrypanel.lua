--[[
	作者:白狼
	2025 12 18
]]--

-- ==================== 测试其他面板 ===============
if SERVER then return end
if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end

UPar.SeqHookAdd('UParActSundryPanels_test_lifecycle', 'TriggerPanel', function(editor)
	local mainPanel = vgui.Create('DPanel', editor)
	local panel = vgui.Create('DForm', mainPanel)

	panel:SetLabel('#upgui.dev.trigger')
	panel:Dock(FILL)

	local run = panel:Button('#upgui.dev.run_track_0', '')
	run.DoClick = function()
		local act = UPar.GetAction('test_lifecycle')
		UPar.Trigger(LocalPlayer(), act, 'oh shit')
	end
	
	local run_t1 = panel:Button('#upgui.dev.run_track_1', '')
	run_t1.DoClick = function()
		local act = UPar.GetAction('test_lifecycle_t1')
		UPar.Trigger(LocalPlayer(), act, 'oh good')
	end

	local interrupt = panel:Button('#upgui.dev.run_interrupt_0', '')
	interrupt.DoClick = function()
		local act = UPar.GetAction('test_interrupt')
		UPar.Trigger(LocalPlayer(), act)
	end

	local killself = panel:Button('#upgui.dev.killself', '')
	killself.DoClick = function()
		RunConsoleCommand('kill')
	end



	panel:Help('')
	
	editor:AddSheet('#upgui.dev.trigger', 'icon16/arrow_switch.png', mainPanel)
end)

UPar.SeqHookAdd('UParActSundryPanels_test_lifecycle', 'sundrypanel.example.1', function(editor)
	local panel = vgui.Create('DButton', editor)
	panel:Dock(FILL)
	panel:SetText('#upgui.button')
	editor:AddSheet('#upgui.dev.sundry', 'icon16/add.png', panel)
end)

UPar.SeqHookAdd('UParActSundryPanels_test_lifecycle', 'sundrypanel.example.2', function(editor)
	local panel = editor:AddSheet('#upgui.dev.sundry', 'icon16/add.png')
	print(panel)
	panel:Dock(FILL)

	local panel2 = vgui.Create('DForm', panel)
	panel2:SetLabel('#upgui.dev.sundry')
	panel2:Dock(FILL)
	panel2:Help('#upgui.dev.sundry')
	panel2:Help('')
end)