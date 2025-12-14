<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## Table of Contents

<a href="./devdoc/UPACTION_en.md">UPAction</a>  
<a href="./devdoc/UPEFFECT_en.md">UPEffect</a>  
<a href="./devdoc/SERHOOK_en.md">SeqHook</a>  
<a href="./devdoc/HOOK_en.md">Hook</a>  
<a href="./devdoc/LIFECYCLE_en.md">Lifecycle</a>  
<a href="./devdoc/LRU_en.md">LRU</a>  
<a href="./devdoc/CUSTOMEFFECT_en.md">Custom Effect</a>  

# UPEffect Class

## Optional Parameters  

![client](../materials/upgui/client.jpg)
**UPEffect**.icon: ***string*** Icon  
![client](../materials/upgui/client.jpg)
**UPEffect**.label: ***string*** Name  
![client](../materials/upgui/client.jpg)
**UPEffect**.AAACreat: ***string*** Creator  
![client](../materials/upgui/client.jpg)
**UPEffect**.AAADesc: ***string*** Description  
![client](../materials/upgui/client.jpg)
**UPEffect**.AAAContrib: ***string*** Contributor  


![client](../materials/upgui/client.jpg)
**UPEffect**.PreviewKVVisible: ***table*** or ***function***  
```lua
-- Display AAACreat in red on the preview interface
-- Hide AAADesc
-- Display AAAContrib normally
effect.PreviewKVVisible = {
    AAACreat = Color(255, 0, 0),
    AAADesc = false,
    AAAContrib = nil
}
```
```lua
-- Display AAACreat, AAADesc, and AAAContrib in red on the preview interface
-- Filter out values (val) that are functions
local filter = {
    AAACreat = Color(255, 0, 0),
    AAADesc = Color(255, 0, 0),
    AAAContrib = Color(255, 0, 0),
}
effect.PreviewKVVisible = function(key, val)
    return filter[key] or not isfunction(val)
end
```

![client](../materials/upgui/client.jpg)
**UPEffect**.PreviewKVExpand: ***function***  
```lua
-- Override default key-value pair preview
effect.PreviewKVExpand = function(key, val, originWidget)
    if IsValid(originWidget) and ispanel(originWidget) then
        originWidget:Remove()
    end

    return vgui.Create('DLabel', tostring(key))
end
```


![client](../materials/upgui/client.jpg)
**UPEffect**.EditorKVVisible: ***table*** or ***function***  
```lua
-- Hide AAACreat, AAADesc, AAAContrib in the editor
effect.EditorKVVisible = {
    AAACreat = false,
    AAADesc = false,
    AAAContrib = false
}
```
```lua
-- Hide AAACreat, AAADesc, AAAContrib, and function-type values in the editor
local filter = {
    AAACreat = false,
    AAADesc = false,
    AAAContrib = false,
}
effect.EditorKVVisible = function(key, val)
    return filter[key] or not isfunction(val)
end
```

![client](../materials/upgui/client.jpg)
**UPEffect**.EditorKVExpand: ***function***  
```lua
-- Override default key-value pair editing
effect.EditorKVExpand = function(key, val, originWidget, obj)
    if IsValid(originWidget) and ispanel(originWidget) then
        originWidget:Remove()
    end

    local entry = vgui.Create('TextEntry')
    entry:SetText(tostring(val))
    entry.OnEnter = function()
        obj[key] = entry:GetText()
    end

    return entry
end
```

![client](../materials/upgui/client.jpg)
**UPEffect**.PreviewPanelOverride(**panel** panel, **panel** effectManager)
```note
Preview panel override
```

![client](../materials/upgui/client.jpg)
**UPEffect**.EditorPanelOverride(**panel** panel, **panel** effectManager)
```note
Editor panel override
```

## Methods to Implement

![shared](../materials/upgui/shared.jpg)
**UPEffect**:Start(**Player** ply, **table** checkResult)
```note
Automatically called after UPAction:Start
```

![shared](../materials/upgui/shared.jpg)
**UPEffect**:OnRhythmChange(**Player** ply, **any** customData)
```note
Triggered by UPar.ActChangeRhythm
```

![shared](../materials/upgui/shared.jpg)
**UPEffect**:Clear(**Player** ply, **table** checkResult, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
Automatically called after UPAction:Clear
```

![shared](../materials/upgui/shared.jpg)
**UPEffect** UPar.RegisterEffectEasy(**string** actName, **string** tarName, **string** name, **table** initData)
```note
This will find the corresponding effect from the registered ones, automatically clone it and overwrite the target.
Set the console variable `developer` to 1 to prevent translation behavior, so that you can view the actual key names.
```
```lua
-- Example:
UPar.RegisterEffectEasy(
	'DParkour-Vault', 
	'default',
    'PunchCompat',
	{
		punch = true,
		upunch = false,
        AAACreat = 'Zack',
		AAAContrib = 'Yu Zhibo',
		AAADesc = 'Disable upunch, which resolves camera conflict issues.',
	}
)
```