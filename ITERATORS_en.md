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

## 1.  Push Render Iterator
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.PushRenderIterator(**any** identity, **function** iterator, **any** addition, **number** timeout, **function** clear)
```note
Used to push a render iterator, which will be executed in the PostRender frame loop.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type, supporting custom types for special business requirements);
2.  iterator: Frame loop callback function with parameters (dt<delta time>, curTime<current time>, add<additional data>);
3.  addition: Additional data, non-table types will be automatically converted to empty tables;
4.  timeout: Timeout duration (in seconds, must be greater than 0, otherwise returns false);
5.  clear: Iterator cleanup callback function with parameters (identity, curTime, add, reason<cleanup reason>).

If an iterator with the same identity already exists, the UParRenderIteratorPop hook will be triggered first and the old iterator will be overwritten.
If there are no valid iterators currently, the PostRender hook will be automatically added.
Returns true if the push is successful, and returns false if the timeout parameter is invalid (<= 0).
```

## 2.  Pop Render Iterator Manually
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.PopRenderIterator(**any** identity, **boolean** silent)
```note
Used to manually remove the render iterator with the specified identifier.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type);
2.  silent: Whether to execute silently, the UParRenderIteratorPop hook will not be triggered when set to true.

If the iterator exists, the cleanup callback (clear) will be executed first, then the hook will be triggered or not according to the silent parameter, and finally returns true.
If the iterator does not exist, returns false directly.
The additional data (add) of the iterator will be automatically nullified after removal to reduce memory redundancy.
```

## 3.  Get Render Iterator Data
![shared](./materials/upgui/shared.jpg)
**table/nil** UPar.GetRenderIterator(**any** identity)
```note
Used to obtain the complete data of the render iterator corresponding to the specified identifier.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type).

If the iterator exists, returns the iterator data table (including fields: f<callback function>, et<end time>, add<additional data>, clear<cleanup callback>, pt<pause time>).
If the iterator does not exist, returns nil.
```

## 4.  Check If Render Iterator Exists
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.IsRenderIteratorExist(**any** identity)
```note
Used to quickly determine whether the render iterator with the specified identifier exists.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type).

Returns true if the iterator exists, and returns false if the iterator does not exist.
```

## 5.  Pause Render Iterator
![shared](./materials/upgui/shared.jpg)
**boolean/number** UPar.PauseRenderIterator(**any** identity, **boolean** silent)
```note
Used to pause the render iterator with the specified identifier; the iterator will no longer participate in the PostRender frame loop execution after pausing.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type);
2.  silent: Whether to execute silently, the UParRenderIteratorPause hook will not be triggered when set to true.

Return Value Description:
1.  false: The iterator does not exist;
2.  0: The iterator is already in a paused state (a truthy value in Lua, adapted for chained judgment like succ = succ and xxx);
3.  true: The iterator is paused successfully.

The current time (pt field) will be recorded when pausing, which is used to compensate the timeout duration when resuming.
```

## 6.  Resume Render Iterator
![shared](./materials/upgui/shared.jpg)
**boolean/number** UPar.ResumeRenderIterator(**any** identity, **boolean** silent)
```note
Used to resume the paused render iterator with the specified identifier.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type);
2.  silent: Whether to execute silently, the UParRenderIteratorResume hook will not be triggered when set to true.

Return Value Description:
1.  false: The iterator does not exist;
2.  0: The iterator is not in a paused state (a truthy value in Lua, adapted for chained judgment like succ = succ and xxx);
3.  true: The iterator is resumed successfully.

The timeout duration will be automatically compensated when resuming (new end time = resume time + remaining timeout duration) to ensure the accuracy of the timeout logic.
If there are no valid iterators currently, the PostRender hook will be automatically added after resumption.
```

## 7.  Set Nested Additional Data of Iterator
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.SetRenderIterAddiKV(**any** identity, **...** varargs)
```note
Used to set the nested additional data of the render iterator, supporting assignment with multi-level key paths.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type);
2.  varargs: Variable arguments, requiring at least 1 key + 1 value (e.g.: SetRenderIterAddiKV(ident, "a", "b", 10) corresponds to add.a.b = 10).

Returns false directly if the table corresponding to the intermediate nested key does not exist.
Returns false if the iterator does not exist.
Returns true if the setting is successful.
Does not support automatic creation of nested tables, only supports assignment for existing nested paths.
```

## 8.  Get Nested Additional Data of Iterator
![shared](./materials/upgui/shared.jpg)
**any/nil** UPar.GetRenderIterAddiKV(**any** identity, **...** varargs)
```note
Used to obtain the nested additional data of the render iterator, supporting query with multi-level key paths.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type);
2.  varargs: Variable arguments, requiring at least 1 key (e.g.: GetRenderIterAddiKV(ident, "a", "b") corresponds to querying add.a.b).

Returns nil if the table corresponding to the intermediate nested key does not exist.
Returns nil if the iterator does not exist.
Returns the value of the corresponding key if the query is successful.
```

## 9.  Set Iterator Timeout End Time
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.SetRenderIterEndTime(**any** identity, **number** endTime, **boolean** silent)
```note
Used to directly set the timeout end time of the specified render iterator.
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type);
2.  endTime: New timeout end time (in timestamp format);
3.  silent: Whether to execute silently, the UParRenderIteratorEndTimeChanged hook will not be triggered when set to true.

Returns true if the iterator exists and the end time is set successfully.
Returns false if the iterator does not exist.
```

## 10. Merge Iterator Additional Data
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.MergeRenderIterAddiKV(**any** identity, **table** data)
```note
Used to merge the additional data of the render iterator, implemented based on the GLua table.Merge method (shallow merge).
Parameter Description:
1.  identity: Unique identifier of the iterator (any non-nil type);
2.  data: Additional data to be merged (must be a table type, otherwise an assertion error will be thrown).

Returns true if the iterator exists and the data is merged successfully.
Returns false if the iterator does not exist.
```