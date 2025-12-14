<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## 目录

<a href="./UPACTION.md">UPAction</a>  
<a href="./UPEFFECT.md">UPEffect</a>  
<a href="./SERHOOK.md">SeqHook</a>  
<a href="./HOOK.md">Hook</a>  
<a href="./LIFECYCLE.md">Lifecycle</a>  
<a href="./LRU.md">LRU</a>  

# UPEffect类

## 可选参数  

![client](materials/upgui/client.jpg)
**UPEffect**.icon: ***string*** 图标  
![client](materials/upgui/client.jpg)
**UPEffect**.label: ***string*** 名称  
![client](materials/upgui/client.jpg)
**UPEffect**.AAACreat: ***string*** 创建者  
![client](materials/upgui/client.jpg)
**UPEffect**.AAADesc: ***string*** 描述  
![client](materials/upgui/client.jpg)
**UPEffect**.AAAContrib: ***string*** 贡献者  


![client](materials/upgui/client.jpg)
**UPEffect**.PreviewKVVisible: ***table***  
```lua
-- 预览界面显示AAACreat为红色
-- 隐藏AAADesc
-- 正常显示AAAContrib
effect.PreviewKVVisible = {
    AAACreat = Color(255, 0, 0),
    AAADesc = false,
    AAAContrib = nil
}
```

![client](materials/upgui/client.jpg)
**UPEffect**.PreviewKVExpand: ***function***  
```lua
-- 覆盖默认键值对预览
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
-- 编辑器隐藏AAACreat, AAADesc, AAAContrib
effect.EditorKVVisible = {
    AAACreat = false,
    AAADesc = false,
    AAAContrib = false
}
```

![client](materials/upgui/client.jpg)
**UPEffect**.EditorKVExpand: ***function***  
```lua
-- 覆盖默认键值对编辑
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
预览面板覆盖
```

![client](materials/upgui/client.jpg)
**UPEffect**.EditorPanelOverride(**panel** panel)
```note
编辑器面板覆盖
```

## 需要实现的方法

![shared](materials/upgui/shared.jpg)
**UPEffect**:Start(**Player** ply, **table** checkResult)
```note
会在UPAction:Start后自动调用
```

![shared](materials/upgui/shared.jpg)
**UPEffect**:OnRhythmChange(**Player** ply, **any** customData)
```note
由 UPar.ActChangeRhythm 触发
```

![shared](materials/upgui/shared.jpg)
**UPEffect**:Clear(**Player** ply, **table** checkResult, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
会在UPAction:Clear后自动调用
```