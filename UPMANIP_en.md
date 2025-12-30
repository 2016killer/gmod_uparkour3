<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## Table of Contents

<a href="./UPACTION_en.md">UPAction</a>  
<a href="./UPEFFECT_en.md">UPEffect</a>  
<a href="./SERHOOK_en.md">SeqHook</a>  
<a href="./HOOK_en.md">Hook</a>  
<a href="./LRU_en.md">LRU</a>  
<a href="./CUSTOMEFFECT_en.md">Custom Effect</a>  
<a href="./UPMANIP_en.md">UPManip</a>  
<a href="./UPKEYBOARD_en.md">UPKeyboard</a>  

# UPManip - Bone Manipulation
```note
Note: This is a test module and is not recommended for use in a production environment.
```


## Overview
The `upmanip_test` console command can be used to test the functionality of UPManip.

This is a **client-side only** API that provides direct control over bones via methods such as **ent:ManipulateBonexxx**.

### Advantages:
1. Directly manipulates bones without the need for methods like **ent:AddEffects(EF_BONEMERGE)**, **BuildBonePositions**, or **ResetSequence**.
2. Compared to **VMLeg**, it supports fade-out animations, and no snapshots are required for these fade-out animations.

### Disadvantages:
1. High computational overhead, as several matrix operations need to be performed via **Lua** each time.
2. Requires per-frame updates.
3. Cannot handle singular matrices, which typically occur when a bone's scale is set to 0.
4. May conflict with other methods that use **ent:ManipulateBonexxx**, resulting in abnormal animations.

## Available Methods

![client](./materials/upgui/client.jpg)
**vec, ang** UPManip.SetBonePosition(**entity** ent, **int** boneId, **vector** posw, **angle** angw)
```note
Controls the position and angle of the specified bone of the target entity.
The new position cannot be too far from the old position (128 units maximum).
It is recommended to call ent:SetupBones() before using this function, as the current bone matrix is required for calculations.
```

![client](./materials/upgui/client.jpg)
**table** UPManip.SnapshotManip(**entity** ent, **table** boneMapping)
```note
Returns the current position and angle of the specified bones of the entity.
Internally uses ent:ManipulateBonexxx() methods.
```

![client](./materials/upgui/client.jpg)
**entity** UPManip.GetEntAnimFadeIdentity(**entity** ent)
```note
Returns the animation fade-in iterator identifier of the specified entity.
```

![client](./materials/upgui/client.jpg)
**bool** UPManip.IsEntAnimFade(**entity** ent)
```note
Determines whether the entity has an animation fade-in iterator.
```

![client](./materials/upgui/client.jpg)
**bool** UPManip:AnimFadeIn(**entity** ent, **entity** or **table** target or snapshot, **table** boneMapping, **float** speed=3, **float** timeout=2)
```note
boneMapping specifies the bones to be manipulated.

The fade-in time is 1 / speed seconds. Manual fade-out is required.
If the target is an entity, automatic fade-out will occur when the target is deleted.

Internally uses UPar.PushIterator to add an iterator. Returns whether the operation succeeded.
No action is taken after the iterator times out.
```

![client](./materials/upgui/client.jpg)
**bool** UPManip:AnimFadeOut(**entity** ent, **table** or **nil** snapshot, **float** speed=3, **float** timeout=2)
```note
boneMapping specifies the bones to be manipulated.
If snapshot is nil, the current snapshot will be used.

The fade-out time is 1 / speed seconds.

No action is taken after the iterator times out.
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
	print('Fade out')
end)

timer.Simple(timeout + 1, function() 
	Eli:Remove()
	gman_high:Remove()
end)
```