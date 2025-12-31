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

## 1. Push Iterator
**boolean** UPar.PushIterator(**any** identity, **function** iterator, **any** addition, **number** timeout, **function** clear=nil, **string** hookName="Think")
```note
Used to push a new iterator into the iterator manager. If an iterator with the specified identity already exists, it will first trigger the UParIteratorPop hook for the old iterator (marked with reason "OVERRIDE") and override the old iterator. Uses the Think frame loop hook by default, automatically starts the corresponding frame loop listening logic, and the timeout must be a value greater than 0.
```

## 2. Pop Iterator
**boolean** UPar.PopIterator(**any** identity, **boolean** silent=false)
```note
Used to manually remove the iterator with the specified identity. Before removal, it will first execute the iterator's clear callback function (if it exists). In non-silent mode (silent=false), it will trigger the UParIteratorPop hook (marked with reason "MANUAL"). Returns false if the iterator does not exist.
```

## 3. Get Iterator Data
**table** UPar.GetIterator(**any** identity)
```note
Used to retrieve the complete stored data of the iterator with the specified identity. The returned table includes fields: f (iterator function), et (absolute timeout time), add (additional data), clear (cleanup callback), hn (bound hook name), and pt (pause time, optional). Returns nil if the iterator does not exist.
```

## 4. Check Iterator Existence
**boolean** UPar.IsIteratorExist(**any** identity)
```note
Used to quickly check if the iterator with the specified identity exists in the iterator manager. Returns true if it exists, false otherwise.
```

## 5. Pause Iterator
**boolean** UPar.PauseIterator(**any** identity, **boolean** silent=false)
```note
Used to pause the iterator with the specified identity. Paused iterators will not execute logic in the frame loop, and the pause time will be recorded. In non-silent mode (silent=false), it will trigger the UParIteratorPause hook. Returns false if the iterator does not exist.
```

## 6. Resume Iterator
**boolean** UPar.ResumeIterator(**any** identity, **boolean** silent=false)
```note
Used to resume the paused iterator with the specified identity. It will automatically compensate for the pause duration (update the iterator's absolute timeout time) and restart the corresponding frame loop listening. In non-silent mode (silent=false), it will trigger the UParIteratorResume hook. Returns false if the iterator does not exist or is not in a paused state.
```

## 7. Set Nested KV in Iterator Additional Data
**boolean** UPar.SetIterAddiKV(**any** identity, **any** ...)
```note
Used to set multi-level nested key-value pairs in the iterator's additional data. At least 2 parameters are required (supports multi-level table indexing; the last two parameters are the target key and corresponding value respectively). Returns false if the iterator does not exist or the nested table path is invalid.
```

## 8. Get Nested KV from Iterator Additional Data
**any** UPar.GetIterAddiKV(**any** identity, **any** ...)
```note
Used to retrieve multi-level nested key-value pairs from the iterator's additional data. At least 2 parameters are required (supports multi-level table indexing; the last parameter is the target key). Returns nil if the iterator does not exist or the nested table path is invalid.
```

## 9. Set Iterator Timeout Time
**boolean** UPar.SetIterEndTime(**any** identity, **number** endTime, **boolean** silent=false)
```note
Used to modify the absolute timeout time of the iterator with the specified identity (endTime must be a numeric absolute time, not a relative duration). In non-silent mode (silent=false), it will trigger the UParIteratorEndTimeChanged hook. Returns false if the iterator does not exist.
```

## 10. Merge Iterator Additional Data
**boolean** UPar.MergeIterAddiKV(**any** identity, **table** data)
```note
Used to merge the iterator's additional data, implemented based on the GLua table.Merge method (shallow merge: only merges top-level key-value pairs, no recursive merging for deep tables). Returns false if the iterator does not exist or the incoming merge data is not a table.
```