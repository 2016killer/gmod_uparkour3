- Author: 白狼
- Translator: Ms. DouBao
- Date: 2025-12-10

# UPAction Class

## I. Key Considerations for Development
### 1.1 Regarding Interface Implementation
The parameter alignment syntax used in version 2.1.0 is no longer adopted here. Although sequential tables perform well in network transmission, their advantages are negligible compared to the overhead caused by high-frequency unpack/pack operations. Therefore, we revert to the parameter-passing method used in version 1.0.0—directly passing hash tables. This approach offers multiple benefits: for example, certain persistent data can be stored directly in the table, or inherited data can be directly included in it.

## II. Interfaces to Be Implemented
```lua
--- Action Pre-Check Interface
--- @param ply Player
--- @param data table
--- @return table checkResult Check result table (Must return a table to proceed to the next cycle)
--- @usage Called on both client and server
function action:Check(ply, data)
    return checkResult
end

--- Action Start Interface
--- @param ply Player
--- @param checkResult table
--- @usage Called on both client and server
function action:Start(ply, checkResult)
    -- Optional implementation; does not affect the workflow
end

--- Core Action Execution Interface
--- @param ply Player
--- @param mv CMoveData
--- @param cmd CUserCmd
--- @param checkResult table
--- @return table endResult Execution result table (Must return a table to proceed to the next cycle)
--- @usage Called only on server
function action:Play(ply, mv, cmd, checkResult)
    return endResult
end

--- Action Cleanup Interface
--- @param ply Player
--- @param endResult table
--- @usage Called on both client and server
function action:Clear(ply, endResult)
    -- Optional implementation; does not affect the workflow
end
```

## III. Additional Optional Interfaces
```lua
--- Custom Parameter Panel Override Interface
--- @param panel table
--- @usage Called only on client
function action:ConVarsPanelOverride(panel)
    -- Customize the parameter panel here
end

--- Additional Parameter Panel Configuration (table structure)
--- @usage Called only on client
-- Additional parameter panels can be added here
action.CreateSundryPanels = {
    {
        label = 'Example', 
        func = function(panel)
            --- @param panel table
            ...
        end
    }
}
```

## IV. Additional Optional Parameters
These parameters have no inherent functionality; they only appear in the Q-menu after initialization and require manual handling:
```lua
action:InitCVarPredictionMode('0') -- By default, we use 'false' for server-side prediction
action:InitCVarKeybind('33 83 65') -- KEY_W + KEY_LCONTROL + KEY_SPACE
```

## V. Available Methods
```lua
--- Update Effect Rhythm (automatically synced to client)
--- @param ply Player
--- @param customData table
--- @usage Called only on server (recommended to call in Play interface)
action:ChangeRhythm(ply, customData) 
```

# UPEffect Class

## I. Interfaces to Be Implemented
```lua
--- Effect Start Interface
--- @param ply Player
--- @param checkResult table
--- @usage Called on both client and server
function effect:Start(ply, checkResult)
    -- Called when the action is triggered
end

--- Effect Rhythm Change Callback Interface
--- @param ply Player
--- @param customData table
--- @usage Called on both client and server
function effect:OnRhythmChange(ply, customData)
    -- Called when rhythm changes, triggered manually via action:ChangeRhythm(ply, customData)
end

--- Effect Cleanup Interface
--- @param ply Player
--- @param endResult table
--- @usage Called on both client and server
function effect:Clear(ply, endResult)
    -- Called when the action ends
end
```

## II. Additional Optional Interfaces
```lua
--- Preview Panel Override Interface
--- @param panel table
--- @usage Called only on client
function effect:PreviewPanelOverride(panel)
end

--- Editor Panel Override Interface
--- @param panel table
--- @usage Called only on client
function effect:EditorPanelOverride(panel)
end
```