- 作者：白狼
- 翻译: 豆小姐
- 日期：2025 12 10

# UPAction类

## 一、开发时所需要关注的部分
### 1.1 关于接口实现
这里不再采用2.1.0版本的参数对齐写法，虽然序列表在网络传输中表现良好，但与高频unpack、pack造成的开销相比微不足道。所以这里改为与1.0.0版本相同的传参，我们直接传递哈希表，这样好处有很多，比如某些需要持久的数据可以直接放表中，或者需要继承的数据也可以直接扔进去。

## 二、需要实现的接口
```lua
--- 动作前置校验接口
--- @param ply Player
--- @param data table
--- @return table checkResult 校验结果表（必须返回表才进入下个周期）
--- @usage 双端调用
function action:Check(ply, data)
    return checkResult
end

--- 动作启动接口
--- @param ply Player
--- @param checkResult table
--- @usage 双端调用
function action:Start(ply, checkResult)
    -- 可以不实现, 不影响流程
end

--- 动作执行核心接口
--- @param ply Player
--- @param mv CMoveData
--- @param cmd CUserCmd
--- @param checkResult table
--- @return table endResult 执行结果表（必须返回表才进入下个周期）
--- @usage 仅服务端调用
function action:Play(ply, mv, cmd, checkResult)
    return endResult
end

--- 动作清理接口
--- @param ply Player
--- @param endResult table
--- @usage 双端调用
function action:Clear(ply, endResult)
    -- 可以不实现, 不影响流程
end
```

## 三、可以额外添加的接口
```lua
--- 自定义参数面板覆盖接口
--- @param panel table
--- @usage 仅客户端调用
function action:ConVarsPanelOverride(panel)
    -- 可以在这里自定义参数界面
end

--- 额外参数面板配置（表结构）
--- @usage 仅客户端调用
-- 可以在这里添加额外的参数界面
action.CreateSundryPanels = {
    {
        label = 'Example', 
        func = function(panel)
            --- @param panel table
            ...
        end
    }
}
```

## 四、可以额外附加的参数
这些参数本身没有意义，只是在初始化后会出现在Q菜单中，需要自己处理：
```lua
action:InitCVarPredictionMode('0') -- 我们默认 false 是 服务器预测
action:InitCVarKeybind('33 83 65') -- KEY_W + KEY_LCONTROL + KEY_SPACE
```

## 五、可用方法
```lua
--- 更新特效节奏（自动同步客户端）
--- @param ply Player
--- @param customData table
--- @usage 仅服务端调用（建议在Play接口中调用）
action:ChangeRhythm(ply, customData) 
```

# UPEffect类

## 一、需要实现的接口
```lua
--- 特效启动接口
--- @param ply Player
--- @param checkResult table
--- @usage 双端调用
function effect:Start(ply, checkResult)
    -- 当动作触发时候调用
end

--- 特效节奏变更回调接口
--- @param ply Player
--- @param customData table
--- @usage 双端调用
function effect:OnRhythmChange(ply, customData)
    -- 当节奏变化时候调用, 使用action:ChangeRhythm(ply, customData)手动触发
end

--- 特效清理接口
--- @param ply Player
--- @param endResult table
--- @usage 双端调用
function effect:Clear(ply, endResult)
    -- 当动作结束时候调用
end
```

## 二、可以额外添加的接口
```lua
--- 预览面板覆盖接口
--- @param panel table
--- @usage 仅客户端调用
function effect:PreviewPanelOverride(panel)
end

--- 编辑器面板覆盖接口
--- @param panel table
--- @usage 仅客户端调用
function effect:EditorPanelOverride(panel)
end
```