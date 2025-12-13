# Implementation of the UPAction Interface  
- Author: 白狼 
- Translator: Miss DouBao  
- Date: December 10, 2025  


This document abandons the parameter-aligned syntax used in version 2.1.0. Although sequence tables performed well in network transmission, frequent unpacking operations were cumbersome and made code maintenance difficult. Therefore, we have reverted to the approach from version 1.0.0.  

This reversion also brings several advantages: for example, persistent data can be directly stored in tables, and inheritable data can be easily integrated. This significantly reduces development complexity.  


# The UPAction Class  

## Parameters  
![client](materials\upgui\client.jpg)
UPAction.icon: ***string*** Icon  
![client](materials\upgui\client.jpg)
UPAction.label: ***string*** Name  
![client](materials\upgui\client.jpg)
UPAction.AAACreat: ***string*** Creator  
![client](materials\upgui\client.jpg)
UPAction.AAADesc: ***string*** Description  
![client](materials\upgui\client.jpg)
UPAction.AAAContrib: ***string*** Contributor  
![shared](materials\upgui\shared.jpg)
UPAction.TrackId: ***int*** Track ID  


## Required Implementation Methods  
![shared](materials\upgui\shared.jpg)
***table*** **UPAction:Check**(**Player** ply, **any** data)  
```note
After returning a table, the process proceeds to Start.
```

![shared](materials\upgui\shared.jpg)
**UPAction:Start**(**Player** ply, **table** checkResult)  
```note
Executed once at startup, then transitions to the Think phase.
```

![server](materials\upgui\server.jpg)
***any*** **UPAction:Think**(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)  
```note
Returning a truthy value triggers the Clear phase; otherwise, the current state is maintained.
```

![shared](materials\upgui\shared.jpg)
**UPAction:Clear**(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **UPAction** interruptSource, **table** interruptData)  
```note
Called in scenarios such as: Think returning a truthy value, forced termination, or interruption.  
- For forced termination: interruptSource is set to true.  
- For interruption: interruptSource is a table, and interruptData is the checkResult of the interrupting entity.
```


## Optional Implementation Methods  
![client](materials\upgui\client.jpg)
**UPAction:ConVarsPanelOverride**(**panel** panel)  
```note
Custom parameter interfaces can be created here (e.g., building parameter editors with complex structures).
```

![client](materials\upgui\client.jpg)
**UPAction.CreateSundryPanels** **table**  
```lua 
-- Example:
action.CreateSundryPanels = {
    {
        label = 'Example', 
        func = function(panel)
            ...
        end
    }
}
```


## Available Methods  
![shared](materials\upgui\shared.jpg)
**UPAction:InitCVarPredictionMode**(**string** default)  
```note
After initialization, it will appear in the Q menu.  
- false: Use server-side prediction.  
- true: Use client-side prediction.  

The parameter itself has no inherent function and requires custom handling.
```

![client](materials\upgui\client.jpg)
**UPAction:InitCVarKeybind**(**string** default)  
```note
After initialization, it will appear in the Q menu.  
Combine keys using spaces (e.g., '33 83 65' represents KEY_W + KEY_LCONTROL + KEY_SPACE).  

The parameter itself has no inherent function and requires custom handling.
```

![server](materials\upgui\server.jpg)
**UPar.ActChangeRhythm**(**Player** ply, **UPAction** action, **any** customData)  
```note
Should be manually called within action:Think. This triggers effect:OnRhythmChange and automatically synchronizes with the client.  
Calling it every frame is not recommended.  

Typically used for actions with variable rhythms (e.g., Double Vault).
```

![shared](materials\upgui\shared.jpg)
**UPAction:InitConVars**(**table** config)  
```note
-- Example:
action:InitConVars(
    {
        {
            name = 'example',
            default = '0.64',
            widget = 'NumSlider',
            min = 0,
            max = 1,
            decimals = 2,
            help = true,
            visible = false,
            client = nil,
            admin = false,
        }
    }
) 

After initialization, it will appear in the Action Editor.  
Access it using self.ConVars.
```


# The UPEffect Class  

![client](materials\upgui\client.jpg)
UPEffect.icon: ***string*** Icon  
![client](materials\upgui\client.jpg)
UPEffect.label: ***string*** Name  
![client](materials\upgui\client.jpg)
UPEffect.AAACreat: ***string*** Creator  
![client](materials\upgui\client.jpg)
UPEffect.AAADesc: ***string*** Description  
![client](materials\upgui\client.jpg)
UPEffect.AAAContrib: ***string*** Contributor  
![shared](materials\upgui\shared.jpg)
UPEffect.TrackId: ***int*** Track ID  


## Required Implementation Methods  
![shared](materials\upgui\shared.jpg)
**UPEffect:Start**(**Player** ply, **table** checkResult)  
```note
Automatically called after UPAction:Start.
```

![shared](materials\upgui\shared.jpg)
**UPEffect:OnRhythmChange**(**Player** ply, **any** customData)  
```note
Automatically called after UPar.ActChangeRhythm.
```

![shared](materials\upgui\shared.jpg)
**UPEffect:Clear**(**Player** ply, **table** checkResult, **bool** or **UPAction** interruptSource, **table** interruptData)  
```note
Automatically called after UPAction:Clear.
```


## Optional Implementation Methods  
![client](materials\upgui\client.jpg)
**UPEffect:PreviewPanelOverride**(**panel** panel)  
```note
Override for the preview panel.
```

![client](materials\upgui\client.jpg)
**UPEffect:EditorPanelOverride**(**panel** panel)  
```note
Override for the editor panel.
```


# Hooks  

## Regular Hooks  
![shared](materials\upgui\shared.jpg)
**bool** **UParRegisterAction**(**string** actName, **UPAction** action)  
```note
Return true to block action registration.
```
```lua
-- Example:
-- Block registration of all actions
hook.Add('UParRegisterAction', 'stop_all', function(actName, action)
    return true
end)
```

![shared](materials\upgui\shared.jpg)
**bool** **UParRegisterEffect**(**string** actName, **string** effName, **UPEffect** effect)  
```note
Return true to block effect registration.
```


## Sequential Hooks  
![shared](materials\upgui\shared.jpg)
**UPar.SeqHookAdd**(**string** eventName, **string** identifier, **function** func, **int** priority)  
```note
Use this to add sequential hooks for events. If the identifier is duplicated and priority is nil, the previous priority will be inherited.
```

![shared](materials\upgui\shared.jpg)
**UPar.SeqHookRemove**(**string** eventName, **string** identifier)  
```note
Remove the hook with the specified identifier.
```

```lua
-- Example:
-- Allow "test_lifecycle" to be interrupted by any other action
-- Priority 0 is the highest
UPar.SeqHookAdd('UParInterrupt', 'test_interrupt', function(ply, playing, playingData, interruptSource, interruptData)
	local playingName = playing.Name
	if playingName ~= 'test_lifecycle' then
		return true
	end
end, 0)
```

![shared](materials\upgui\shared.jpg)
**bool** **UParInterrupt**(**Player** ply, **UPAction** playing, **table** playingData, **bool** or **UPAction** interruptSource)  
```note
Called when the current track is occupied. Return true to allow interruption.
```

![shared](materials\upgui\shared.jpg)
**bool** **UParPreStart**(**Player** ply, **UPAction** action, **table** checkResult)  
```note
Called after UPAction:Check passes. Return true to block action startup.
```

![shared](materials\upgui\shared.jpg)
**bool** **UParStart**(**Player** ply, **UPAction** action, **table** checkResult)  
```note
Called before UPAction:Start. Return true to override the default behavior.
```

![shared](materials\upgui\shared.jpg)
**bool** **UParOnChangeRhythm**(**Player** ply, **UPAction** action, **UPEffect** effect, **any** customData)  
```note
Triggered when UPar.ActChangeRhythm is used. Return true to override the default behavior.
```

![shared](materials\upgui\shared.jpg)
**bool** **UParClear**(**Player** ply, **UPAction** playing, **table** playingData, **CMoveData** mv, **CUserCmd** cmd, **UPAction** interruptSource, **table** interruptData)  
```note
Called before UPAction:Clear. Return true to override the default behavior.
```


# About the Lifecycle  
**UPAction.TrackId**  
```note
This is the core:  
- If two actions are on the same track, an interrupt will be triggered (e.g., if a vault detection is triggered while executing a climb action, an interrupt will occur).  
- If actions are on different TrackIds (e.g., an inspection action), they can run in parallel with climb or vault actions.
```

![uplife](materials\upgui\uplife_en.jpg)  
![uplife2](materials\upgui\uplife2_en.jpg)