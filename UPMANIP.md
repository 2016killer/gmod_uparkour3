<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## 目录

<a href="./UPACTION.md">UPAction</a>  
<a href="./UPEFFECT.md">UPEffect</a>  
<a href="./SERHOOK.md">SeqHook</a>  
<a href="./HOOK.md">Hook</a>  
<a href="./LRU.md">LRU</a>  
<a href="./CUSTOMEFFECT.md">Custom Effect</a>  
<a href="./UPMANIP.md">UPManip</a>  
<a href="./UPKEYBOARD.md">UPKeyboard</a>  

# UPManip 骨骼操纵
## 简介
使用 `upmanip_test` 控制台指令可以测试 UPManip 的功能。

这是一个**纯客户端**的API, 通过 **ent:ManipulateBonexxx** 等方法对骨骼进行直接的控制。  

优点: 
1. 直接操作骨骼, 无需通过 **ent:AddEffects(EF_BONEMERGE)** 、 **BuildBonePositions** 、 **ResetSequence** 等方法。
2. 相比 **VMLeg** , 它拥有淡出动画 并且 淡出动画不需要快照。  

缺点:
1. 运算量较大, 每次都需通过 **lua** 进行几次矩阵运算。
2. 需要每帧更新。
3. 无法处理奇异的矩阵, 这通常发生在骨骼缩放为0时。
4. 可能会和使用了 **ent:ManipulateBonexxx** 的方法冲突, 导致动画异常。
## 可用方法

![client](./materials/upgui/client.jpg)
UPManip.SetBonePosition(**entity** ent, **int** boneId, **vector** posw, **angle** angw)
```note
控制指定实体的指定骨骼的位置和角度, 新的位置不能距离旧位置太远 (128个单位)
最好在调用之前使用 ent:SetupBones(), 因为计算中需要当前骨骼矩阵。
```

![client](./materials/upgui/client.jpg)
UPManip.AnimFadeIn(**entity** ent, **entity** target, **table** boneMapping, **float** speed=3, **float** timeout=2)
```note
控制指定实体的指定骨骼淡入到目标的动画, 动画时间为 1 / speed 秒, 超时后会清空 ManipulateBonexxx, boneMapping 指定了需要操纵的骨骼名以及对应目标的骨骼名。

内部会使用 UPar.UParIteratorPush 添加迭代器, 标志位是实体。
```

![client](./materials/upgui/client.jpg)
UPManip.AnimFadeOut(**entity** ent, **table** boneMapping, **float** speed=3, **float** timeout=2)
```note
控制指定实体的指定骨骼淡出动画, 淡出时间为 1 / speed 秒, 超时后不做任何事, boneMapping 指定了需要淡出的骨骼名。

内部会使用 UPar.UParIteratorPop 弹出淡入的迭代器, 然后使用 UPar.UParIteratorPush 添加迭代器, 标志位是实体。
```

```lua
local ply = LocalPlayer()
local Eli = ClientsideModel('models/Eli.mdl', RENDERGROUP_OTHER)
local gman_high = ClientsideModel('models/gman_high.mdl', RENDERGROUP_OTHER)

local speed = 1
local timeout = 1
local boneMapping = {
	['ValveBiped.Bip01_Head1'] = {
		-- 最终的偏移矩阵由三个部分合成, 但为了方便理解, 这里将其拆分为位置偏移、角度偏移、缩放偏移
		boneName = 'ValveBiped.Bip01_Head1', -- 目标骨骼名
		pos = Vector(10, 0, 0), -- 位置偏移
		ang = Angle(20, 0, 0), -- 角度偏移
		scale = Vector(2, 1, 1), -- 缩放偏移
	},
	['ValveBiped.Bip01_L_Calf'] = true, -- 使用恒等映射获取骨骼名
}

local pos1 = ply:GetPos() + 100 * ply:EyeAngles():Forward()
local pos2 = pos1 + 100 * ply:EyeAngles():Right()

Eli:SetPos(pos1)
Eli:SetupBones()

gman_high:SetPos(pos2)
gman_high:SetupBones()

UPManip.AnimFadeIn(Eli, gman_high, boneMapping, speed, timeout)
timer.Simple(timeout * 0.5, function() 
	UPManip.AnimFadeOut(Eli, boneMapping, speed, timeout) 
end)

timer.Simple(timeout + 1, function() 
	Eli:Remove()
	gman_high:Remove()
end)
```