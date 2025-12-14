<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## 目录

<a href="./devdoc/UPACTION.md">UPAction</a>  
<a href="./devdoc/UPEFFECT.md">UPEffect</a>  
<a href="./devdoc/SERHOOK.md">SeqHook</a>  
<a href="./devdoc/HOOK.md">Hook</a>  
<a href="./devdoc/LIFECYCLE.md">Lifecycle</a>  
<a href="./devdoc/LRU.md">LRU</a>  
<a href="./devdoc/CUSTOMEFFECT.md">Custom Effect</a>  

# LRU
```note
总共有三个LRU, 其方法名几乎相同, 区别在于加了标识符
例如: LRUSet, LRU2Set, LRU3Set
三个LRU默认大小为30, 客户端的第一个LRU已经被面板数据占用, 尽量避免使用。
```

![shared](materials/upgui/shared.jpg)
**any** UPar.LRUGet(**string** key)

![shared](materials/upgui/shared.jpg)
**any** UPar.LRUSet(**string** key, **any** val)

![shared](materials/upgui/shared.jpg)
**any** UPar.LRUGetOrSet(**string** key, **any** default)

![shared](materials/upgui/shared.jpg)
UPar.LRUDelete(**string** key)