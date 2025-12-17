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
<a href="./CUSTOMEFFECT_en.md">Custom Effect</a>  

```note
To save development time, i have not added protection to the tables. Therefore, all tables in the hooks can be directly manipulated. This provides convenience but also introduces certain security risks, so you need to exercise caution when manipulating the tables.
```

```note
Regarding the implementation of interrupts and related logic, now use the sequence hook approach instead. Previously, functions were directly inserted into tables — while this old method might have had higher query efficiency, it was rather cumbersome. Given that interrupt functions have a relatively low reuse rate, we’ve adopted the sequence hook implementation.

Regarding the overriding or extension of interfaces, i still use the approach of directly inserting functions into tables, as interface functions have a slightly higher reuse rate.
```

- Author: 白狼 ava741963@163.com
- Translator: Miss DouBao  
- Date: December 10, 2025  
- Version: 3.0.0  