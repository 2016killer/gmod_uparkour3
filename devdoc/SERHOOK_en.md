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

## Sequence Hooks

## Operations

![shared](materials/upgui/shared.jpg)
**int** UPar.SeqHookAdd(**string** eventName, **string** identifier, **function** func, **int** priority)
```note
Use this method to add sequence hooks for events. If the identifier is duplicated and the priority is nil, the previous priority will be inherited.
Return the current priority.
```

![shared](materials/upgui/shared.jpg)
UPar.SeqHookRemove(**string** eventName, **string** identifier)
```note
Remove the hook with the specified identifier.
```

## Existing Hooks

![shared](materials/upgui/shared.jpg)
**bool** UParInterrupt(**Player** ply, **UPAction** playing, **table** playingData, **bool** or **UPAction** interruptSource)
```note
Return true to allow interruption.
```
```lua
-- Example:
-- Allow "test_lifecycle" to be interrupted by any action
-- Priority 0 is the highest
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
Called after UPAction:Check passes. Return true to prevent the action from starting.
```

![shared](materials/upgui/shared.jpg)
**bool** UParStart(**Player** ply, **UPAction** action, **table** checkResult)
```note
Called before UPAction:Start. Return true to override the default behavior.
```

![shared](materials/upgui/shared.jpg)
**bool** UParOnChangeRhythm(**Player** ply, **UPAction** action, **UPEffect** effect, **any** customData)
```note
Triggered when UPar.ActChangeRhythm is called. Return true to override the default behavior.
```

![shared](materials/upgui/shared.jpg)
**bool** UParClear(**Player** ply, **UPAction** playing, **table** playingData, **CMoveData** mv, **CUserCmd** cmd, **UPAction** interruptSource, **table** interruptData)
```note
Called before UPAction:Clear. Return true to override the default behavior.
```