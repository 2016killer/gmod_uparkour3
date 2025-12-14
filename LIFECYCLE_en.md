<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## Table of Contents

<a href="./UPACTION_en.md">UPAction</a>  
<a href="./UPEFFECT_en.md">UPEffect</a>  
<a href="./SERHOOK_en.md">SeqHook</a>  
<a href="./HOOK_en.md">Hook</a>  
<a href="./LIFECYCLE_en.md">Lifecycle</a>  
<a href="./LRU_en.md">LRU</a>   


# About Lifecycle
**UPAction.TrackId**
```note
This is the core parameter.
- If actions are on the same track, an interruption will be triggered. For example, if a vault check is triggered while climbing is in progress, the interruption process will be initiated.
- If actions are on different TrackIds (e.g., an inspection action), they can run in parallel with climbing or vaulting.
```

![uplife](materials/upgui/uplife_en.jpg)
![uplife2](materials/upgui/uplife2_en.jpg)
