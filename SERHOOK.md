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


## 序列钩子

## 操作方法

![shared](materials/upgui/shared.jpg)
UPar.SeqHookAdd(**string** eventName, **string** identifier, **function** func, **int** priority)
```note
使用此添加事件的序列钩子, 如果标识符重复且priority为nil的情况则继承之前的优先级
```

![shared](materials/upgui/shared.jpg)
UPar.SeqHookRemove(**string** eventName, **string** identifier)
```note
移除指定标识符的钩子
```

## 已存在的钩子

![shared](materials/upgui/shared.jpg)
**bool** UParInterrupt(**Player** ply, **UPAction** playing, **table** playingData, **bool** or **UPAction** interruptSource)
```note
返回 true 允许中断
```
```lua
-- 例:
-- 允许 test_lifecycle 被任何动作中断
-- 优先级 0 最高
UPar.SeqHookAdd('UParInterrupt', 'test_interrupt', function(ply, playing, playingData, interruptSource, interruptData)
	local playingName = playing.Name
	if playingName ~= 'test_lifecycle' then
		return true
	end
end, 0)
```

![shared](materials/upgui/shared.jpg)
**bool** UParPreStart(**Player** ply, **UPAction** action, **table** checkResult)
```note
在UPAction:Check通过后调用, 返回 true 阻止动作启动
```

![shared](materials/upgui/shared.jpg)
**bool** UParStart(**Player** ply, **UPAction** action, **table** checkResult)
```note
在UPAction:Start前调用, 返回 true 覆盖默认
```

![shared](materials/upgui/shared.jpg)
**bool** UParOnChangeRhythm(**Player** ply, **UPAction** action, **UPEffect** effect, **any** customData)
```note
使用 UPar.ActChangeRhythm 时触发, 返回 true 覆盖默认
```

![shared](materials/upgui/shared.jpg)
**bool** UParClear(**Player** ply, **UPAction** playing, **table** playingData, **CMoveData** mv, **CUserCmd** cmd, **UPAction** interruptSource, **table** interruptData)
```note
在 UPAction:Clear 前调用, 返回 true 覆盖默认
```
