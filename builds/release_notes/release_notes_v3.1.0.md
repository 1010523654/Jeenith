# v3.1.0 — 解卦智能体（多轮对话 + Markdown + 本地历史 + 过渡动画）

## 概述

解卦页升级为对话式智能体：AI 记上下文、可连续追问；回复 Markdown 渲染；会话本地存档可回看；气泡入场与切换全程过渡动画，杜绝瞬间出现。

## 新增 / 改进

### 1. 多轮对话（智能体）
- `GlmClient.chat` 接收对话历史 messages，AI 结合卦象 + 此前问答上下文连续解读
- 用户可在首问后继续追问细节，AI 不丢上下文

### 2. Markdown 渲染
- AI 回复用 `flutter_markdown` 渲染（标题 / 加粗 / 分点列表），排版清晰
- system prompt 鼓励 AI 用 Markdown 排版

### 3. 本地会话历史
- `JiekuaStore`：每次解卦存为一个会话（卦象来源 + 多轮消息）
- 解卦页右上「历史」入口：查看 / 加载 / 删除过往会话

### 4. 过渡动画（无瞬间出现）
- `AnimatedList` 气泡入场（slide + fade，方向随 user/assistant 区分）
- 卦象来源条、发送按钮用 `AnimatedSwitcher` 过渡
- 会话切换平滑重建

### 5. 对话气泡
- user：右对齐金色气泡，普通文本
- assistant：左对齐卡片，Markdown 渲染，最大宽 82%

## 影响文件

- `core/ai/glm_client.dart`（多轮 chat + GlmMessage，保留 interpret 兼容）
- `core/ai/jiekua_store.dart`（新：会话存储）
- `features/jiekua/ui/jiekua_page.dart`（重构为对话式）
- `pubspec.yaml`（加 flutter_markdown）

## 验证

- `flutter analyze`：No issues found
- `flutter test`：27 项全过

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_3.1.0_release_20260726_01.apk | 60.83 MB | `52A0A7AA4F8F2A3209E374F21CB69DFE27BC6A5705DF1B9E9F2E0E8F6FB08176` |
| Windows x64 | Jeenith_3.1.0_release_20260726_01_windows_x64.zip | 16.00 MB | `3C033114F968267A3D648F3948B1158D089D0680B4359905D485E1E10C8E1EFF` |

## 版本信息

- **版本号**：3.1.0+49
- **构建状态**：release
- **构建日期**：2026-07-26
