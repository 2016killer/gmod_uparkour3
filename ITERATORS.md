<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## 目录

<a href="./UPACTION.md">动作</a>  
<a href="./UPEFFECT.md">特效</a>  
<a href="./SERHOOK.md">序列钩子</a>  
<a href="./HOOK.md">钩子</a>  
<a href="./LRU.md">LRU存储</a>  
<a href="./CUSTOMEFFECT.md">自定义特效</a>  
<a href="./UPMANIP.md">骨骼操纵</a>  
<a href="./UPKEYBOARD.md">键盘</a>  
<a href="./ITERATORS.md">迭代器</a>  


# 迭代器
```
实际上有两个迭代器系统：
1. RenderIterators: 用于在 PostDrawOpaqueRenderables 帧循环中执行迭代器。
2. Iterators: 用于在 Think 帧循环中执行迭代器。

UPar.PushIterator 与 UPar.PushRenderIterator 是同构的。
```


## 1.  推送迭代器
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.PushIterator(**any** identity, **function** iterator, **any** addition, **number** timeout, **function** clear)
```note
用于推送一个迭代器，该迭代器会在 Think 帧循环中执行。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型，支持特殊业务需求的自定义类型）；
2.  iterator：帧循环回调函数，参数为 (dt<帧间隔>, curTime<当前时间>, add<附加数据>)；
3.  addition：附加数据，非表类型会自动转为空表；
4.  timeout：超时时间（秒，必须大于 0，否则返回 false）；
5.  clear：迭代器清理回调函数，参数为 (identity, curTime, add, reason<清理原因>)。
当同名 identity 已存在时，会先触发 UParIteratorPop 钩子并覆盖旧迭代器；
若当前无有效迭代器，会自动添加 Think 钩子；
返回 true 表示推送成功，返回 false 表示超时参数不合法（<=0）。
```

## 2.  手动移除迭代器
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.PopIterator(**any** identity, **boolean** silent)
```note
用于手动移除指定标识的迭代器。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）；
2.  silent：是否静默执行，为 true 时不触发 UParIteratorPop 钩子。
若迭代器存在，会先执行清理回调（clear），再根据 silent 参数决定是否触发钩子，最后返回 true；
若迭代器不存在，直接返回 false；
移除后会自动置空迭代器的附加数据（add），减少内存冗余。
```

## 3.  获取迭代器数据
![shared](./materials/upgui/shared.jpg)
**table/nil** UPar.GetIterator(**any** identity)
```note
用于获取指定标识对应的迭代器完整数据。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）。
若迭代器存在，返回迭代器数据表（包含字段：f<回调函数>、et<结束时间>、add<附加数据>、clear<清理回调>、pt<暂停时间>）；
若迭代器不存在，返回 nil。
```

## 4.  判断迭代器是否存在
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.IsIteratorExist(**any** identity)
```note
用于快速判断指定标识的迭代器是否已存在。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）。
若迭代器存在，返回 true；若迭代器不存在，返回 false。
```

## 5.  暂停迭代器
![shared](./materials/upgui/shared.jpg)
**boolean/number** UPar.PauseIterator(**any** identity, **boolean** silent)
```note
用于暂停指定标识的迭代器，暂停后迭代器不再参与 Think 帧循环执行。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）；
2.  silent：是否静默执行，为 true 时不触发 UParIteratorPause 钩子。
返回值说明：
1.  false：迭代器不存在；
2.  0：迭代器已处于暂停状态（Lua 中为真值，适配 succ = succ and xxx 链式判断）；
3.  true：迭代器暂停成功。
暂停时会记录当前时间（pt 字段），用于恢复时补偿超时时间。
```

## 6.  恢复迭代器
![shared](./materials/upgui/shared.jpg)
**boolean/number** UPar.ResumeIterator(**any** identity, **boolean** silent)
```note
用于恢复已暂停的指定标识迭代器。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）；
2.  silent：是否静默执行，为 true 时不触发 UParIteratorResume 钩子。
返回值说明：
1.  false：迭代器不存在；
2.  0：迭代器未处于暂停状态（Lua 中为真值，适配 succ = succ and xxx 链式判断）；
3.  true：迭代器恢复成功。
恢复时会自动补偿超时时间（新结束时间 = 恢复时间 + 剩余超时时间），保证超时逻辑准确；
若当前无有效迭代器，恢复后会自动添加 Think 钩子。
```

## 7.  设置迭代器嵌套附加数据
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.SetIterAddiKV(**any** identity, **...** varargs)
```note
用于设置迭代器的嵌套附加数据，支持多级键路径赋值。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）；
2.  varargs：变长参数，至少需要 1 个键 + 1 个值（例如：SetIterAddiKV(ident, "a", "b", 10) 对应 add.a.b = 10）。
若中间嵌套键对应的表不存在，直接返回 false；
若迭代器不存在，返回 false；
若设置成功，返回 true；
不支持自动创建嵌套表，仅支持已有嵌套路径的赋值。
```

## 8.  获取迭代器嵌套附加数据
![shared](./materials/upgui/shared.jpg)
**any/nil** UPar.GetIterAddiKV(**any** identity, **...** varargs)
```note
用于获取迭代器的嵌套附加数据，支持多级键路径查询。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）；
2.  varargs：变长参数，至少需要 1 个键（例如：GetIterAddiKV(ident, "a", "b") 对应查询 add.a.b）。
若中间嵌套键对应的表不存在，返回 nil；
若迭代器不存在，返回 nil；
若查询成功，返回对应键的值。
```

## 9.  设置迭代器超时结束时间
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.SetIterEndTime(**any** identity, **number** endTime, **boolean** silent)
```note
用于直接设置指定迭代器的超时结束时间。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）；
2.  endTime：新的超时结束时间（时间戳格式）；
3.  silent：是否静默执行，为 true 时不触发 UParIteratorEndTimeChanged 钩子。
若迭代器存在，设置结束时间并返回 true；
若迭代器不存在，返回 false。
```

## 10. 合并迭代器附加数据
![shared](./materials/upgui/shared.jpg)
**boolean** UPar.MergeIterAddiKV(**any** identity, **table** data)
```note
用于合并迭代器的附加数据，基于 GLua table.Merge 方法实现（浅合并）。
参数说明：
1.  identity：迭代器唯一标识（任意非空类型）；
2.  data：待合并的附加数据（必须为表类型，否则断言报错）。
若迭代器存在，合并数据并返回 true；
若迭代器不存在，返回 false。
```
