# v3.1.1 — 档案 CRUD 崩溃修复 + 档案/解卦视觉重做（去原生 Material）

## Bug 修复

- **档案首次新增崩溃**：`ProfileStore.load` 在无数据时返回 `const <Profile>[]`（不可修改），首次 `add` 执行 `list.insert` 抛 `Cannot add to an unmodifiable list`。改为返回可修改空列表。

## 视觉重做（去原生 Material，紧扣主题）

针对 v3.0/v3.1 档案页、解卦页使用原生 Material 组件（AlertDialog / DropdownButton / IconButton / ListTile / CircularProgressIndicator 等）造成的割裂感，全面重做为主题化组件：

### 新增 `ThemedDialog`（共享组件）
- 替代 AlertDialog：`BackdropFilter` 背景模糊渐入 + 金边主题卡片 + scale easeOutBack 入场 + 标题鎏金竖条
- 全局复用（档案编辑/删除、解卦选卦/历史）

### 档案页重做
- **12 时辰 chip 网格**（子丑寅卯…+「未知」）替代 DropdownButton，点选切换，主题金色
- 性别 chip、主题档案卡（性别徽章 + 时辰标注 + 备注）、列表错峰入场动画
- 所有 IconButton → GestureDetector + 主题图标

### 解卦页重做
- 选卦 / 历史弹窗 → ThemedDialog（自定义列表项替代 ListTile）
- AppBar 操作 / 列表项 → GestureDetector + 主题图标
- loading → DivinationLoadingIndicator（替 CircularProgressIndicator）
- 气泡主题金边 + 发送按钮主题圆形

## 影响文件

- `core/profiles/profile_store.dart`（bug 修）
- `shared/widgets/themed_dialog.dart`（新）
- `features/profiles/ui/profiles_page.dart`（重做）
- `features/jiekua/ui/jiekua_page.dart`（重做）

## 验证

- `flutter analyze`：No issues found
- `flutter test`：27 项全过

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_3.1.1_release_20260726_01.apk | 60.83 MB | `7B59B0BDEC5E4B7B05319FE7E5F7E73A4287873BE1697B99CF2612416A096CC1` |
| Windows x64 | Jeenith_3.1.1_release_20260726_01_windows_x64.zip | 16.00 MB | `2E974515B910264B0FB4BD8B7C9D46E0BCB1335B7852F4C283C7D8D0F5979931` |

## 版本信息

- **版本号**：3.1.1+50
- **构建状态**：release
- **构建日期**：2026-07-26
