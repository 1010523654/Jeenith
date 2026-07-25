// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

final configProvider = AsyncNotifierProvider<ConfigNotifier, AppConfig>(
  ConfigNotifier.new,
);

class ConfigNotifier extends AsyncNotifier<AppConfig> {
  /// prefs key 前缀。完整格式：`anim_<techId>_<kind>`，如 `anim_xiaoliuren_entrance`。
  static const String _kAnimPrefix = 'anim_';

  @override
  Future<AppConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    // Read all animation settings whose key starts with `anim_`.
    // Format: anim_<techId>_<kind>，其中 techId 可能含下划线（如 name_test），
    // 因此以最后一个下划线分段：尾部为 kind，前面合并为 techId。
    final raw = <String, Map<String, bool>>{};
    final knownKinds = AnimationKind.values.map((k) => k.name).toSet();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_kAnimPrefix)) continue;
      final suffix = key.substring(_kAnimPrefix.length);
      final lastUnderscore = suffix.lastIndexOf('_');
      if (lastUnderscore <= 0) continue; // 跳过旧格式 anim_<techId>
      final kindStr = suffix.substring(lastUnderscore + 1);
      final techId = suffix.substring(0, lastUnderscore);
      if (!knownKinds.contains(kindStr)) continue; // 未知 kind 跳过
      raw.putIfAbsent(techId, () => {});
      raw[techId]![kindStr] = prefs.getBool(key) ?? true;
    }
    return AppConfig(
      showDetails: prefs.getBool('showDetails') ?? true,
      useOnline: prefs.getBool('useOnline') ?? true,
      animationsEnabled: prefs.getBool('animationsEnabled') ?? true,
      animationSettings: raw,
      themeMode: _parseThemeMode(prefs.getString('themeMode')),
      glmApiKey: prefs.getString('glmApiKey') ?? '',
    );
  }

  Future<void> setShowDetails(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showDetails', v);
    final current = await future;
    state = AsyncData(current.copyWith(showDetails: v));
  }

  Future<void> setUseOnline(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useOnline', v);
    final current = await future;
    state = AsyncData(current.copyWith(useOnline: v));
  }

  Future<void> setAnimationsEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animationsEnabled', v);
    final current = await future;
    state = AsyncData(current.copyWith(animationsEnabled: v));
  }

  /// Toggle one [AnimationKind] for a single tech.
  Future<void> setAnimationSetting(
      String techId, AnimationKind kind, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kAnimPrefix${techId}_${kind.name}', v);
    final current = await future;
    final next = Map<String, Map<String, bool>>.from(current.animationSettings);
    next[techId] = Map<String, bool>.from(next[techId] ?? {});
    next[techId]![kind.name] = v;
    state = AsyncData(current.copyWith(animationSettings: next));
  }

  /// One-click bulk toggle: enable or disable all 4 kinds for all given techs.
  Future<void> setAllAnimations(List<String> techIds, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in techIds) {
      for (final kind in AnimationKind.values) {
        await prefs.setBool('$_kAnimPrefix${id}_${kind.name}', v);
      }
    }
    final current = await future;
    final next = Map<String, Map<String, bool>>.from(current.animationSettings);
    for (final id in techIds) {
      next[id] = Map<String, bool>.from(next[id] ?? {});
      for (final kind in AnimationKind.values) {
        next[id]![kind.name] = v;
      }
    }
    state = AsyncData(current.copyWith(animationSettings: next));
  }

  Future<void> setThemeMode(ThemeMode v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _stringifyThemeMode(v));
    final current = await future;
    state = AsyncData(current.copyWith(themeMode: v));
  }

  /// 设置 GLM API key（v3.0.0 解卦用）。
  Future<void> setGlmApiKey(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('glmApiKey', v);
    final current = await future;
    state = AsyncData(current.copyWith(glmApiKey: v));
  }

  /// 重置所有设置为默认值（v2.11.0：「还原初设」/「归零重始」用）。
  ///
  /// 移除 showDetails / useOnline / animationsEnabled / themeMode 及全部
  /// anim_* 细分开关，状态置为 [AppConfig.defaults]。仅清设置，不动
  /// 卜算历史与引导标记（那些由 `AppData` 负责）。
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('showDetails');
    await prefs.remove('useOnline');
    await prefs.remove('animationsEnabled');
    await prefs.remove('themeMode');
    await prefs.remove('glmApiKey');
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_kAnimPrefix)) await prefs.remove(key);
    }
    state = const AsyncData(AppConfig.defaults);
  }

  static ThemeMode _parseThemeMode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static String _stringifyThemeMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
