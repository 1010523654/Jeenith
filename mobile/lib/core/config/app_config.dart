// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

/// 动画细分类型（v2.3.2：从单一开关拆分为 4 个独立开关）。
///
/// - [entrance]：入场仪式（仪式动画页面 / 路由前置过渡）
/// - [transition]：路由转场（TechTransition）
/// - [painter]：绘制过程（CustomPainter 的 progress 动画）
/// - [reveal]：结果揭示（RevealAnimation 封装）
enum AnimationKind { entrance, transition, painter, reveal }

/// 应用配置（真随机熵源开关 + 展示开关 + 微交互动效总开关 + 按术数分类的动画设置 + 主题模式）。
///
/// v2.3.0: 把原本分散的 `xiaoliurenCinematic` / `ritualAnimationsEnabled` /
/// `painterAnimationsEnabled` / `revealAnimationsEnabled` / `transitionsEnabled`
/// 合并为 `animationSettings: Map<String, bool>`，Key 为各术 id（如
/// `xiaoliuren`/`zhouyi`/`bazi` 等）。
///
/// v2.3.2: 进一步细分为 `animationSettings: Map<String, Map<String, bool>>`，
/// 外层 key 为 techId，内层 key 为 [AnimationKind] 字符串形式
/// （`entrance`/`transition`/`painter`/`reveal`）。旧的 prefs key `anim_<techId>`
/// 不再读取（向前兼容：未记录时默认全部为 true）。
class AppConfig {
  final bool showDetails;                  // 起卦后展示采样详情
  final bool useOnline;                    // 在线大气噪声 random.org
  final bool animationsEnabled;            // 微交互动效总开关（按钮缩放/图标旋转/卡片错峰等）
  /// 按术数分类的动画开关。外层 key = tech id；内层 key = [AnimationKind] 名。
  final Map<String, Map<String, bool>> animationSettings;
  final ThemeMode themeMode;               // 主题模式：system/light/dark
  final String glmApiKey;                  // v3.0.0 GLM-4-Flash API key（解卦用）

  const AppConfig({
    required this.showDetails,
    required this.useOnline,
    this.animationsEnabled = true,
    this.animationSettings = const {},
    this.themeMode = ThemeMode.dark,
    this.glmApiKey = '',
  });

  /// 默认配置：所有术的所有 kind 动画开关都为 true。
  /// 新增术时，注册表中对应 id 默认视为 true（通过 `isAnimationEnabled` 读取）。
  static const defaults = AppConfig(
    showDetails: true,
    useOnline: true,
    animationsEnabled: true,
    animationSettings: {},
    themeMode: ThemeMode.dark,
    glmApiKey: '',
  );

  /// 读取某术某类动画开关。未在 Map 中显式记录时默认 true（向前兼容）。
  bool isAnimationEnabled(String techId, AnimationKind kind) =>
      animationSettings[techId]?[kind.name] ?? true;

  AppConfig copyWith({
    bool? showDetails,
    bool? useOnline,
    bool? animationsEnabled,
    Map<String, Map<String, bool>>? animationSettings,
    ThemeMode? themeMode,
    String? glmApiKey,
  }) =>
      AppConfig(
        showDetails: showDetails ?? this.showDetails,
        useOnline: useOnline ?? this.useOnline,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
        animationSettings: animationSettings ?? this.animationSettings,
        themeMode: themeMode ?? this.themeMode,
        glmApiKey: glmApiKey ?? this.glmApiKey,
      );
}
