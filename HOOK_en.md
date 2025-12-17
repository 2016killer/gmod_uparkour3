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

# Hook

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterAction  
***@Params*** 
- actName **string**  
- action **UPAction**  

```note
Called when registering an action.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterEffect  
***@Params*** 
- actName **string**  
- effName **string**  
- effect **UPEffect**  

```note
Called when registering an effect.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCacheToDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
Called when saving the user's effect cache; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCfgToDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
Called when saving the user's effect configuration; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCacheFromDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
Called when loading the user's effect cache; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCfgFromDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
Called when loading the user's effect configuration; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserCustomEffectToDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
Called when saving the user's custom effect configuration; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserCustomEffectFromDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
Called when loading the user's custom effect configuration; returning a truthy value will override the default value
```