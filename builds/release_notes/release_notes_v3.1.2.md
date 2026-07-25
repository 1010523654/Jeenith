# v3.1.2 — 档案/解卦存储 unmodifiable list 崩溃根治（hotfix）

## Bug 修复

v3.1.1 试图修复档案首次新增崩溃，但只改了 `ProfileStore.load` 的部分 `const` 返回，**漏了 `if (s == null) return const`（行内仍是 const）**，导致首次新增档案仍崩。本次根治：

- `ProfileStore` / `JiekuaStore` 的 add / update / remove / upsert 改用 `<Type>[...await load()]` 拷贝出全新的可修改列表——**无论 `load` 返回是否可修改，写入操作均安全**
- 加 `ProfileStore.add / update / remove` 单测，含「空存储 add 不崩」回归项

## 影响文件

- `core/profiles/profile_store.dart`
- `core/ai/jiekua_store.dart`
- `test/profile_test.dart`

## 验证

- `flutter analyze`：No issues found
- `flutter test`：profile_test 5 项全过（含空存储 add / update / remove）

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_3.1.2_release_20260726_01.apk | 60.83 MB | `2A7D6F5AC1707FE5E1492F535DD7764C041201BBE5457CFF701B6458D8B90238` |
| Windows x64 | Jeenith_3.1.2_release_20260726_01_windows_x64.zip | 16.00 MB | `ADA9B6E4BDE6B400F284F8CEBE354C676EC360A52E92935F69C8F85BAA8E2168` |

## 下一步计划：深化「全方位卜算」

- **三术交叉印证**：紫微 / 八字 / 称骨 结果互相参照，给出融合断语（而非当前的三块并列）
- **每术更详细**：紫微加大限/流年要点、八字加十神/大运/旺衰、称骨加逐年运势
- **缺时辰降级**：称骨支持「无时辰估算」（年月日三骨 + 时辰均值），让缺时辰档案也能部分卜算
- **可视化融合**：三术关键指标（命局强弱 / 吉凶偏向 / 大运节点）一图统览

## 版本信息

- **版本号**：3.1.2+51
- **构建状态**：release
- **构建日期**：2026-07-26
