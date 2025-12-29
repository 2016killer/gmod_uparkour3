<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## 目录

<a href="./UPACTION.md">UPAction</a>  
<a href="./UPEFFECT.md">UPEffect</a>  
<a href="./SERHOOK.md">SeqHook</a>  
<a href="./HOOK.md">Hook</a>  
<a href="./LRU.md">LRU</a>  
<a href="./CUSTOMEFFECT.md">Custom Effect</a>  
<a href="./UPMANIP.md">UPManip</a>  
<a href="./UPKEYBOARD.md">UPKeyboard</a>  

# Hook

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterAction  
***@Params*** 
- actName **string**  
- action **UPAction**  

```note
注册动作时触发
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterEffect  
***@Params*** 
- actName **string**  
- effName **string**  
- effect **UPEffect**  

```note
注册特效时触发
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCacheToDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
保存用户特效缓存时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCfgToDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
保存用户特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCacheFromDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
加载用户特效缓存时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCfgFromDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
加载用户特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserCustomEffectToDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
保存用户自定义特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserCustomEffectFromDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
加载用户自定义特效配置时触发, 返回真值将覆盖默认值
```