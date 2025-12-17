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

### 简介
```note
为了节省开发时间, 我并没有对表加入保护, 所以hook中的所有表都是可以直接操作的, 这提供了便利也造成一些安全隐患, 操作表的时候需要小心。
```

```note
关于中断等的写法, 现在改用序列钩子的写法，之前是将函数直接插入表, 之前的查询效率可能比序列钩子高, 但是看起很繁琐, 考虑到中断函数的复用概率比较低, 所以采用序列钩子的写法。

关于界面的覆盖或拓展, 依旧采用将函数直接插入表的写法, 因为界面的函数复用概率略高一点。
```

- 作者：白狼 ava741963@163.com
- 翻译: 豆小姐
- 日期：2025 12 10
- 版本: 3.0.0