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

## 关于UPAction接口实现
这里不再采用2.1.0版本的参数对齐写法, 虽然序列表在网络传输中表现良好, 但是高频地unpack也很难受，代码也不好维护, 所以退回1.0.0版本的方法。
当然, 这样也有很多好处, 比如某些需要持久的数据可以直接放表中, 或者需要继承的数据也可以直接扔进去, 这使开发难度大大滴降低。

## 可选参数
![client](./materials/upgui/client.jpg)
**UPAction**.icon: ***string*** 图标  
![client](./materials/upgui/client.jpg)
**UPAction**.label: ***string*** 名称  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAACreat: ***string*** 创建者  
![client](./materials/upgui/client.jpg)
**UPAction**.AAADesc: ***string*** 描述  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAContrib: ***string*** 贡献者  
![shared](./materials/upgui/shared.jpg)
**UPAction**.TrackId: ***int*** or ***string*** 轨道ID  
```note
默认为0, 相同TrackId的动作同时触发时会触发中断判断。
```

![client](./materials/upgui/client.jpg)
**UPAction**:SundryPanels ***table***
```lua 
-- 例:
if CLIENT then
	local function ExamplePanel(self, panel)
		panel:Help('This is example')
	end

	action.SundryPanels = {
		{
			label = '#upgui.dev.example',
			func = ExamplePanel,
		}
	}
end
```

![client](./materials/upgui/client.jpg)
**UPAction**:ConVarsPanelOverride(**DForm** panel)
```note
可以在这里自定义参数界面, 比如创建复杂结构的参数编辑器
```
```lua 
if CLIENT then
    function action:ConVarsPanelOverride(panel)
        panel:Help(self.Name)
    end
end
```

![client](./materials/upgui/client.jpg)
**UPAction**:ConVarWidgetExpand(**int** idx, **table** cvCfg, **panel** originWidget, **DForm** panel)
```note
You can extend the controls of the parameter interface here, or override the default ones.
```
```lua 
if CLIENT then
    function action:ConVarWidgetExpand(idx, cvCfg, originWidget, panel)
		if IsValid(originWidget) and ispanel(originWidget) and idx == 1 then
			local label = vgui.Create('DLabel')
			label:SetText('#upgui.dev.cv_widget_expand')
			label:SetTextColor(Color(0, 150, 0))

			return label
		end
    end
end
```

## 需要实现的方法
![shared](./materials/upgui/shared.jpg) 
***table*** **UPAction**:Check(**Player** ply, **any** data)  
```note
返回表后进入Start
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Start(**Player** ply, **table** checkResult)
```note
在启动时执行一次, 然后进入Think
```

![server](./materials/upgui/server.jpg)
***any*** **UPAction**:Think(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)
```note
返回真值进入Clear, 否则维持当前状态
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Clear(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **UPAction** interruptSource, **table** interruptData)
```note
在Think返回真值、强制结束、 中断 等情况下调用
强制结束时, interruptSource为true
中断时, interruptSource为table, interruptData为中断者的checkResult
```


## 可用方法
![shared](./materials/upgui/shared.jpg)
**UPAction**:InitCVarPredictionMode(**string** default)
```note
在初始化后会出现在Q菜单中

false: 使用服务端预测
true: 使用客户端预测

参数本身无作用，需要自行处理。
```

![client](./materials/upgui/client.jpg)
**UPAction**:InitCVarKeybind(**string** default)
```note
在初始化后会出现在Q菜单中
组合键用空格隔开
例: '33 83 65': KEY_W + KEY_LCONTROL + KEY_SPACE

参数本身无作用，需要自行处理。
```



![shared](./materials/upgui/shared.jpg)
**UPAction**:InitConVars(**table** config)
```lua
-- 例:
-- 初始化后会出现在动作编辑器中
-- 使用 self.ConVars 可访问
action:InitConVars(
    {
        {
            name = 'example_numslider',
            default = '0',
            widget = 'NumSlider',
            min = 0, max = 1, decimals = 2,
            help = true
        },

	    {
            name = 'example_color',
            default = '0',
            widget = 'UParColorEditor'
        },

	    {
            name = 'example_ang',
            default = '0',
            widget = 'UParAngEditor',
			min = -1, max = 1, decimals = 1, interval = 0.1,
        },

	    {
            name = 'example_vec',
            default = '0',
            widget = 'UParVecEditor',
			min = -2, max = 2, decimals = 2, interval = 0.5,
        },

	    {
            name = 'example_invisible',
            default = '0',
            widget = 'NumSlider',
			invisible = true,
        },

	    {
            name = 'example_admin',
            default = '0',
            widget = 'NumSlider',
			admin = true,
        }
    }
) 
```

![client](./materials/upgui/client.jpg)
**UPAction**:RegisterPreset(**table** preset)
```lua
if CLIENT then
	action:RegisterPreset(
		{
			AAAACreat = 'Miss DouBao',
			AAAContrib = 'Zack',

			label = '#upgui.dev.example',
			values = {
				['example_numslider'] = '0.5'
			}
		}
	) 
end
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:AddConVar(**table** cvCfg)
```lua
action:AddConVar({
	name = 'example_other',
	widget = 'NumSlider'
})
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:RemoveConVar(**string** cvName)
```lua
action:RemoveConVar('example_other')
```