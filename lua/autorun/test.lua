// print(1)
// if SERVER then return end
// GlobalPnlCache = GlobalPnlCache or {}

// // local pnl = vgui.Create("DPanel")
// // pnl.myData = {hugeData = 666666}
// // GlobalPnlCache.myPanel = pnl

// // pnl:Remove()

// PrintTable(GlobalPnlCache)
// print(GlobalPnlCache.myPanel.myData.hugeData)


// -- 原数据：内部有两个键指向同一个Vector，且有循环引用
// local vec = Vector(1,2,3)

// local original = {
//     a = vec,   -- 键a指向vec
//     b = vec,   -- 键b也指向同一个vec
//     selfRef = nil
// }
// original.selfRef = original -- 循环引用

// -- 深拷贝
// local cloned = UPar.DeepClone(original)

// -- 验证内部引用关系：
// print(cloned ~= original)
// print(original.a == original.b) -- true（原数据中a和b指向同一个vec）
// print(cloned.a == cloned.b)     -- true（拷贝后a和b仍指向同一个拷贝后的vec）
// print(cloned.selfRef == cloned) -- true（循环引用关系保留，且不崩溃）
// print(cloned.a ~= original.a)   -- false (并非内存地址比较)

// cloned.a[1] = 100
// cloned.a[2] = 200
// cloned.b[3] = 300
// print(cloned.a, original.a) -- 100

// // print(Vector(1) == Vector(1))

// local baseContainer = {name = "test", version = 1.0}
// local baseInjector = {
//     name = "override_me",  -- 跳过
//     desc = "basic inject test",  -- 补充
//     author = "whitewolf"  -- 补充
// }
// UPar.DeepInject(baseContainer, baseInjector)
// print("=== 基础补全测试 ===")
// PrintTable(baseContainer)
// print("=== 基础Injector ===")
// PrintTable(baseInjector)

// -- 测试2：嵌套Table补全
// local nestedContainer = {
//     info = {type = "nested", id = 100}
// }
// local nestedInjector = {
//     info = {
//         id = 200,  -- 跳过
//         detail = "nested table test"  -- 递归补充
//     },
//     config = {max = 10, min = 1}  -- 补充
// }
// UPar.DeepInject(nestedContainer, nestedInjector)
// print("\n=== 嵌套Table补全测试 ===")
// PrintTable(nestedContainer)
// print("=== 嵌套Injector ===")
// PrintTable(nestedInjector)

// -- 测试3：循环引用防护（避免递归崩溃）
// local loopInjector = {name = "loop test"}
// loopInjector.selfRef = loopInjector  -- 构造循环引用
// local loopContainer = {}
// UPar.DeepInject(loopContainer, loopInjector)
// print("\n=== 循环引用防护测试 ===")
// PrintTable(loopContainer)
// print("=== 循环Injector ===")
// PrintTable(loopInjector)

// -- 测试4：元表继承（容器无元表时继承注射器的元表）
// local metaInjector = setmetatable({}, {__index = {msg = "meta table test"}})
// local metaContainer = {}
// UPar.DeepInject(metaContainer, metaInjector)
// print("\n=== 元表继承测试 ===")
// print("metaContainer.msg:", getmetatable(metaContainer).__index.msg)  -- 输出：meta table test