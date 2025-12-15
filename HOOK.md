<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## 目录

<a href="./UPACTION.md">UPAction</a>  
<a href="./UPEFFECT.md">UPEffect</a>  
<a href="./SERHOOK.md">SeqHook</a>  
<a href="./HOOK.md">Hook</a>  
<a href="./LIFECYCLE.md">Lifecycle</a>  
<a href="./LRU.md">LRU</a>  
<a href="./CUSTOMEFFECT.md">Custom Effect</a>  

# Hook

![shared](./materials/upgui/shared.jpg)
UParRegisterAction(**string** actName, **UPAction** action)
```note
注册动作时触发
```

![shared](./materials/upgui/shared.jpg)
UParRegisterEffect(**string** actName, **string** effName, **UPEffect** effect)
```note
注册特效时触发
```

![shared](./materials/upgui/shared.jpg)
**table** UParSaveUserEffCacheToDisk(**table** cache)
```note
保存用户特效缓存时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**table** UParSaveUserEffCfgToDisk(**table** cfg)
```note
保存用户特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**table** UParLoadUserEffCacheFromDisk(**table** cache)
```note
加载用户特效缓存时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**table** UParLoadUserEffCfgFromDisk(**table** cfg)
```note
加载用户特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**table** UParSaveUserCustomEffectToDisk(**table** custom)
```note
保存用户自定义特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**table** UParLoadUserCustomEffectFromDisk(**table** custom)
```note
加载用户自定义特效配置时触发, 返回真值将覆盖默认值
```