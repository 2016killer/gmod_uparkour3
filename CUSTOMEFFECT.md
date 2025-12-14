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


## 自定义特效

自定义特效是用户在特效管理界面创建的特效, 实际它不是**UPEffect**的实例, 所以使用 **UPar.isupeffect** 判断时会返回false, 它实际上就是一个包含**linkName**和**linkAct**键的普通**table**, **linkName**和**linkAct**应当是**string**类型, 是某个**UPEffect**和**UPAction**的名称。

## 保存路径
/uparkour_effects/custom/**%linkAct%**/**%name%**.json

## 工作原理

如果将自定义特效作为**UPEffect**注入**UPAction**, 可能会导致覆盖问题, 这在多人游戏可能造成不可预测的结果,   
所以这里利用了某种缓存机制, 我们将自定义特效初始化(根据**linkName**和**linkAct**搜索)后, 将初始化的数据放入**ply.upeff_cache**并将**ply.upeffect_config**对应键设为**CACHE**,  
同时这些需要同步到服务器端, 这些过程较为复杂, 不建议对此操作。

```lua 
-- 例: 
ply.upeff_cache['example'] = custom
ply.upeff_config['example'] = 'CACHE'
```