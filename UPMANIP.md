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

# UPManip 骨骼操纵
```note
注意: 这是一个测试性模块, 不建议在生产环境中使用。
```


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
**vec**, **ang** UPManip.SetBonePosition(**entity** ent, **int** boneId, **vector** posw, **angle** angw)
```note
控制指定实体的指定骨骼的位置和角度, 新的位置不能距离旧位置太远 (128个单位)
最好在调用之前使用 ent:SetupBones(), 因为计算中需要当前骨骼矩阵。
```

![client](./materials/upgui/client.jpg)
**table** UPManip.SnapshotManip(**entity** ent, **table** boneMapping)
```note
返回当前实体的指定骨骼的位置和角度。
内部使用 ent:ManipulateBonexxx()
```

![client](./materials/upgui/client.jpg)
**entity** UPManip.GetEntAnimFadeIdentity(**entity** ent)
```note
返回指定实体的动画淡入迭代器标志位。
```

![client](./materials/upgui/client.jpg)
**bool** UPManip.IsEntAnimFade(**entity** ent)
```note
判断实体是否有动画淡入迭代器。
```

![client](./materials/upgui/client.jpg)
**bool** UPManip:AnimFadeIn(**entity** ent, **entity** or **table** target or snapshot, **table** boneMapping, **float** speed=3, **float** timeout=2)
```note
boneMapping 指定了需要操纵的骨骼。

淡入时间为 1 / speed 秒, 需要手动淡出, 如果 target 是实体, 当 target 被删除时会自动淡出。

内部会使用 UPar.UParIteratorPush 添加迭代器, 返回是否成功。
迭代器超时后不做任何事。
```

![client](./materials/upgui/client.jpg)
**bool** UPManip:AnimFadeOut(**entity** ent, **table** or **nil** snapshot, **float** speed=3, **float** timeout=2)
```note
boneMapping 指定了需要操纵的骨骼。
snapshot 为 nil 则使用当前快照。

淡出时间为 1 / speed 秒

迭代器超时后不做任何事。
```

```lua
local ply = LocalPlayer()
local Eli = ClientsideModel('models/Eli.mdl', RENDERGROUP_OTHER)
local gman_high = ClientsideModel('models/gman_high.mdl', RENDERGROUP_OTHER)

local speed = 1
local timeout = 10
local boneMapping = {
	['ValveBiped.Bip01_Head1'] = {pos = Vector(10, 0, 0), ang = Angle(0, 90, 0), scale = Vector(2, 1, 1)},
	['ValveBiped.Bip01_L_Calf'] = true,
}

local pos1 = ply:GetPos() + 100 * UPar.XYNormal(ply:EyeAngles():Forward())
local pos2 = pos1 + 100 * UPar.XYNormal(ply:EyeAngles():Right())

Eli:SetPos(pos1)
Eli:SetupBones()

gman_high:SetupBones()
gman_high:SetPos(pos2)

UPManip:AnimFadeIn(Eli, gman_high, boneMapping, speed, timeout)
timer.Simple(timeout * 0.5, function() 
	UPManip:AnimFadeOut(Eli, nil, speed, timeout)
	print('淡出')
end)

timer.Simple(timeout + 1, function() 
	Eli:Remove()
	gman_high:Remove()
end)
```