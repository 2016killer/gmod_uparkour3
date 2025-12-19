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

# UPEffect类

## 可选参数  

![client](./materials/upgui/client.jpg)
**UPEffect**.icon: ***string*** 图标  
![client](./materials/upgui/client.jpg)
**UPEffect**.label: ***string*** 名称  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAAACreat: ***string*** 创建者  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAADesc: ***string*** 描述  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAAContrib: ***string*** 贡献者  


![client](./materials/upgui/client.jpg)
**UPEffect**.PreviewKVExpand: ***function***  
```lua
-- 覆盖默认键值对预览
if CLIENT then
    effect.PreviewKVExpand = function(key, val, originWidget, _, _)
        if IsValid(originWidget) and ispanel(originWidget) then
            originWidget:Remove()
        end

        local label = vgui.Create('DLabel')
        label:SetText(tostring(val))

        return label
    end
end
```

## 需要实现的方法

![shared](./materials/upgui/shared.jpg)
**UPEffect**:Start(**Player** ply, **table** checkResult)
```note
会在UPAction:Start后自动调用
```



![shared](./materials/upgui/shared.jpg)
**UPEffect** UPar.RegisterEffectEasy(**string** actName, **string** tarName, **string** name, **table** initData)
```note
这会从已注册的当中找到对应的特效, 自动克隆并覆盖。
将控制台变量 developer 设为 1 可以阻止翻译行为以便查看真实键名。

此方法内部会使用 UPar.DeepClone 来克隆, 然后使用table.Merge来合并。
```
```lua
-- 例:
UPar.RegisterEffectEasy(
	'DParkour-Vault', 
	'default',
    'PunchCompat',
	{
		punch = true,
		upunch = false,
        AAAACreat = 'Zack',
		AAAContrib = '余智博',
		AAADesc = '禁用upunch, 这可以解决相机冲突问题。',
	}
)
```