<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## Table of Contents

<a href="./UPACTION_en.md">UPAction</a>  
<a href="./UPEFFECT_en.md">UPEffect</a>  
<a href="./SERHOOK_en.md">SeqHook</a>  
<a href="./HOOK_en.md">Hook</a>  
<a href="./LIFECYCLE_en.md">Lifecycle</a>  


# UPEffect Class

## Optional Parameters  

![client](materials/upgui/client.jpg)
**UPEffect**.icon: ***string*** Icon  
![client](materials/upgui/client.jpg)
**UPEffect**.label: ***string*** Name  
![client](materials/upgui/client.jpg)
**UPEffect**.AAACreat: ***string*** Creator  
![client](materials/upgui/client.jpg)
**UPEffect**.AAADesc: ***string*** Description  
![client](materials/upgui/client.jpg)
**UPEffect**.AAAContrib: ***string*** Contributor  


![client](materials/upgui/client.jpg)
**UPEffect**.PreviewKVVisible: ***table***  
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

![client](materials/upgui/client.jpg)
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


![client](materials/upgui/client.jpg)
**UPEffect**.EditorKVVisible: ***table***  
```lua
-- Hide AAACreat, AAADesc, AAAContrib in the editor
effect.EditorKVVisible = {
    AAACreat = false,
    AAADesc = false,
    AAAContrib = false
}
```

![client](materials/upgui/client.jpg)
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

![client](materials/upgui/client.jpg)
**UPEffect**.PreviewPanelOverride(**panel** panel)
```note
Preview panel override
```

![client](materials/upgui/client.jpg)
**UPEffect**.EditorPanelOverride(**panel** panel)
```note
Editor panel override
```

## Methods to Implement

![shared](materials/upgui/shared.jpg)
**UPEffect**:Start(**Player** ply, **table** checkResult)
```note
Automatically called after UPAction:Start
```

![shared](materials/upgui/shared.jpg)
**UPEffect**:OnRhythmChange(**Player** ply, **any** customData)
```note
Triggered by UPar.ActChangeRhythm
```

![shared](materials/upgui/shared.jpg)
**UPEffect**:Clear(**Player** ply, **table** checkResult, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
Automatically called after UPAction:Clear
```