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


## Custom Effect

The biggest difference between a Custom Effect and a **UPEffect** is the addition of the `linkName` and `linkAct` keys. Both keys are of **string** type, corresponding to the names of a specific **UPEffect** and a specific **UPAction** respectively.


## Working Principle

### Saving
Path: /data/uparkour_effects/custom/**%linkAct%**/**%name%**.json  

Data serialization is implemented using `util.TableToJSON`.  
Data after saving will lose internal reference relationships. For effects that rely on this mechanism to function, it is not recommended to create custom effects.  
Alternatively, use the hooks **UParLoadUserCustomEffectFromDisk** and **UParSaveUserCustomEffectToDisk** for loading and saving operations.

### Initialization
Initialization is triggered every time data is saved. Internally, **UPar.DeepClone** is used for deep copy — the original deep copy function `table.Copy` does not support userdata types such as `vector`, `angle`, `matrix`, etc.  

Subsequently, **UPar.DeepInject** is used to complement the custom object with non-serializable types (e.g., **function**).  