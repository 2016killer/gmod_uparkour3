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

## 序列钩子

## 操作方法

![shared](./materials/upgui/shared.jpg)
**int** UPar.SeqHookAdd(**string** eventName, **string** identifier, **function** func, **int** priority)
```note
使用此添加事件的序列钩子, 如果标识符重复且priority为nil的情况则继承之前的优先级。
返回当前优先级。
```

![shared](./materials/upgui/shared.jpg)
UPar.SeqHookRemove(**string** eventName, **string** identifier)
```note
移除指定标识符的钩子
```

## 已存在的钩子

