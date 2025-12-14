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
<a href="./CUSTOMEFFECT.md">Custom Effect</a>  

# UPEffect类

## 可选参数  

![client](./materials/upgui/client.jpg)
**UPEffect**.icon: ***string*** 图标  
![client](./materials/upgui/client.jpg)
**UPEffect**.label: ***string*** 名称  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAACreat: ***string*** 创建者  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAADesc: ***string*** 描述  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAAContrib: ***string*** 贡献者  


![client](./materials/upgui/client.jpg)
**UPEffect**.PreviewKVVisible: ***table*** or ***function***  
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
```lua
-- 预览界面显示AAACreat, AAADesc, AAAContrib为红色
-- 过滤val为函数
local filter = {
    AAACreat = Color(255, 0, 0),
    AAADesc = Color(255, 0, 0),
    AAAContrib = Color(255, 0, 0),
}
effect.PreviewKVVisible = function(key, val)
    return filter[key] or !isfunction(val)
end
```


![client](./materials/upgui/client.jpg)
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


![client](./materials/upgui/client.jpg)
**UPEffect**.EditorKVVisible: ***table*** or ***function***  
```lua
-- 编辑器隐藏AAACreat, AAADesc, AAAContrib
effect.EditorKVVisible = {
    AAACreat = false,
    AAADesc = false,
    AAAContrib = false
}
```
```lua
-- 编辑器隐藏AAACreat, AAADesc, AAAContrib, 函数 
local filter = {
    AAACreat = false,
    AAADesc = false,
    AAAContrib = false,
}
effect.EditorKVVisible = function(key, val)
    return filter[key] or !isfunction(val)
end
```

![client](./materials/upgui/client.jpg)
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

![client](./materials/upgui/client.jpg)
**UPEffect**.PreviewPanelOverride(**panel** panel, **panel** effectManager)
```note
预览面板覆盖
```

![client](./materials/upgui/client.jpg)
**UPEffect**.EditorPanelOverride(**panel** panel, **panel** effectManager)
```note
编辑器面板覆盖
```

## 需要实现的方法

![shared](./materials/upgui/shared.jpg)
**UPEffect**:Start(**Player** ply, **table** checkResult)
```note
会在UPAction:Start后自动调用
```

![shared](./materials/upgui/shared.jpg)
**UPEffect**:OnRhythmChange(**Player** ply, **any** customData)
```note
由 UPar.ActChangeRhythm 触发
```

![shared](./materials/upgui/shared.jpg)
**UPEffect**:Clear(**Player** ply, **table** checkResult, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
会在UPAction:Clear后自动调用
```

![shared](./materials/upgui/shared.jpg)
**UPEffect** UPar.RegisterEffectEasy(**string** actName, **string** tarName, **string** name, **table** initData)
```note
这会从已注册的当中找到对应的特效, 自动克隆并覆盖。
将控制台变量 developer 设为 1 可以阻止翻译行为以便查看真实键名
```
```lua
-- 例:
UPar.RegisterEffectEasy(
	'DParkour-Vault', 
	'default',
    'PunchCompat',
	{
		punch = true,
		upunch = false,
        AAACreat = 'Zack',
		AAAContrib = '余智博',
		AAADesc = '禁用upunch, 这可以解决相机冲突问题。',
	}
)
```