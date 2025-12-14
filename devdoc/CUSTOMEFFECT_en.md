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

## Custom Effect

Custom effects are effects created by users in the effect management interface. In fact, they are **not instances of UPEffect**—thus, the check via `UPar.isupeffect` will return `false`. A custom effect is essentially an ordinary `table` containing the keys `linkName` and `linkAct`: both keys must be of `string` type, corresponding to the names of a specific `UPEffect` and `UPAction` respectively.

## Save Path
/uparkour_effects/custom/**%linkAct%**/**%name%**.json

## Working Principle

Injecting a custom effect into `UPAction` as a `UPEffect` instance may cause overwriting issues, which could lead to unpredictable results in multiplayer games.  

To avoid this, a dedicated caching mechanism is used:  
After initializing the custom effect (by searching with `linkName` and `linkAct`), we store the initialized data in `ply.upeff_cache` and set the corresponding key in `ply.upeffect_config` to `CACHE`.  

These operations must be synchronized to the server side simultaneously. The entire process is relatively complex, and **manual modification of this logic is not recommended**.

```lua 
-- Example: 
ply.upeff_cache['example'] = custom
ply.upeff_config['example'] = 'CACHE'
```