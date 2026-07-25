# v3.0.0 — 底部三栏导航 + 档案 + 解卦(AI) + 入场仪式补全

## 概述

志极 3.0 大版本：首页升级为底部三栏导航（卜算 / 解卦 / 档案）；新增人物生辰档案管理与全方位卜算（紫微+八字+称骨融合）；接入 GLM-4-Flash 大模型实现 AI 解卦；补齐称骨、太乙的入场仪式。

## 新增功能

### 1. 底部三栏导航
- 「卜算」（现有 15 术首页）/「解卦」（居中凸起金色呼吸发光按钮）/「档案」
- `StatefulShellRoute` 各 tab 保状态；移除首页底部 copyright

### 2. 档案管理
- 新建/编辑/删除人物档案：姓名、公历生辰（时辰可选「未知」）、性别、备注
- 时辰未知时档案卡显示「时辰未知」标记

### 3. 全方位卜算（档案页）
- 对单个档案一次性推演：紫微斗数（命宫/五行局/主星）+ 八字推演（四柱）+ 称骨算命（骨重/命格/称骨歌/断辞），三结果融合展示
- 缺时辰降级：紫微/八字/称骨均需时辰，缺时辰三术不可用，提示并引导「补全时辰」

### 4. AI 解卦（GLM-4-Flash）
- 解卦页：从历史记录选卦象 + 输入问题 → GLM-4-Flash 大模型结合卦象详细解读并给建议
- 底部常驻「AI 生成未必全对，理性看待」
- 设置页「AI 解卦」分区填入智谱 API key（免费申请，不硬编码）；无 key 时引导

### 5. 入场仪式补全
- 称骨：鎏金铜钱落定 + 旋转
- 太乙：九宫星点逐个点亮
- 至此 15 术全部具备入场仪式

## 影响文件

- `shared/widgets/main_shell.dart`（新）、`router/app_router.dart`（StatefulShellRoute）
- `core/profiles/profile_store.dart`（新）、`features/profiles/ui/profiles_page.dart`、`profile_divination_page.dart`（新）
- `core/ai/glm_client.dart`（新）、`features/jiekua/ui/jiekua_page.dart`、`features/settings/settings_page.dart`
- `core/animation/ritual/chenggu_ritual.dart`（新）、`taiyi_ritual.dart`（新）
- `core/config/app_config.dart`、`config_providers.dart`（glmApiKey）
- `features/home/home_page.dart`、`test/profile_test.dart`（新）

## 验证

- `flutter analyze`：No issues found
- `flutter test`：27 项全过（紫微流年 8 + 六爻纳甲 16 + Profile 3）

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_3.0.0_release_20260726_01.apk | 59.60 MB | `CA18D846FDB067BE8C8185A714D5B51334E543E6506B80A6BFDBBDEC73E1A28B` |
| Windows x64 | Jeenith_3.0.0_release_20260726_01_windows_x64.zip | 15.77 MB | `C5F6B86B76A29045CD3D80598D72FD424FC1A9FC85E5070F54D0C2EF1A445EED` |

## 版本信息

- **版本号**：3.0.0+48
- **构建状态**：release
- **构建日期**：2026-07-26
