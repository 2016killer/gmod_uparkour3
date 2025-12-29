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


## 简介

### 示例
使用指令 developer 1;up_reload_sv;up_reload_cl 来加载示例。
可以在所有带有 test 的 lua 文件中找到示例代码。

### 共识
```note
对于 UPAction 和 UPEffect, 我们应当将他们视为静态容器, 不应该将任何运行的结果存储在他们的中。

UPAction、UPEffect 生命周期的同步永远是一次性的。 因为同步的数据是表, 如果需要多次同步, 可以自行标记并发送。
```

### 数据安全
```note
为了节省开发时间以及本人对lua和框架设计的理解有限, 我并没有对表加入保护, 所以hook中的所有表都是可以直接操作的, 这提供了便利也造成一些安全隐患, 操作表的时候需要小心, 你也可以按需为输出的表加入保护。

最好的方法是不要放入在Start和Clear初始化或操作有上下文依赖的数据以确保在极端情况下的安全。
```
### 变化
```note
关于中断等的写法, 现在改用序列钩子的写法, 如果动作"test_lifecycle"在轨道中运行, 同时你触发了动作, 则会运行序列"UParUParActAllowInterrupt_test_lifecycle" 和 "UParUParActInterrupt", 其他所有可以拓展的都按照此规律。

1. 增加动作编辑器自定义面板支持。
2. 重构生命周期, 删去大部分小概率用到的参数, 动作可以多轨道并行。
3. 新增迭代器支持。
4. 新增 UPManip API, 可以直接操纵骨骼, 但运算量较大。
5. 新增按键绑定与事件支持。
6. 可以创建更多的自定义特效
```
- 作者：白狼 2322012547@qq.com
- 翻译: 豆小姐
- 日期：2025 12 10
- 版本: 3.0.0
