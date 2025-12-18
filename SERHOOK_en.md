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
<a href="./LRU_en.md">LRU</a>  
<a href="./CUSTOMEFFECT_en.md">Custom Effect</a>  

## Sequence Hooks

## Operations

![shared](./materials/upgui/shared.jpg)
**int** UPar.SeqHookAdd(**string** eventName, **string** identifier, **function** func, **int** priority)
```note
Use this method to add sequence hooks for events. If the identifier is duplicated and the priority is nil, the previous priority will be inherited.
Return the current priority.
```

![shared](./materials/upgui/shared.jpg)
UPar.SeqHookRemove(**string** eventName, **string** identifier)
```note
Remove the hook with the specified identifier.
```

## Existing Hooks

![shared](./materials/upgui/shared.jpg)
**@Name** UParInterrupt  
***@Params*** 
- ply **Player**  
- playing **UPAction**  
- playingData **table**  
- interruptSource **bool** or **UPAction**    

***@Return***  
- **bool** 
```note
Return true to allow interruption.
```
```lua
-- Example:
-- Allow "test_lifecycle" to be interrupted by any action
-- Priority 0 is the highest
UPar.SeqHookAdd('UParInterrupt', 'test_interrupt', function(ply, playing, playingData, interruptSource)
	local playingName = playing.Name
	if playingName ~= 'test_lifecycle' then
		return true
	end
end, 0)
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParPreStart  
***@Params*** 
- ply **Player**  
- action **UPAction**  
- checkResult **table**    

***@Return***  
- **bool** 
```note
Called after UPAction:Check passes. Return true to prevent the action from starting.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParStart  
***@Params*** 
- ply **Player**  
- action **UPAction**  
- checkResult **table**   

***@Return***  
- **bool** 
```note
Called before UPAction:Start. Return true to override the default behavior.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParClear  
***@Params*** 
- ply **Player**  
- playing **UPAction**  
- playingData **table**  
- mv **CMoveData**  
- cmd **CUserCmd**  
- interruptSource **bool** or **UPAction**   
- interruptData **table**  

***@Return***  
- **bool** 
```note
Called before UPAction:Clear. Return true to override the default behavior.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParVersionCompat  
```note
SeqHookRunAllSafe will be called, which runs all hooks and automatically handles exceptions.
```