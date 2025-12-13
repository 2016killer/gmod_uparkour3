- 作者：白狼
- 翻译: 豆小姐
- 日期：2025 12 10

# 关于UPAction接口的实现
这里不再采用2.1.0版本的参数对齐写法, 虽然序列表在网络传输中表现良好, 但是高频地unpack也很难受，代码也不好维护, 所以退回1.0.0版本的方法。
当然, 这样也有很多好处, 比如某些需要持久的数据可以直接放表中, 或者需要继承的数据也可以直接扔进去, 这使开发难度大大滴降低。

# UPAction类

## 参数
![client](materials\upgui\client.jpg)
UPAction.icon: ***string*** 图标  
![client](materials\upgui\client.jpg)
UPAction.label: ***string*** 名称  
![client](materials\upgui\client.jpg)
UPAction.AAACreat: ***string*** 创建者  
![client](materials\upgui\client.jpg)
UPAction.AAADesc: ***string*** 描述  
![client](materials\upgui\client.jpg)
UPAction.AAAContrib: ***string*** 贡献者  
![shared](materials\upgui\shared.jpg)
UPAction.TrackId: ***int*** 轨道ID  
## 需要实现的方法
![shared](materials\upgui\shared.jpg) 
***table*** **UPAction:Check**(**Player** ply, **any** data)  
```note
返回表后进入Start
```

![shared](materials\upgui\shared.jpg)
**UPAction:Start**(**Player** ply, **table** checkResult)
```note
在启动时执行一次, 然后进入Think
```

![server](materials\upgui\server.jpg)
***any*** **UPAction:Think**(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)

```note
返回真值进入Clear, 否则维持当前状态
```

![shared](materials\upgui\shared.jpg)
**UPAction:Clear**(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
在Think返回真值、强制结束、 中断 等情况下调用
强制结束时, interruptSource为true
中断时, interruptSource为table, interruptData为中断者的checkResult
```

## 可选实现的方法
![client](materials\upgui\client.jpg)
**UPAction:ConVarsPanelOverride**(**panel** panel)
```note
可以在这里自定义参数界面, 比如创建复杂结构的参数编辑器
```


![client](materials\upgui\client.jpg)
**UPAction.CreateSundryPanels** **table**
```lua 
例:
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
![shared](materials\upgui\shared.jpg)
**UPAction:InitCVarPredictionMode**(**string** default)
```note
在初始化后会出现在Q菜单中

false: 使用服务端预测
true: 使用客户端预测

参数本身无作用，需要自行处理。
```

![client](materials\upgui\client.jpg)
**UPAction:InitCVarKeybind**(**string** default)
```note
在初始化后会出现在Q菜单中
组合键用空格隔开
例: '33 83 65': KEY_W + KEY_LCONTROL + KEY_SPACE

参数本身无作用，需要自行处理。
```

![server](materials\upgui\server.jpg)
**UPar.ActChangeRhythm**(**Player** ply, **UPAction** action, **any** customData)
```note
应当在action:Think中手动调用, 这会触发effect:OnRhythmChange,
自动同步客户端, 不建议每帧调用

通常用于节奏多变的动作, 比如Double Vault
```

![shared](materials\upgui\shared.jpg)
**UPAction:InitConVars**(**table** config)
```note
例:
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
            admin = false,
        }
    }
) 

初始化后会出现在动作编辑器中
使用self.ConVars可访问
```

# UPEffect类

![client](materials\upgui\client.jpg)
UPEffect.icon: ***string*** 图标  
![client](materials\upgui\client.jpg)
UPEffect.label: ***string*** 名称  
![client](materials\upgui\client.jpg)
UPEffect.AAACreat: ***string*** 创建者  
![client](materials\upgui\client.jpg)
UPEffect.AAADesc: ***string*** 描述  
![client](materials\upgui\client.jpg)
UPEffect.AAAContrib: ***string*** 贡献者  
![shared](materials\upgui\shared.jpg)
UPEffect.TrackId: ***int*** 轨道ID 

## 需要实现的方法

![shared](materials\upgui\shared.jpg)
**UPEffect:Start**(**Player** ply, **table** checkResult)
```note
会在UPAction:Start后自动调用
```

![shared](materials\upgui\shared.jpg)
**UPEffect:OnRhythmChange**(**Player** ply, **any** customData)
```note
会在UPar.ActChangeRhythm 后自动调用
```

![shared](materials\upgui\shared.jpg)
**UPEffect:Clear**(**Player** ply, **table** checkResult, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
会在UPAction:Clear后自动调用
```

## 可选实现的方法

![client](materials\upgui\client.jpg)
**UPEffect:PreviewPanelOverride**(**panel** panel)
```note
预览面板覆盖
```

![client](materials\upgui\client.jpg)
**UPEffect:EditorPanelOverride**(**panel** panel)
```note
编辑器面板覆盖
```


# Hook
## 普通的

![shared](materials\upgui\shared.jpg)
**bool** **UParRegisterAction**(**string** actName, **UPAction** action)
```note
返回 true 阻止动作注册
```
```lua
-- 例:
-- 阻止所有动作注册
hook.Add('UParRegisterAction', 'stop_all', function(actName, action)
    return true
end)
```

![shared](materials\upgui\shared.jpg)
**bool** **UParRegisterEffect**(**string** actName, **string** effName, **UPEffect** effect)
```note
返回 true 阻止特效注册
```

## 序列的
![shared](materials\upgui\shared.jpg)
**UPar.SeqHookAdd**(**string** eventName, **string** identifier, **function** func, **int** priority)
```note
使用此添加事件的序列钩子, 如果标识符重复且priority为nil的情况则继承之前的优先级
```

![shared](materials\upgui\shared.jpg)
**UPar.SeqHookRemove**(**string** eventName, **string** identifier)
```note
移除指定标识符的钩子
```

```lua
-- 例:
-- 允许 test_lifecycle 被其他任何动作中断
-- 优先级 0 最高
UPar.SeqHookAdd('UParInterrupt', 'test_interrupt', function(ply, playing, playingData, interruptSource, interruptData)
	local playingName = playing.Name
	if playingName ~= 'test_lifecycle' then
		return true
	end
end, 0)
```

![shared](materials\upgui\shared.jpg)
**bool** **UParInterrupt**(**Player** ply, **UPAction** playing, **table** playingData, **bool** or **UPAction** interruptSource)
```note
当前轨道被占用时调用, 返回 true 运行中断
```

![shared](materials\upgui\shared.jpg)
**bool** **UParPreStart**(**Player** ply, **UPAction** action, **table** checkResult)
```note
在UPAction:Check通过后调用, 返回 true 阻止动作启动
```

![shared](materials\upgui\shared.jpg)
**bool** **UParStart**(**Player** ply, **UPAction** action, **table** checkResult)
```note
在UPAction:Start前调用, 返回 true 覆盖默认
```

![shared](materials\upgui\shared.jpg)
**bool** **UParOnChangeRhythm**(**Player** ply, **UPAction** action, **UPEffect** effect, **any** customData)
```note
使用 UPar.ActChangeRhythm 时触发, 返回 true 覆盖默认
```

![shared](materials\upgui\shared.jpg)
**bool** **UParClear**(**Player** ply, **UPAction** playing, **table** playingData, **CMoveData** mv, **CUserCmd** cmd, **UPAction** interruptSource, **table** interruptData)
```note
在 UPAction:Clear 前调用, 返回 true 覆盖默认
```


# 关于生命周期
**UPAction.TrackId**
```note
这是核心,
如果在同一轨道的话要走中断，比如执行攀爬时触发了翻越检测就要走中断，
如果不同TrackId, 比如检视动作是可以和攀爬、翻越并行的。
```

![uplife](materials\upgui\uplife_zh.jpg)
![uplife2](materials\upgui\uplife2_zh.jpg)
