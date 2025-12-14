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


## About UPAction Interface Implementation
The parameter alignment syntax used in version 2.1.0 is no longer adopted here. Although sequence tables perform well in network transmission, frequent `unpack` operations are cumbersome and the code is difficult to maintain. Therefore, we revert to the approach used in version 1.0.0.

This approach also offers several advantages. For instance, certain persistent data can be directly stored in tables, and inherited data can also be placed in them directly—this **greatly reduces development difficulty**.


## Optional Parameters
![client](materials/upgui/client.jpg)
**UPAction**.icon: ***string*** Icon  
![client](materials/upgui/client.jpg)
**UPAction**.label: ***string*** Name  
![client](materials/upgui/client.jpg)
**UPAction**.AAACreat: ***string*** Creator  
![client](materials/upgui/client.jpg)
**UPAction**.AAADesc: ***string*** Description  
![client](materials/upgui/client.jpg)
**UPAction**.AAAContrib: ***string*** Contributor  
![shared](materials/upgui/shared.jpg)
**UPAction**.TrackId: ***int*** Track ID  
```note
Default value is 0. When actions with the same TrackId are triggered simultaneously, interruption judgment will be initiated.
```

![client](materials/upgui/client.jpg)
**UPAction**.SundryPanels ***table***
```lua 
-- Example:
action.SundryPanels = {
    {
        label = 'Example', 
        func = function(panel)
            ...
        end
    }
}
```

![client](materials/upgui/client.jpg)
**UPAction**.ConVarsPanelOverride(**panel** panel)
```note
Custom parameter interfaces can be created here (e.g., building parameter editors with complex structures).
```


## Methods to Implement
![shared](materials/upgui/shared.jpg) 
***table*** **UPAction**:Check(**Player** ply, **any** data)  
```note
After returning a table, the process proceeds to the Start phase.
```

![shared](materials/upgui/shared.jpg)
**UPAction**:Start(**Player** ply, **table** checkResult)
```note
Executed once when the action starts, then the process enters the Think phase.
```

![server](materials/upgui/server.jpg)
***any*** **UPAction**:Think(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)
```note
Returning a truthy value proceeds to the Clear phase; otherwise, the current state is maintained.
```

![shared](materials/upgui/shared.jpg)
**UPAction**:Clear(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
Called in scenarios such as: Think returning a truthy value, forced termination, or interruption.
- When forcefully ended: interruptSource is `true`.
- When interrupted: interruptSource is a `table`, and interruptData is the checkResult of the interrupter.
```


## Available Methods
![shared](materials/upgui/shared.jpg)
**UPAction**:InitCVarPredictionMode(**string** default)
```note
Will appear in the Q menu after initialization.
- false: Use server-side prediction
- true: Use client-side prediction

The parameter itself has no inherent function and needs to be handled manually.
```

![client](materials/upgui/client.jpg)
**UPAction**:InitCVarKeybind(**string** default)
```note
Will appear in the Q menu after initialization.
Separate key combinations with spaces.
Example: '33 83 65' represents KEY_W + KEY_LCONTROL + KEY_SPACE.

The parameter itself has no inherent function and needs to be handled manually.
```

![server](materials/upgui/server.jpg)
UPar.ActChangeRhythm(**Player** ply, **UPAction** action, **any** customData)
```note
Should be called manually in `action:Think`. This triggers `effect:OnRhythmChange` and automatically synchronizes with the client.
Calling it every frame is not recommended.

Typically used for actions with variable rhythms (e.g., Double Vault).
```

![shared](materials/upgui/shared.jpg)
**UPAction**:InitConVars(**table** config)
```lua
-- Example:
-- Will appear in the Action Editor after initialization.
-- Accessible via `self.ConVars`.
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
```