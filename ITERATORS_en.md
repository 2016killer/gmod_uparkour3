<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## Table of Contents

<a href="./UPACTION_en.md">UPAction</a>  
<a href="./UPEFFECT_en.md">UPEffect</a>  
<a href="./SERHOOK_en.md">SeqHook</a>  
<a href="./HOOK_en.md">Hook</a>  
<a href="./LRU_en.md">LRU</a>  
<a href="./CUSTOMEFFECT_en.md">Custom Effect</a>  
<a href="./UPMANIP_en.md">UPManip</a>  
<a href="./UPKEYBOARD_en.md">UPKeyboard</a>  
<a href="./ITERATORS_en.md">Iterators</a>  


# Iterators 

## 1. Module Overview
![shared](./materials/upgui/shared.jpg)
### 1.1 Core Purpose
This module is an iterator management tool implemented based on the GMOD `Think` hook. It supports automatic execution, timeout control, pause/resumption of iterators, and additional data operations. There is no need to manually call iterator functions in loops, reducing business development costs.
### 1.2 Applicable Scenarios
- Cyclic business logic on the server/client (e.g., player state monitoring, NPC AI behavior, animation fade-in/fade-out, scheduled task execution)
- Asynchronous logic that requires precise control of execution duration and supports pause/resumption
### 1.3 Dependency Description
No third-party dependencies. Only relies on GMOD built-in APIs (such as `CurTime`/`hook`/`istable`/`table.Merge`) and standard Lua syntax, which can be directly integrated and used.

## 2. Core API Usage Instructions
### 2.1 Add Iterator: `UPar.PushIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.PushIterator(**identity** identity, **function** iterator, **table** addition, **number** timeout)
#### Purpose
Add a new iterator. If the `identity` already exists, the old iterator will be overwritten and the `UParIteratorPop` hook will be triggered.
#### Parameter Description
| Parameter Name | Type       | Required | Description                                                                 |
|----------------|------------|----------|-----------------------------------------------------------------------------|
| identity       | any        | Yes      | Unique identifier of the iterator (cannot be nil, used to query/operate the iterator later) |
| iterator       | function   | Yes      | Iterator execution function (driven by the `Think` hook every frame; parameters: dt (frame interval), curTime (current time), add (additional data)) |
| addition       | table/any  | No       | Additional data of the iterator (automatically converted to an empty table to store business-related data) |
| timeout        | number     | Yes      | Iterator timeout duration (in seconds, must be greater than 0; the iterator will be automatically removed after timeout) |
#### Return Value
`true` (added successfully) / `false` (timeout ≤ 0, failed to add)
#### Usage Example
```lua
-- Example: Add a player position monitoring iterator
local playerIterId = "player_pos_monitor_" .. LocalPlayer():SteamID()
UPar.PushIterator(playerIterId, function(dt, curTime, add)
    -- Iterator logic: Print the player's current position
    local ply = add.ply
    if IsValid(ply) then
        print("Player position: " .. tostring(ply:GetPos()))
    else
        return true -- Player is invalid, actively terminate the iterator
    end
end, {ply = LocalPlayer()}, 30) -- Timeout duration: 30 seconds
```

### 2.2 Remove Iterator: `UPar.PopIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.PopIterator(**identity** identity, **bool** silent)
#### Purpose
Manually remove the iterator with the specified identifier.
#### Parameter Description
| Parameter Name | Type   | Required | Description                                                                 |
|----------------|--------|----------|-----------------------------------------------------------------------------|
| identity       | any    | Yes      | Unique identifier of the iterator                                           |
| silent         | bool   | No       | Silent mode (true: do not trigger the `UParIteratorPop` hook; false/default: trigger the hook) |
#### Return Value
`true` (iterator exists and is removed successfully) / `false` (iterator does not exist)
#### Usage Example
```lua
-- Example: Manually remove the player position monitoring iterator (non-silent mode)
local playerIterId = "player_pos_monitor_" .. LocalPlayer():SteamID()
local isRemoved = UPar.PopIterator(playerIterId, false)
if isRemoved then
    print("Iterator removed successfully")
end
```

### 2.3 Query Iterator
#### 2.3.1 `UPar.GetIterator`
![shared](./materials/upgui/shared.jpg)
**table/nil** UPar.GetIterator(**identity** identity)
##### Purpose
Obtain the complete data of the specified iterator (including function, end time, additional data, etc.)
##### Parameter
`identity`: Unique identifier of the iterator (cannot be nil)
##### Return Value
Iterator data table (exists) / nil (does not exist)
##### Example
```lua
local iterData = UPar.GetIterator(playerIterId)
if iterData then
    print("Iterator end time: " .. iterData.et)
end
```

#### 2.3.2 `UPar.IsIteratorExist`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.IsIteratorExist(**identity** identity)
##### Purpose
Determine whether the specified iterator exists.
##### Parameter
`identity`: Unique identifier of the iterator (cannot be nil)
##### Return Value
`true` (exists) / `false` (does not exist)
##### Example
```lua
if UPar.IsIteratorExist(playerIterId) then
    print("Iterator exists, subsequent operations can be performed")
end
```

### 2.4 Pause/Resume Iterator
#### 2.4.1 `UPar.PauseIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.PauseIterator(**identity** identity, **bool** silent)
##### Purpose
Pause the specified iterator (the iterator function will no longer be executed after pausing)
##### Parameter
| Parameter Name | Type   | Required | Description                                                                 |
|----------------|--------|----------|-----------------------------------------------------------------------------|
| identity       | any    | Yes      | Unique identifier of the iterator                                           |
| silent         | bool   | No       | Silent mode (true: do not trigger the `UParIteratorPause` hook; false/default: trigger the hook) |
##### Return Value
`true` (paused successfully) / `false` (iterator does not exist)
##### Example
```lua
-- Pause the iterator in silent mode
UPar.PauseIterator(playerIterId, true)
```

#### 2.4.2 `UPar.ResumeIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.ResumeIterator(**identity** identity, **bool** silent)
##### Purpose
Resume a paused iterator (automatically compensate for the timeout duration to offset the pause time)
##### Parameter
| Parameter Name | Type   | Required | Description                                                                 |
|----------------|--------|----------|-----------------------------------------------------------------------------|
| identity       | any    | Yes      | Unique identifier of the iterator                                           |
| silent         | bool   | No       | Silent mode (true: do not trigger the `UParIteratorResume` hook; false/default: trigger the hook) |
##### Return Value
`true` (resumed successfully) / `false` (iterator does not exist/not paused)
##### Example
```lua
-- Resume the iterator in non-silent mode
UPar.ResumeIterator(playerIterId, false)
```

### 2.5 Additional Data Operations
#### 2.5.1 `UPar.SetIterAddiKV`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.SetIterAddiKV(**identity** identity, ...)
##### Purpose
Set **multi-level nested key-value** for the iterator's additional data
##### Parameter
| Parameter Name | Type   | Required | Description                                                                 |
|----------------|--------|----------|-----------------------------------------------------------------------------|
| identity       | any    | Yes      | Unique identifier of the iterator                                           |
| ...            | any    | Yes      | Variable parameters (at least 2, format: multi-level key path + target key + value to assign) |
##### Return Value
`true` (set successfully) / `false` (iterator does not exist/invalid nested path)
##### Example
```lua
-- Set add.player.pos.x = 100 for the iterator's additional data
UPar.SetIterAddiKV(playerIterId, "player", "pos", "x", 100)
```

#### 2.5.2 `UPar.GetIterAddiKV`
![shared](./materials/upgui/shared.jpg)
**any/nil** UPar.GetIterAddiKV(**identity** identity, ...)
##### Purpose
Query **multi-level nested key-value** from the iterator's additional data
##### Parameter
| Parameter Name | Type   | Required | Description                                                                 |
|----------------|--------|----------|-----------------------------------------------------------------------------|
| identity       | any    | Yes      | Unique identifier of the iterator                                           |
| ...            | any    | Yes      | Variable parameters (at least 2, format: multi-level key path + target key) |
##### Return Value
Value corresponding to the target key (exists) / nil (iterator does not exist/invalid nested path/key does not exist)
##### Example
```lua
-- Query add.player.pos.x
local xPos = UPar.GetIterAddiKV(playerIterId, "player", "pos", "x")
```

#### 2.5.3 `UPar.MergeIterAddiKV`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.MergeIterAddiKV(**identity** identity, **table** data)
##### Purpose
Batch merge key-value pairs into the iterator's additional data (shallow merge)
##### Parameter
| Parameter Name | Type   | Required | Description                                                                 |
|----------------|--------|----------|-----------------------------------------------------------------------------|
| identity       | any    | Yes      | Unique identifier of the iterator                                           |
| data           | table  | Yes      | Source table to be merged (key-value pairs will overwrite the same-named keys in the additional data and add new keys) |
##### Return Value
`true` (merged successfully) / `false` (iterator does not exist)
##### Example
```lua
-- Batch update top-level fields of additional data
UPar.MergeIterAddiKV(playerIterId, {
    hp = 150,
    mp = 100,
    state = "alive"
})
```

### 2.6 Modify Iterator End Time: `UPar.SetIterEndTime`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.SetIterEndTime(**identity** identity, **number** endTime, **bool** silent)
#### Purpose
Dynamically modify the absolute end time of the iterator
#### Parameter
| Parameter Name | Type   | Required | Description                                                                 |
|----------------|--------|----------|-----------------------------------------------------------------------------|
| identity       | any    | Yes      | Unique identifier of the iterator                                           |
| endTime        | number | Yes      | New absolute end time (need to pass `CurTime() + relative seconds` instead of directly passing relative seconds) |
| silent         | bool   | No       | Silent mode (true: do not trigger the `UParIteratorEndTimeChanged` hook; false/default: trigger the hook) |
#### Return Value
`true` (modified successfully) / `false` (iterator does not exist)
#### Example
```lua
-- Extend the iterator's timeout by 10 seconds
local newEndTime = CurTime() + 10
UPar.SetIterEndTime(playerIterId, newEndTime, false)
```

## 3. Key Usage Notes
1. **Iterator Function Termination Rule**: When the iterator function returns `true`, it will be automatically removed (active termination); when it returns `nil/false`, it will continue to execute until timeout.
2. **Timeout Explanation**: The `timeout` of `UPar.PushIterator` is a **relative time** (in seconds), which will be automatically converted to `CurTime() + timeout` (absolute time) for storage; the `endTime` of `UPar.SetIterEndTime` is an **absolute time**, and the relative offset needs to be calculated manually.
3. **Pause/Resume Compensation**: When the iterator is resumed, the timeout duration will be automatically compensated (`new end time = resume time + (original end time - pause time)`), ensuring the effective execution duration remains unchanged.
4. **Additional Data Merge Feature**: `UPar.MergeIterAddiKV` performs a **shallow merge**; nested tables will not be merged recursively, and only tables corresponding to the same-named keys will be directly overwritten.
5. **Performance Optimization**: When there are no active iterators, the module will automatically remove the `Think` hook to avoid invalid performance consumption; when the first iterator is added, the `Think` hook will be automatically registered.
6. **Parameter Validation**: All APIs use `assert` to verify that `identity` is not nil. Illegal parameters will trigger an assertion error. It is recommended to use `UPar.IsIteratorExist` to check if the iterator exists before use.