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

## 一、 模块概述
![shared](./materials/upgui/shared.jpg)
### 1.  核心作用
该模块是基于 GMOD `Think` 钩子实现的迭代器管理工具，支持迭代器的自动执行、超时管控、暂停恢复及附加数据操作，无需手动循环调用迭代器函数，降低业务开发成本。
### 2.  适用场景
- 服务端/客户端的循环业务逻辑（如玩家状态监控、NPC AI 行为、动画淡入淡出、定时任务执行）
- 需要精准控制执行时长、支持暂停/恢复的异步逻辑
### 3.  依赖说明
无第三方依赖，仅依赖 GMOD 内置 API（`CurTime`/`hook`/`istable`/`table.Merge` 等）和 Lua 标准语法，可直接集成使用。

## 二、 核心 API 使用说明
### 1.  迭代器添加：`UPar.PushIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.PushIterator(**identity** identity, **function** iterator, **table** addition, **number** timeout)
#### 用途
添加一个新的迭代器（若 `identity` 已存在，会覆盖旧迭代器并触发 `UParIteratorPop` 钩子）
#### 参数说明
| 参数名     | 类型       | 必填 | 说明                                                                 |
|------------|------------|------|----------------------------------------------------------------------|
| identity   | 任意       | 是   | 迭代器唯一标识（不可为 nil，用于后续查询/操作该迭代器）               |
| iterator   | 函数       | 是   | 迭代器执行函数（每帧由 `Think` 钩子驱动，参数：dt(帧间隔)、curTime(当前时间)、add(附加数据)） |
| addition   | 表/任意    | 否   | 迭代器附加数据（自动转为空表，存储业务关联数据）                     |
| timeout    | 数字       | 是   | 迭代器超时时间（秒，必须大于 0，超时后迭代器自动被移除）             |
#### 返回值
`true`（添加成功）/ `false`（timeout ≤ 0，添加失败）
#### 使用示例
```lua
-- 示例：添加一个玩家位置监控迭代器
local playerIterId = "player_pos_monitor_" .. LocalPlayer():SteamID()
UPar.PushIterator(playerIterId, function(dt, curTime, add)
    -- 迭代器逻辑：打印玩家当前位置
    local ply = add.ply
    if IsValid(ply) then
        print("玩家位置：" .. tostring(ply:GetPos()))
    else
        return true -- 玩家无效，主动终止迭代器
    end
end, {ply = LocalPlayer()}, 30) -- 超时时间30秒
```

### 2.  迭代器移除：`UPar.PopIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.PopIterator(**identity** identity, **bool** silent)
#### 用途
手动移除指定标识的迭代器
#### 参数说明
| 参数名     | 类型   | 必填 | 说明                                                                 |
|------------|--------|------|----------------------------------------------------------------------|
| identity   | 任意   | 是   | 迭代器唯一标识                                                       |
| silent     | 布尔   | 否   | 静默模式（true：不触发 `UParIteratorPop` 钩子；false/默认：触发钩子） |
#### 返回值
`true`（迭代器存在并成功移除）/ `false`（迭代器不存在）
#### 使用示例
```lua
-- 示例：手动移除玩家位置监控迭代器（非静默模式）
local playerIterId = "player_pos_monitor_" .. LocalPlayer():SteamID()
local isRemoved = UPar.PopIterator(playerIterId, false)
if isRemoved then
    print("迭代器已成功移除")
end
```

### 3.  迭代器查询
#### （1） `UPar.GetIterator`
![shared](./materials/upgui/shared.jpg)
**table/nil** UPar.GetIterator(**identity** identity)
##### 用途
获取指定迭代器的完整数据（包含函数、结束时间、附加数据等）
##### 参数
`identity`：迭代器唯一标识（不可为 nil）
##### 返回值
迭代器数据表格（存在）/ nil（不存在）
##### 示例
```lua
local iterData = UPar.GetIterator(playerIterId)
if iterData then
    print("迭代器结束时间：" .. iterData.et)
end
```

#### （2） `UPar.IsIteratorExist`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.IsIteratorExist(**identity** identity)
##### 用途
判断指定迭代器是否存在
##### 参数
`identity`：迭代器唯一标识（不可为 nil）
##### 返回值
`true`（存在）/ `false`（不存在）
##### 示例
```lua
if UPar.IsIteratorExist(playerIterId) then
    print("迭代器存在，可执行后续操作")
end
```

### 4.  迭代器暂停/恢复
#### （1） `UPar.PauseIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.PauseIterator(**identity** identity, **bool** silent)
##### 用途
暂停指定迭代器（暂停后不再执行迭代器函数）
##### 参数
| 参数名     | 类型   | 必填 | 说明                                                                 |
|------------|--------|------|----------------------------------------------------------------------|
| identity   | 任意   | 是   | 迭代器唯一标识                                                       |
| silent     | 布尔   | 否   | 静默模式（true：不触发 `UParIteratorPause` 钩子；false/默认：触发钩子） |
##### 返回值
`true`（暂停成功）/ `false`（迭代器不存在）
##### 示例
```lua
-- 静默暂停迭代器
UPar.PauseIterator(playerIterId, true)
```

#### （2） `UPar.ResumeIterator`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.ResumeIterator(**identity** identity, **bool** silent)
##### 用途
恢复已暂停的迭代器（自动补偿超时时间，抵消暂停时长）
##### 参数
| 参数名     | 类型   | 必填 | 说明                                                                 |
|------------|--------|------|----------------------------------------------------------------------|
| identity   | 任意   | 是   | 迭代器唯一标识                                                       |
| silent     | 布尔   | 否   | 静默模式（true：不触发 `UParIteratorResume` 钩子；false/默认：触发钩子） |
##### 返回值
`true`（恢复成功）/ `false`（迭代器不存在/未暂停）
##### 示例
```lua
-- 非静默恢复迭代器
UPar.ResumeIterator(playerIterId, false)
```

### 5.  附加数据操作
#### （1） `UPar.SetIterAddiKV`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.SetIterAddiKV(**identity** identity, ...)
##### 用途
给迭代器附加数据设置**多级嵌套键值**
##### 参数
| 参数名     | 类型   | 必填 | 说明                                                                 |
|------------|--------|------|----------------------------------------------------------------------|
| identity   | 任意   | 是   | 迭代器唯一标识                                                       |
| ...        | 任意   | 是   | 可变参数（至少2个，格式：多级键路径 + 目标键 + 赋值内容）             |
##### 返回值
`true`（设置成功）/ `false`（迭代器不存在/嵌套路径无效）
##### 示例
```lua
-- 给迭代器附加数据设置：add.player.pos.x = 100
UPar.SetIterAddiKV(playerIterId, "player", "pos", "x", 100)
```

#### （2） `UPar.GetIterAddiKV`
![shared](./materials/upgui/shared.jpg)
**any/nil** UPar.GetIterAddiKV(**identity** identity, ...)
##### 用途
查询迭代器附加数据的**多级嵌套键值**
##### 参数
| 参数名     | 类型   | 必填 | 说明                                                                 |
|------------|--------|------|----------------------------------------------------------------------|
| identity   | 任意   | 是   | 迭代器唯一标识                                                       |
| ...        | 任意   | 是   | 可变参数（至少2个，格式：多级键路径 + 目标键）                       |
##### 返回值
目标键对应的值（存在）/ nil（迭代器不存在/嵌套路径无效/键不存在）
##### 示例
```lua
-- 查询：add.player.pos.x
local xPos = UPar.GetIterAddiKV(playerIterId, "player", "pos", "x")
```

#### （3） `UPar.MergeIterAddiKV`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.MergeIterAddiKV(**identity** identity, **table** data)
##### 用途
批量合并键值对到迭代器附加数据（浅层合并）
##### 参数
| 参数名     | 类型   | 必填 | 说明                                                                 |
|------------|--------|------|----------------------------------------------------------------------|
| identity   | 任意   | 是   | 迭代器唯一标识                                                       |
| data       | 表     | 是   | 待合并的源表（键值对会覆盖附加数据同名键，新增异名键）               |
##### 返回值
`true`（合并成功）/ `false`（迭代器不存在）
##### 示例
```lua
-- 批量更新附加数据顶层字段
UPar.MergeIterAddiKV(playerIterId, {
    hp = 150,
    mp = 100,
    state = "alive"
})
```

### 6.  迭代器结束时间修改：`UPar.SetIterEndTime`
![shared](./materials/upgui/shared.jpg)
**bool** UPar.SetIterEndTime(**identity** identity, **number** endTime, **bool** silent)
#### 用途
动态修改迭代器的绝对结束时间
#### 参数
| 参数名     | 类型   | 必填 | 说明                                                                 |
|------------|--------|------|----------------------------------------------------------------------|
| identity   | 任意   | 是   | 迭代器唯一标识                                                       |
| endTime    | 数字   | 是   | 新的绝对结束时间（需传入 `CurTime() + 相对秒数`，而非直接传相对秒数） |
| silent     | 布尔   | 否   | 静默模式（true：不触发 `UParIteratorEndTimeChanged` 钩子；false/默认：触发钩子） |
#### 返回值
`true`（修改成功）/ `false`（迭代器不存在）
#### 示例
```lua
-- 给迭代器延长10秒超时时间
local newEndTime = CurTime() + 10
UPar.SetIterEndTime(playerIterId, newEndTime, false)
```