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


## 关于UPAction接口实现
这里不再采用2.1.0版本的参数对齐写法, 虽然序列表在网络传输中表现良好, 但是高频地unpack也很难受，代码也不好维护, 所以退回1.0.0版本的方法。
当然, 这样也有很多好处, 比如某些需要持久的数据可以直接放表中, 或者需要继承的数据也可以直接扔进去, 这使开发难度大大滴降低。

## 可选参数
![client](materials/upgui/client.jpg)
**UPAction**.icon: ***string*** 图标  
![client](materials/upgui/client.jpg)
**UPAction**.label: ***string*** 名称  
![client](materials/upgui/client.jpg)
**UPAction**.AAACreat: ***string*** 创建者  
![client](materials/upgui/client.jpg)
**UPAction**.AAADesc: ***string*** 描述  
![client](materials/upgui/client.jpg)
**UPAction**.AAAContrib: ***string*** 贡献者  
![shared](materials/upgui/shared.jpg)
**UPAction**.TrackId: ***int*** 轨道ID  
```note
默认为0, 相同TrackId的动作同时触发时会触发中断判断。
```

![client](materials/upgui/client.jpg)
**UPAction**.SundryPanels ***table***
```lua 
-- 例:
action.SundryPanels = {
    {
        label = 'Example', 
        func = function(panel)
            ...
        end
    }
}
```

![client](materials/upgui/client.jpg)
**UPAction**.ConVarsPanelOverride(**panel** panel)
```note
可以在这里自定义参数界面, 比如创建复杂结构的参数编辑器
```


## 需要实现的方法
![shared](materials/upgui/shared.jpg) 
***table*** **UPAction**:Check(**Player** ply, **any** data)  
```note
返回表后进入Start
```

![shared](materials/upgui/shared.jpg)
**UPAction**:Start(**Player** ply, **table** checkResult)
```note
在启动时执行一次, 然后进入Think
```

![server](materials/upgui/server.jpg)
***any*** **UPAction**:Think(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)
```note
返回真值进入Clear, 否则维持当前状态
```

![shared](materials/upgui/shared.jpg)
**UPAction**:Clear(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
在Think返回真值、强制结束、 中断 等情况下调用
强制结束时, interruptSource为true
中断时, interruptSource为table, interruptData为中断者的checkResult
```


## 可用方法
![shared](materials/upgui/shared.jpg)
**UPAction**:InitCVarPredictionMode(**string** default)
```note
在初始化后会出现在Q菜单中

false: 使用服务端预测
true: 使用客户端预测

参数本身无作用，需要自行处理。
```

![client](materials/upgui/client.jpg)
**UPAction**:InitCVarKeybind(**string** default)
```note
在初始化后会出现在Q菜单中
组合键用空格隔开
例: '33 83 65': KEY_W + KEY_LCONTROL + KEY_SPACE

参数本身无作用，需要自行处理。
```

![server](materials/upgui/server.jpg)
UPar.ActChangeRhythm(**Player** ply, **UPAction** action, **any** customData)
```note
应当在action:Think中手动调用, 这会触发effect:OnRhythmChange,
自动同步客户端, 不建议每帧调用

通常用于节奏多变的动作, 比如Double Vault
```

![shared](materials/upgui/shared.jpg)
**UPAction**:InitConVars(**table** config)
```lua
-- 例:
-- 初始化后会出现在动作编辑器中
-- 使用self.ConVars可访问
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
```