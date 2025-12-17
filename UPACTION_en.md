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

## About UPAction Interface Implementation
The parameter alignment syntax used in version 2.1.0 is no longer adopted here. Although sequence tables perform well in network transmission, frequent `unpack` operations are cumbersome and the code is difficult to maintain. Therefore, we revert to the approach used in version 1.0.0.

This approach also offers several advantages. For instance, certain persistent data can be directly stored in tables, and inherited data can also be placed in them directly—this **greatly reduces development difficulty**.


## Optional Parameters
![client](./materials/upgui/client.jpg)
**UPAction**.icon: ***string*** Icon  
![client](./materials/upgui/client.jpg)
**UPAction**.label: ***string*** Name  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAACreat: ***string*** Creator  
![client](./materials/upgui/client.jpg)
**UPAction**.AAADesc: ***string*** Description  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAContrib: ***string*** Contributor  
![shared](./materials/upgui/shared.jpg)
**UPAction**.TrackId: ***int*** or ***string*** Track ID  
```note
Default value is 0. When actions with the same TrackId are called simultaneously, interruption judgment will be initiated.
```

![client](./materials/upgui/client.jpg)
**UPAction**.SundryPanels ***table***
```lua 
-- Example:
if CLIENT then
	local function ExamplePanel(self, panel)
		panel:Help('This is example')
	end

	action.SundryPanels = {
		{
			label = '#upgui.dev.example',
			func = ExamplePanel,
		}
	}
end
```

![client](./materials/upgui/client.jpg)
**UPAction**:ConVarsPanelOverride(**DForm** panel)
```note
Custom parameter interfaces can be created here (e.g., building parameter editors with complex structures).
```
```lua 
if CLIENT then
    function action:ConVarsPanelOverride(panel)
        panel:Help(self.Name)
    end
end
```

![client](./materials/upgui/client.jpg)
**UPAction**:ConVarWidgetExpand(**int** idx, **table** cvCfg, **panel** originWidget, **DForm** panel)
```note
可以在这里拓展参数界面的控件, 或者覆盖默认
```
```lua 
if CLIENT then
    function action:ConVarWidgetExpand(idx, cvCfg, originWidget, panel)
        if IsValid(originWidget) and ispanel(originWidget) and idx == 1 then
            local label = vgui.Create('DLabel')
            label:SetText('#upgui.dev.cv_widget_expand')
            label:SetTextColor(Color(0, 150, 0))

            return label
        end
    end
end
```

## Methods to Implement
![shared](./materials/upgui/shared.jpg) 
***table*** **UPAction**:Check(**Player** ply, **any** data)  
```note
After returning a table, the process proceeds to the Start phase.
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Start(**Player** ply, **table** checkResult)
```note
Executed once when the action starts, then the process enters the Think phase.
```

![server](./materials/upgui/server.jpg)
***any*** **UPAction**:Think(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)
```note
Returning a truthy value proceeds to the Clear phase; otherwise, the current state is maintained.
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Clear(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
Called in scenarios such as: Think returning a truthy value, forced termination, or interruption.
- When forcefully ended: interruptSource is `true`.
- When interrupted: interruptSource is a `table`, and interruptData is the checkResult of the interrupter.
```


## Available Methods
![shared](./materials/upgui/shared.jpg)
**UPAction**:InitCVarPredictionMode(**string** default)
```note
Will appear in the Q menu after initialization.
- false: Use server-side prediction
- true: Use client-side prediction

The parameter itself has no inherent function and needs to be handled manually.
```

![client](./materials/upgui/client.jpg)
**UPAction**:InitCVarKeybind(**string** default)
```note
Will appear in the Q menu after initialization.
Separate key combinations with spaces.
Example: '33 83 65' represents KEY_W + KEY_LCONTROL + KEY_SPACE.

The parameter itself has no inherent function and needs to be handled manually.
```

![server](./materials/upgui/server.jpg)
UPar.ActChangeRhythm(**Player** ply, **UPAction** action, **any** customData)
```note
Should be called manually in `action:Think`. This triggers `effect:OnRhythmChange` and automatically synchronizes with the client.
Calling it every frame is not recommended.

Typically used for actions with variable rhythms (e.g., Double Vault).
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:InitConVars(**table** config)
```lua
-- Example:
-- Will appear in the Action Editor after initialization.
-- Accessible via `self.ConVars`.
action:InitConVars(
    {
        {
            name = 'example_numslider',
            default = '0',
            widget = 'NumSlider',
            min = 0, max = 1, decimals = 2,
            help = true
        },

	    {
            name = 'example_color',
            default = '0',
            widget = 'UParColorEditor'
        },

	    {
            name = 'example_ang',
            default = '0',
            widget = 'UParAngEditor',
			min = -1, max = 1, decimals = 1, interval = 0.1,
        },

	    {
            name = 'example_vec',
            default = '0',
            widget = 'UParVecEditor',
			min = -2, max = 2, decimals = 2, interval = 0.5,
        },

	    {
            name = 'example_invisible',
            default = '0',
            widget = 'NumSlider',
			invisible = true,
        },

	    {
            name = 'example_admin',
            default = '0',
            widget = 'NumSlider',
			admin = true,
        }
    }
) 
```

![client](./materials/upgui/client.jpg)
**UPAction**:RegisterPreset(**table** preset)
```lua
if CLIENT then
	action:RegisterPreset(
		{
			AAAACreat = 'Miss DouBao',
			AAAContrib = 'Zack',

			label = '#upgui.dev.example',
			values = {
				['example_numslider'] = '0.5'
			}
		}
	) 
end
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:AddConVar(**table** cvCfg)
```lua
action:AddConVar({
    name = 'example_other',
    widget = 'NumSlider'
})
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:RemoveConVar(**string** cvName)
```lua
action:RemoveConVar('example_other')
```