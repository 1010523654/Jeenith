# v3.1.4 — 解卦 AI 流式输出（打字机效果）

## 新增

解卦 AI 回复改为**流式输出**——GLM-4-Flash SSE 流（`stream: true`），逐字逐段实时填充 assistant 气泡，打字机式呈现，不再干等整段返回。

- **`GlmClient.chatStream`**：`http.Client.send` 拿到 `StreamedResponse`，按行解析 `data: {...}` 的 `choices[0].delta.content`，逐段 `yield`
- **解卦 `_send` 改流式**：先插一个空 assistant 气泡，逐 delta 填充 content 并实时 `setState`，气泡内容边生成边显示
- 保留 `chat` / `interpret` 一次性方法，兼容其他场景

## 影响文件

- `core/ai/glm_client.dart`（新增 `chatStream`）
- `features/jiekua/ui/jiekua_page.dart`（`_send` 改流式）

## 验证

- `flutter analyze`：No issues found

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_3.1.4_release_20260731_01.apk | 60.85 MB | `185AFD5BB5BB2B3948587E96AD9D2D7AE864179D95DECB0F9ED5177C8BDCE3CB` |
| Windows x64 | Jeenith_3.1.4_release_20260731_01_windows_x64.zip | 16.01 MB | `F639F64C26BA0F6B5DAD77C6FB8D0DC05435626FCEDA544F48E3EC8F741DD11E` |

## 版本信息

- **版本号**：3.1.4+53
- **构建状态**：release
- **构建日期**：2026-07-31
