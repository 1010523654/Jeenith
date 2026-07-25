# CLAUDE.md — 志极 Jeenith

> 项目定制规则。身份信息（组织/包名/署名）以 `D:\Code\.Rules\OrganizationAndUser.md` 为准。

## 一、项目信息

| 属性 | 值 |
|------|-----|
| 中文名 / 英文名 | 志极 / Jeenith |
| 项目类型 | 移动 App（Flutter，Android + Windows 桌面）|
| 所属组织 | Qore（叩心）|
| 应用包名 | `com.qore.jeenith` |
| 当前版本 | 2.10.4+44（fix，2026-07-23）|
| 项目位置 | `D:\Code\Project\Qore\Jeenith` |

**项目定位**：叩问本心的卜算合集——小六壬、周易、梅花易数、掷筊、紫微斗数、奇门遁甲、抽签、测字、大六壬、风水罗盘 + 使用手册。一个 APP 首页选术，可扩展卜算框架（加新术 = 新建 feature 目录 + 注册一行）。

## 二、目录结构

```
Jeenith/
  mobile/             # Flutter 项目
    lib/
      app.dart        # JeenithApp（MaterialApp.router + Starfield 背景 + 主题模式）
      main.dart       # 入口（async + ProviderScope + 桌面窗口尺寸初始化）
      core/           # branding / calendar / config / divination / history / rng / theme
      data/           # yijing（64卦 + 八卦数据，周易/梅花共用）
      features/       # home / xiaoliuren / zhouyi / meihua / jiaobei / ziwei / qimen / taiyi /
                      #   daliuren / liuyao / chouqian / cezi / chenggu / luopan / bazi / name_test / manual / settings / history
      providers/      # providers.dart（barrel 聚合 config + rng providers）
      router/         # app_router.dart（GoRouter + 仪式路由）
      shared/         # widgets/（GoldButton / DarkButton / AnimatedExpandIcon / SvgIcon /
                      #   DecorativePanel / InteractableCard / CopyResultButton /
                      #   ShareResultButton / GuideDialog / Starfield / SectionTitle）
    scripts/          # build_apk.ps1 + archive_history.py
    android/ ios/ web/ windows/ linux/ macos/
    pubspec.yaml
  backend/            # 占位（Jeenith 无后端）
  design/             # 占位（设计稿）
  docs/               # PROJECT_SUMMARY / FLUTTER_APK_BUILD_PIPELINE / NEXT_PLAN 等
  tools/              # 占位（工具脚本）
  builds/             # 构建产物归档（APK/ZIP + build_history.json + release_history.json）
```

## 三、技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Flutter 3.x（Dart 3.11+）|
| 状态管理 | Riverpod（flutter_riverpod ^2.5）|
| 路由 | go_router ^14.0 |
| 农历/八字/节气 | lunar ^1.7.8（寿星天文历）|
| 图标 | flutter_svg ^2.0 |
| 真随机 | dart:math Random.secure + 触摸轨迹 + http random.org + crypto SHA256 |
| 配置持久化 | shared_preferences ^2.2 |
| 设备传感器 | sensors_plus ^6.0.0（陀螺仪/磁场，风水罗盘）|
| 结果分享 | share_plus ^10.0.0 |
| 文件路径 | path_provider ^2.1.0（历史导出）|
| APP 图标 | flutter_launcher_icons ^0.14 |
| 微交互动效 | 自定义 AnimationController（封装在 core/theme/animations.dart）|

## 四、构建

```bash
cd mobile
flutter pub get
flutter analyze
# APK（脚本自动更新版本号 + 归档 + 双份历史）
pwsh -File scripts/build_apk.ps1 -Status release -TargetVersion "2.0.0"
# Windows 桌面
flutter build windows --release
# 产物归档：builds/android/（APK）、builds/windows/（zip，手动 Compress-Archive）
```

构建规范见 `docs/FLUTTER_APK_BUILD_PIPELINE.md`。产物归档到 `builds/`（与 mobile/ 平级）。

## 五、后续阶段

见 `docs/NEXT_PLAN/` 与项目 memory：
- 紫微 v2/奇门 v2/大六壬已落地（v1.3.0+ / v1.4.0 / v1.7.0），后续仍可深化细节
- 周易/梅花卦辞爻辞已落地（v1.2.0）
- 主题切换 + 结果分享 + 历史导出已落地（v1.5.0）
- v2.0.0 完成体验深化与品牌定调（按钮物理反馈 + 图标状态切换 + 动效开关）
- v2.1.0/v2.2.0 动效体系 Phase 1-6 全面落地（入场仪式 / 路由转场 / 绘制过程 / 结果揭示）
- v2.3.0 新增八字推演、测名字，重构紫微盘与设置页动画
- v2.3.1 起卦按钮 BUG 修复 + 动效曲线优化
- v2.3.2 设置页动画细分开关（4 个 AnimationKind 独立控制）+ Windows 应用图标修复
- v2.3.3 首页按钮间距修复 + 添加 MIT LICENSE + Windows 图标产物归档
- v2.4.0 八字/测字入场仪式 + 一键获取当前时间 + 测字词库扩展 + All rights reserved 全面移除
- v2.4.x 首次使用引导遮罩落地（TechGuideOverlay，紫微/奇门/大六壬分步导读）+ 全量浅色主题感知
- v2.5.0 紫微深化（四化/大限/长生/补煞）+ 奇门深化（天盘干/格局断辞）
- v2.6.0 称骨算命（袁天罡）— 第 13 术
- v2.7.0 太乙神数（三式之首）— 第 14 术，三式齐备
- v2.7.1 GoldButton 竖线坍塌根治 + 按压缩放延迟
- v2.8.0 六爻纳甲 — 第 15 术 + pinned header 修复（v2.8.1）
- v2.9.0/v2.9.1/v2.9.2 六爻断法深化（旬空 + 六冲六合 + 进退神）
- v2.10.0 浅色模式适配
- v2.10.1/v2.10.2/v2.10.3 GoldButton/DarkButton 竖线坍塌多次根治 + InteractableCard 崩溃修复 + 周易 ActionBar 自适应
- v2.10.4 DarkButton 浅色适配补齐 + configProvider 订阅修复 + SvgIcon fallback 主题感知
- v2.11.0 设置页数据与重置（清除数据/还原初设/归零重始）+ 应用级重启 + 首次使用引导遮罩扩展至周易/六爻/八字 + 周易/小六壬复制按钮 pinned header 修复
- v2.11.1 结果输出体验增强（复制文字动画/SnackBar/分享图署名）+ 历史记录搜索/筛选/批量删除
- v2.12.0 紫微流年/小限（流年命宫+四化+小限宫高亮+断辞+8单测）
- v3.0.0 底部三栏导航（卜算/解卦/档案）+ 档案管理（CRUD+紫微/八字/称骨全方位卜算）+ AI 解卦（GLM-4-Flash）+ 称骨/太乙入场仪式补全
- v3.1.0 解卦智能体（多轮对话 + Markdown 渲染 + 本地会话历史 + 过渡动画）
- 后续可考虑：择日黄历（第16术）、仪式动画浅色适配、紫微流年深化、解卦深化（当前卦直发/流式输出）、档案扩展（照片/亲属关系）、v3.x 新术数 / 数据云同步 / 国际化

## 六、规则

- 先看再改，理解上下文
- 身份信息以 OrganizationAndUser.md 为准，不硬编码
- 构建用 scripts/build_apk.ps1，版本号 + 归档 + 历史自动
- 加新卜算术 = 新建 features/xxx/ + 实现 DivinationTech + registry 注册一行
- 微交互动画统一封装在 core/theme/animations.dart，所有动效可通过设置页全局开关（AppConfig.animationsEnabled）
- CustomPainter 实现必须显式 dispose TextPainter，防止 native handle 泄漏
- HistoryStore 操作必须使用原子读-改-写模式，防止快速连续卜算时丢数据
