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


# 关于生命周期
**UPAction.TrackId**
```note
这是核心,
如果在同一轨道的话要走中断，比如执行攀爬时触发了翻越检测就要走中断，
如果不同TrackId, 比如检视动作是可以和攀爬、翻越并行的。
```

![uplife](materials/upgui/uplife_zh.jpg)
![uplife2](materials/upgui/uplife2_zh.jpg)
