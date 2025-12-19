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

## Introduction

### Example
Use the command `developer 1;up_reload_sv;up_reload_cl` to load examples.  
Sample code can be found in all Lua files containing the keyword "test".

### Consensus
```note
For UPAction and UPEffect, we should treat them as static containers and must not store any runtime results in them.
```

### Data Security
```note
To save development time and due to my limited understanding of Lua and framework design, I have not added protection to tables. Therefore, all tables in hooks can be directly manipulated—this provides convenience but also poses potential security risks. Exercise caution when operating on tables, or you can add protection to output tables as needed.

The best practice is to avoid initializing or manipulating context-dependent data in Start and Clear to ensure safety under extreme conditions.
```

### Changes
```note
Regarding the implementation of interruptions and similar features, SeqHook is now used. If the action "test_lifecycle" is running in a track and you trigger another action, the sequences "UParUParActAllowInterrupt_test_lifecycle" and "UParUParActInterrupt" will be executed. All other extensible features follow this pattern.

Added support for custom panels in the Action Editor.
Refactored the lifecycle, removed most rarely used parameters, and actions now support multi-track parallel execution.
```

- Author: 白狼 (ava741963@163.com)
- Translator: Miss DouBao
- Date: December 10, 2025
- Version: 3.0.0