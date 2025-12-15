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
UParRegisterAction(**string** actName, **UPAction** action)
```note
Called when registering an action.
```

![shared](./materials/upgui/shared.jpg)
UParRegisterEffect(**string** actName, **string** effName, **UPEffect** effect)
```note
Called when registering an effect.
```

![shared](./materials/upgui/shared.jpg)
**table** UParSaveUserEffCacheToDisk(**table** cache)
```note
Called when saving the user's effect cache; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**table** UParSaveUserEffCfgToDisk(**table** cfg)
```note
Called when saving the user's effect configuration; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**table** UParLoadUserEffCacheFromDisk(**table** cache)
```note
Called when loading the user's effect cache; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**table** UParLoadUserEffCfgFromDisk(**table** cfg)
```note
Called when loading the user's effect configuration; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**table** UParSaveUserCustomEffectToDisk(**table** custom)
```note
Called when saving the user's custom effect configuration; returning a truthy value will override the default value
```

![shared](./materials/upgui/shared.jpg)
**table** UParLoadUserCustomEffectFromDisk(**table** custom)
```note
Called when loading the user's custom effect configuration; returning a truthy value will override the default value
```