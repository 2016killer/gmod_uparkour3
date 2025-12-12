- 作者：白狼
- 翻译: 豆小姐
- 日期：2025 12 10

# 关于接口实现
这里不再采用2.1.0版本的参数对齐写法, 虽然序列表在网络传输中表现良好, 
但是代码不好维护, 所以退回1.0.0版本的方法。
当然, 这样也有很多好处, 比如某些需要持久的数据可以直接放表中, 或者需要继承的数据也可以直接扔进去。

# 关于生命周期
![shared](materials\uparkour\shared.jpg)
**UPAction:Check**
```lua
@param ply Player
@param data table
function action:Check(ply, data)
    return checkResult
end
@Returns table checkResult
```
```note
返回表后进入Start
```


# Hook
## 普通的

![shared](materials\uparkour\shared.jpg)
**UParRegisterAction**
```lua
@param actName string
@param action UPAction
@Returns bool
hook.Add('UParRegisterAction', 'example', function(name, action)
    return prevent
end)
```
```note
返回 true 阻止动作注册
```

![shared](materials\uparkour\shared.jpg)
**UParRegisterEffect**
```lua
@param actName string
@param effName string
@param effect UPEffect
@Returns bool
hook.Add('UParRegisterEffect', 'example', function(actName, effName, effect)
    return prevent
end)
```
```note
返回 true 阻止特效注册
```

## 序列的
![shared](materials\uparkour\shared.jpg)
**'UPActInterrupt' + actName**
```lua
@param action UPAction
@param checkResult table
@Returns bool(返回 true 阻止动作启动)
UPar.RunActPreStartHook(action, checkResult)
```
```note
在UPAction:Check通过后调用
返回 true 阻止动作启动
```

--- 中断检查
@param playing string
@param action UPAction
@Returns bool(返回 true 阻止动作启动)
UPar.RunActInterruptHook(playing, playingData, action, checkResult)

UPar.RunActStartHook(action, checkResult)
UPar.RunActClearHook(action, endReason)
UPar.RunActOnRhythmChangeHook(action, customData)
```


# UPAction类
## 需要实现的接口

![shared](materials\uparkour\shared.jpg) 
**UPAction:Check**
```lua
@param ply Player
@param data table
function action:Check(ply, data)
    return checkResult
end
@Returns table checkResult
```
```note
返回表后进入Start
```

![shared](materials\uparkour\shared.jpg)
**UPAction:Start**
```lua
@param ply Player
@param checkResult table
function action:Start(ply, checkResult) 
end
```
```note
可以不实现, 不影响流程, 只执行一次, 然后进入Think
```

![server](materials\uparkour\server.jpg)
**UPAction:Think**
```lua
@param ply Player
@param mv CMoveData
@param cmd CUserCmd
@param checkResult table
@Returns table endReason
function action:Think(ply, mv, cmd, checkResult)
    return endReason
end
```
```note
返回表进入Clear, 否则维持当前状态
```

![shared](materials\uparkour\shared.jpg)
**UPAction:Clear**
```lua
@param ply Player
@param endReason table
function action:Clear(ply, endReason) 
end
```
```note
可选, 这将会在Play返回、强制中断(玩家死亡等)、中断后调用
```

## 可选接口
![client](materials\uparkour\client.jpg)
**UPAction:ConVarsPanelOverride**
```lua 
@param panel panel
function action:ConVarsPanelOverride(panel) 
end
```
```note
可以在这里自定义参数界面, 比如创建复杂结构的参数编辑器
```


![client](materials\uparkour\client.jpg)
**UPAction.CreateSundryPanels**
```lua 
action.CreateSundryPanels = {
    {
        label = 'Example', 
        func = function(panel)
            ...
        end
    }
}
```

## 可用方法
![shared](materials\uparkour\shared.jpg)
**UPAction:InitCVarPredictionMode**
```lua
@param default string
action:InitCVarPredictionMode(default) 
```
```note
在初始化后会出现在Q菜单中

false: 使用服务端预测
true: 使用客户端预测

参数本身无作用，需要自行处理。
```

![client](materials\uparkour\client.jpg)
**UPAction:InitCVarKeybind**
```lua
@param default string 组合键用空格隔开
action:InitCVarKeybind(default) 
```
```note
在初始化后会出现在Q菜单中

例: '33 83 65': KEY_W + KEY_LCONTROL + KEY_SPACE

参数本身无作用，需要自行处理。
```

![server](materials\uparkour\server.jpg)
**UPAction:ChangeRhythm**
```lua
@param ply Player
@param customData table
action:ChangeRhythm(ply, customData) 
```
```note
应当在Play接口中调用
将会使用net自动同步客户端, 不建议每帧调用

通常用于节奏多变的动作, 比如Double Vault
```

![shared](materials\uparkour\shared.jpg)
**UPAction:InitConVars**
```lua 
@param config table
action:InitConVars(
    {
        {
            name = 'example',
            default = '0.64',
            widget = 'NumSlider',
            min = 0,
            max = 1,
            decimals = 2,
            help = true,
            visible = false,
            client = nil,
        }
    }
) 
```
```note
初始化后会出现在动作编辑器中
使用self.ConVars可访问
```

# UPEffect类

## 需要实现的接口

![shared](materials\uparkour\shared.jpg)
**UPEffect:Start**
```lua
@param ply Player
@param checkResult table
function effect:Start(ply, checkResult) 
end
```
```note
会在UPAction:Start后自动调用
```

![shared](materials\uparkour\shared.jpg)
**UPEffect:OnRhythmChange**
```lua
@param ply Player
@param customData table
function effect:OnRhythmChange(ply, customData)
end
```
```note
会在UPAction:ChangeRhythm后自动调用
```

![shared](materials\uparkour\shared.jpg)
**UPEffect:Clear**
```lua
@param ply Player
@param endReason table
function effect:Clear(ply, endReason)
    -- 当动作结束时候调用
end
```
```note
会在UPAction:Clear后自动调用
```

## 可选接口

![client](materials\uparkour\client.jpg)
**UPEffect:PreviewPanelOverride**
```lua 
@param panel panel
function effect:PreviewPanelOverride(panel)
end
```
```note
预览面板覆盖
```

![client](materials\uparkour\client.jpg)
**UPEffect:EditorPanelOverride**
```lua
@param panel panel
function effect:EditorPanelOverride(panel)
end
```
```note
编辑器面板覆盖
```