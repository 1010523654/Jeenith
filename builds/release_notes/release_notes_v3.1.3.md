# v3.1.3 — 解卦/档案弹窗 pop 崩溃根治（hotfix）

## Bug 修复

v3.1.2 档案可正常增删改查，但解卦「选卦 / 历史」、档案「编辑 / 删除」弹窗点选时崩溃：

```
You have popped the last page off of the stack
currentConfiguration.isNotEmpty
```

**根因**：弹窗内 `Navigator.pop(context)` 用的是 `context`（go_router 页面 State context）最近的 Navigator = **go_router 的 Navigator**，pop 触发 go_router 页面断言。

**修复**：所有弹窗 pop 改为 `Navigator.of(context, rootNavigator: true).pop(...)`——pop 到 **MaterialApp root Navigator**（dialog 实际所在，showDialog `useRootNavigator` 默认 true），不碰 go_router page stack。

## 影响文件

- `features/jiekua/ui/jiekua_page.dart`（选卦 / 历史弹窗的 pop）
- `features/profiles/ui/profiles_page.dart`（编辑 / 删除弹窗的 pop）

## 验证

- `flutter analyze`：No issues found
- 全项目无遗漏的 `Navigator.pop(context)`（go_router 环境）

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_3.1.3_release_20260726_01.apk | 60.83 MB | `4EF246A2523E601FFD0C4D90870F1CEAD2FC8E187188543552E30CAF8A0FF48B` |
| Windows x64 | Jeenith_3.1.3_release_20260726_01_windows_x64.zip | 16.00 MB | `25890E760AF4F1386D32A584A8919778CA4127E3A5B73E775E0FEDF106B46078` |

## 版本信息

- **版本号**：3.1.3+52
- **构建状态**：release
- **构建日期**：2026-07-26
