--[[
	作者:白狼
	2025 12 09
--]]

-- ==================== 扁平表编辑器 ===============
local FlatTableEditor = {}

function FlatTableEditor:Init2(obj, kVVisible, kvExpand)
	self.obj = obj
	
	if not istable(self.obj) then 
		ErrorNoHaltWithStack(string.format('Invalid obj "%s" (not table)', obj))
		return 
	end

	local keys = {}
	for k, _ in pairs(self.obj) do table.insert(keys, k) end
	table.sort(keys)

	for _, key in ipairs(keys) do
		local val = self.obj[key]

		local keyColor = nil
		if isfunction(kVVisible) then
			keyColor = kVVisible(key, val)
		elseif istable(kVVisible) then
			keyColor = kVVisible[key]
		end

		if keyColor == false then 
			continue 
		end

		local origin = self:CreateKeyValueWidget(key, val, keyColor)
		local expanded = isfunction(kvExpand) and kvExpand(key, val, origin, self.obj, keyColor) or nil
		
		if IsValid(origin) and ispanel(origin) then
			self:AddItem(origin)
		end

		if IsValid(expanded) and ispanel(expanded) then
			self:AddItem(expanded)
		end
	end
	
	self:Help('')
end

function FlatTableEditor:CreateKeyValueWidget(key, val, color)
	local label = self:Help(UPar.SnakeTranslate(key))
	if IsColor(color) then label:SetColor(color) end

	if key == 'VManipAnim' or key == 'VMLegsAnim' then
		-- 针对特殊的键名进行特殊处理
		local target = key == 'VManipAnim' and VManip.Anims or VMLegs.Anims
		local anims = {}
		for a, _ in pairs(target) do table.insert(anims, a) end
		table.sort(anims)
		
		local comboBox = vgui.Create('DComboBox')
		for _, a in ipairs(anims) do comboBox:AddChoice(a, nil, a == val) end
		comboBox.OnSelect = function(_, _, newVal) self:Update(key, newVal) end

		return comboBox
	elseif isstring(val) then
		local textEntry = vgui.Create('DTextEntry')
		textEntry:SetText(val)
		textEntry.OnChange = function()
			local newVal = textEntry:GetText()
			self:Update(key, newVal)
		end

		return textEntry
	elseif isnumber(val) then
		local numberWang = vgui.Create('DNumberWang')
		numberWang:SetValue(val)
		numberWang.OnValueChanged = function(_, newVal)
			self:Update(key, newVal)
		end

		return numberWang
	elseif isbool(val) then
		local checkBox = vgui.Create('DCheckBoxLabel')
		checkBox:SetChecked(val)
		checkBox:SetText('')
		checkBox.OnChange = function(_, newVal)
			self:Update(key, newVal)
		end
		
		return checkBox
	elseif isvector(val) then
		local vecEditor = vgui.Create('UParVecEditor')
		vecEditor:SetValue(val)

		vecEditor.OnChange = function(_, newVal)
			self:Update(key, newVal)
		end

		return vecEditor
	elseif isangle(val) then
		local angEditor = vgui.Create('UParAngEditor')
		angEditor:SetValue(val)

		angEditor.OnChange = function(_, newVal)
			self:Update(key, newVal)
		end

		return angEditor
	else
		return self:ControlHelp('unknown type')
	end
end

function FlatTableEditor:Update(key, newVal)
	self.obj[key] = newVal
	self:OnUpdate(key, newVal)
end

function FlatTableEditor:OnRemove()
	self.obj = nil
end

FlatTableEditor.OnUpdate = UPar.emptyFunc

vgui.Register('UParFlatTableEditor', FlatTableEditor, 'DForm')
FlatTableEditor = nil
-- ==================== 扁平表预览 ===============
local FlatTablePreview = {}
function FlatTablePreview:Init2(obj, kVVisible, kvExpand)
	self.obj = obj

	if not istable(self.obj) then 
		ErrorNoHaltWithStack(string.format('Invalid obj "%s" (not table)', obj))
		return 
	end

	local keys = {}
	for k, v in pairs(self.obj) do table.insert(keys, k) end
	table.sort(keys)

	for _, key in ipairs(keys) do
		local val = self.obj[key]

		local keyColor = nil
		if isfunction(kVVisible) then
			keyColor = kVVisible(key, val)
		elseif istable(kVVisible) then
			keyColor = kVVisible[key]
		end

		if keyColor == false then 
			continue 
		end

		local label = nil
		if key == 'AAADesc'  then 
			label = self:Help(string.format('%s = %s', UPar.SnakeTranslate(key), language.GetPhrase(tostring(val))))
		else
			label = self:Help(string.format('%s = %s', UPar.SnakeTranslate(key), val))
		end

		if IsColor(keyColor) then label:SetColor(keyColor) end

		local expanded = isfunction(kvExpand) and kvExpand(key, val, label, nil, keyColor) or nil
		if IsValid(expanded) and ispanel(expanded) then
			self:AddItem(expanded)
		end
	end

	self:Help('')
end

function FlatTablePreview:OnRemove()
	self.obj = nil
end

vgui.Register('UParFlatTablePreview', FlatTablePreview, 'DForm')
FlatTablePreview = nil