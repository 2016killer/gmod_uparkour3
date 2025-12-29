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
UPManip.SetBonePosition(**entity** ent, **int** boneId, **vector** posw, **angle** angw)
```note
Controls the position and angle of the specified bone on the specified entity. The new position must not be too far from the old position (128 units).
It is recommended to call ent:SetupBones() before invoking this method, as the current bone matrix is required for calculations.
```

![client](./materials/upgui/client.jpg)
UPManip.AnimFadeIn(**entity** ent, **entity** target, **table** boneMapping, **float** speed=3, **float** timeout=2)
```note
Controls the specified bones of the source entity to fade in to the animation state of the target entity. The animation duration is 1 / speed seconds. 
After the timeout, all ManipulateBonexxx operations will be cleared. boneMapping specifies the names of the bones to be manipulated and their corresponding bone names on the target entity.

Internally, it uses UPar.UParIteratorPush to add an iterator, with the entity as the flag.
```

![client](./materials/upgui/client.jpg)
UPManip.AnimFadeOut(**entity** ent, **table** boneMapping, **float** speed=3, **float** timeout=2)
```note
Controls the specified bones of the entity to perform a fade-out animation. The fade-out duration is 1 / speed seconds. No action will be taken after the timeout.
boneMapping specifies the names of the bones to be faded out.

Internally, it first uses UPar.UParIteratorPop to remove the fade-in iterator, then uses UPar.UParIteratorPush to add a new iterator, with the entity as the flag.
```

```lua
local ply = LocalPlayer()
local Eli = ClientsideModel('models/Eli.mdl', RENDERGROUP_OTHER)
local gman_high = ClientsideModel('models/gman_high.mdl', RENDERGROUP_OTHER)

local speed = 1
local timeout = 1
local boneMapping = {
	['ValveBiped.Bip01_Head1'] = {
		-- The final offset matrix is composed of three parts. For ease of understanding, it is split into position offset, angle offset, and scale offset here.
		boneName = 'ValveBiped.Bip01_Head1', -- Target bone name
		pos = Vector(10, 0, 0), -- Position offset
		ang = Angle(20, 0, 0), -- Angle offset
		scale = Vector(2, 1, 1), -- Scale offset
	},
	['ValveBiped.Bip01_L_Calf'] = true, -- Use identity mapping to get the bone name
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