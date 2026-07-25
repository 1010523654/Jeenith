// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app/restart_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_providers.dart';
import '../../core/data/app_data.dart';
import '../../core/divination/divination_registry.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/divination_loading_indicator.dart';
import '../../shared/widgets/section_title.dart';

/// 设置页：外观 + 动画/动效（按卜算术分类，一键全控）+ 随机与展示 + 数据与重置。
///
/// v2.3.0：合并「动效」与「动画设置」为单一「◆ 动画/动效」分区。
/// v2.3.2：每术 ExpansionTile 拆 4 个细分开关（AnimationKind）。
/// v2.4.2：全面主题感知，浅色模式适配。
/// v2.11.0：新增「◆ 数据与重置」分区（清除数据 / 还原初设 / 归零重始）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppClr.of(context);
    final goldDivider = c.resolve(
        const Color.fromRGBO(212, 168, 87, 0.18),
        const Color.fromRGBO(155, 122, 42, 0.25));
    final configAsync = ref.watch(configProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('设　置'),
      ),
      body: configAsync.when(
        loading: () =>
            const Center(child: DivinationLoadingIndicator(size: 48)),
        error: (e, _) => Center(child: Text('载入失败：$e')),
        data: (cfg) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SectionTitle('◆ 外观', color: c.goldBright),
            const SizedBox(height: 4),
            _card(
              context,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      Text('主题模式', style: TextStyle(color: c.textPrimary)),
                      const SizedBox(width: 8),
                      Text('跟随系统/浅色/深色',
                          style: TextStyle(
                              color: c.textSubtitle, fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('跟随'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('浅色'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('深色'),
                      ),
                    ],
                    selected: {cfg.themeMode},
                    onSelectionChanged: (modes) => ref
                        .read(configProvider.notifier)
                        .setThemeMode(modes.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SectionTitle('◆ 动画/动效', color: c.goldBright),
            const SizedBox(height: 4),
            _card(
              context,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  title: Text('启用微交互动效',
                      style: TextStyle(color: c.textPrimary)),
                  subtitle: Text(
                      '按钮按动缩放/图标状态切换/卡片错峰等微交互（关闭后不影响功能）',
                      style:
                          TextStyle(color: c.textSubtitle, fontSize: 12)),
                  value: cfg.animationsEnabled,
                  onChanged: (v) => ref
                      .read(configProvider.notifier)
                      .setAnimationsEnabled(v),
                ),
                Divider(color: goldDivider, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text('开启所有分类'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.goldBright,
                            side: BorderSide(
                                color: c.gold.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => ref
                              .read(configProvider.notifier)
                              .setAllAnimations(
                                  ref.read(visibleTechsProvider).map((t) => t.id).toList(),
                                  true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.deselect, size: 16),
                          label: const Text('关闭所有分类'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.textSubtitle,
                            side: BorderSide(
                                color: c.textSubtitle.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => ref
                              .read(configProvider.notifier)
                              .setAllAnimations(
                                  ref.read(visibleTechsProvider).map((t) => t.id).toList(),
                                  false),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: goldDivider, height: 1),
                ...ref.watch(visibleTechsProvider).map((t) => ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      iconColor: c.gold,
                      collapsedIconColor: c.textSubtitle,
                      title: Text(t.meta.displayName,
                          style: TextStyle(
                              color: c.goldBright,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      children: [
                        _kindSwitch(context, cfg, ref, t.id, AnimationKind.entrance,
                            '入场仪式', '仪式入场动画（路由前置过渡）'),
                        _kindSwitch(context, cfg, ref, t.id, AnimationKind.transition,
                            '路由转场', '进入此术时的路由过渡动画'),
                        _kindSwitch(context, cfg, ref, t.id, AnimationKind.painter,
                            '绘制过程', 'CustomPainter 绘制过程动画'),
                        _kindSwitch(context, cfg, ref, t.id, AnimationKind.reveal,
                            '结果揭示', '结果段落错峰淡入与打字机'),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 20),

            SectionTitle('◆ 随机与展示', color: c.goldBright),
            const SizedBox(height: 4),
            _card(
              context,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  title: Text('展示采样详情',
                      style: TextStyle(color: c.textPrimary)),
                  subtitle: Text('随机起卦后展示各熵源的真实采样值',
                      style:
                          TextStyle(color: c.textSubtitle, fontSize: 12)),
                  value: cfg.showDetails,
                  onChanged: (v) =>
                      ref.read(configProvider.notifier).setShowDetails(v),
                ),
                Divider(color: goldDivider, height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  title: Text('在线大气噪声',
                      style: TextStyle(color: c.textPrimary)),
                  subtitle: Text('联网取 random.org 真随机增强熵源',
                      style:
                          TextStyle(color: c.textSubtitle, fontSize: 12)),
                  value: cfg.useOnline,
                  onChanged: (v) =>
                      ref.read(configProvider.notifier).setUseOnline(v),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // v3.0.0：AI 解卦分区（GLM API key）。
            SectionTitle('◆ AI 解卦', color: c.goldBright),
            const SizedBox(height: 4),
            _card(
              context,
              children: const [_GlmKeyTile()],
            ),
            const SizedBox(height: 20),

            // v2.11.0：数据与重置分区。
            SectionTitle('◆ 数据与重置', color: c.goldBright),
            const SizedBox(height: 4),
            _card(
              context,
              children: [
                _dataTile(
                  context,
                  icon: Icons.cleaning_services_outlined,
                  title: '清除数据',
                  subtitle: '选择要清除的内容（卜算历史 / 使用指引）',
                  onTap: () => _showClearDataDialog(context, ref),
                ),
                Divider(color: goldDivider, height: 1),
                _dataTile(
                  context,
                  icon: Icons.restart_alt,
                  title: '还原初设',
                  subtitle: '将所有设置恢复为默认，保留卜算历史',
                  onTap: () => _showResetSettingsDialog(context, ref),
                ),
                Divider(color: goldDivider, height: 1),
                _dataTile(
                  context,
                  icon: Icons.auto_delete_outlined,
                  title: '归零重始',
                  subtitle: '清除全部数据并恢复所有设置（不可撤销）',
                  titleColor: c.fireGlow,
                  iconColor: c.fireGlow,
                  onTap: () => _showFactoryResetDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '志极 Jeenith · 叩问本心，不忘初心\nCopyright (c) 2026 Qore',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textHint, fontSize: 11, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    final c = AppClr.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: c.resolve(
                const Color.fromRGBO(212, 168, 87, 0.22),
                const Color.fromRGBO(155, 122, 42, 0.28))),
      ),
      child: Column(children: children),
    );
  }

  /// 数据与重置分区的条目（图标 + 标题 + 副标题 + 箭头）。
  Widget _dataTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    final c = AppClr.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: iconColor ?? c.goldBright, size: 22),
      title: Text(title,
          style: TextStyle(
              color: titleColor ?? c.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: TextStyle(color: c.textSubtitle, fontSize: 12, height: 1.4)),
      trailing: Icon(Icons.chevron_right, color: c.textHint, size: 20),
      onTap: onTap,
    );
  }

  /// 单个细分动画开关。
  Widget _kindSwitch(
    BuildContext context,
    AppConfig cfg,
    WidgetRef ref,
    String techId,
    AnimationKind kind,
    String title,
    String subtitle,
  ) {
    final c = AppClr.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title,
          style: TextStyle(color: c.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(color: c.textSubtitle, fontSize: 11)),
      value: cfg.isAnimationEnabled(techId, kind),
      onChanged: (v) => ref
          .read(configProvider.notifier)
          .setAnimationSetting(techId, kind, v),
    );
  }

  /// 「清除数据」：勾选要清除的数据类型（历史 / 引导）后清除并重启。
  Future<void> _showClearDataDialog(BuildContext context, WidgetRef ref) async {
    final c = AppClr.of(context);
    final histCount = await AppData.historyCount();
    final guideCount = await AppData.guideFlagCount();
    if (!context.mounted) return;

    var clearHistory = true;
    var clearGuide = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final any = clearHistory || clearGuide;
            return AlertDialog(
              backgroundColor: c.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: c.goldBorder),
              ),
              title: Row(
                children: [
                  Icon(Icons.cleaning_services_outlined,
                      color: c.goldBright, size: 20),
                  const SizedBox(width: 8),
                  Text('清除数据',
                      style: TextStyle(
                          color: c.goldBright,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('勾选要清除的内容，清除后应用将重启。',
                        style: TextStyle(color: c.textBody, fontSize: 13)),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: c.goldBright,
                      checkColor: Colors.black87,
                      value: clearHistory,
                      onChanged: (v) =>
                          setSt(() => clearHistory = v ?? false),
                      title: Text('卜算历史记录（$histCount 条）',
                          style: TextStyle(
                              color: c.textPrimary, fontSize: 14)),
                      subtitle: Text('清除后无法恢复',
                          style: TextStyle(
                              color: c.textSubtitle, fontSize: 11)),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: c.goldBright,
                      checkColor: Colors.black87,
                      value: clearGuide,
                      onChanged: (v) =>
                          setSt(() => clearGuide = v ?? false),
                      title: Text('使用指引标记（$guideCount 项）',
                          style: TextStyle(
                              color: c.textPrimary, fontSize: 14)),
                      subtitle: Text('清除后相关引导将重新弹出',
                          style: TextStyle(
                              color: c.textSubtitle, fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    Text('设置（主题 / 动画 / 随机）不受影响。',
                        style: TextStyle(color: c.textSubtitle, fontSize: 11)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('取消',
                      style: TextStyle(color: c.textSubtitle)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        any ? c.gold : c.textHint,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: any
                      ? () async {
                          Navigator.pop(ctx);
                          if (clearHistory) await AppData.clearHistory();
                          if (clearGuide) await AppData.clearGuideFlags();
                          RestartController.instance.restart();
                        }
                      : null,
                  child: const Text('清除并重启'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 「还原初设」：把所有设置恢复为默认，保留数据，然后重启。
  Future<void> _showResetSettingsDialog(
      BuildContext context, WidgetRef ref) async {
    final c = AppClr.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.goldBorder),
        ),
        title: Row(
          children: [
            Icon(Icons.restart_alt, color: c.goldBright, size: 20),
            const SizedBox(width: 8),
            Text('还原初设',
                style: TextStyle(
                    color: c.goldBright,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ],
        ),
        content: Text(
          '将把主题、动画/动效、随机与展示等所有设置恢复为默认值。\n\n卜算历史与使用指引不受影响。完成后应用将重启。',
          style: TextStyle(color: c.textBody, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: c.textSubtitle)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.gold,
              foregroundColor: Colors.black87,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('还原并重启'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(configProvider.notifier).resetSettings();
    RestartController.instance.restart();
  }

  /// 「归零重始」：清除全部数据 + 恢复所有设置（最彻底，不可撤销），然后重启。
  Future<void> _showFactoryResetDialog(
      BuildContext context, WidgetRef ref) async {
    final c = AppClr.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.fireGlow.withValues(alpha: 0.5)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: c.fireGlow, size: 22),
            const SizedBox(width: 8),
            Text('归零重始',
                style: TextStyle(
                    color: c.fireGlow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ],
        ),
        content: Text(
          '此操作将清除全部数据（卜算历史 + 使用指引），并把所有设置恢复为默认。\n\n该操作不可撤销，完成后应用将重启。',
          style: TextStyle(color: c.textBody, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: c.textSubtitle)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.fireGlow,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认归零'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppData.clearAllData();
    await ref.read(configProvider.notifier).resetSettings();
    RestartController.instance.restart();
  }
}

/// GLM API key 输入条（v3.0.0 解卦用）。
class _GlmKeyTile extends ConsumerStatefulWidget {
  const _GlmKeyTile();

  @override
  ConsumerState<_GlmKeyTile> createState() => _GlmKeyTileState();
}

class _GlmKeyTileState extends ConsumerState<_GlmKeyTile> {
  late final TextEditingController _ctrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: ref.read(configProvider).valueOrNull?.glmApiKey ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    final empty = _ctrl.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              Text('GLM API Key', style: TextStyle(color: c.textPrimary)),
              const Spacer(),
              Text(empty ? '未设置' : '已设置',
                  style: TextStyle(
                      color: empty ? c.textHint : c.goldBright,
                      fontSize: 11)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            children: [
              TextField(
                controller: _ctrl,
                obscureText: _obscure,
                style: TextStyle(color: c.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '粘贴智谱 API key',
                  hintStyle: TextStyle(color: c.textHint, fontSize: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: c.textSubtitle),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.goldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: c.goldBright, width: 1.2)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        '用于「解卦」页 AI 解读。智谱 GLM-4-Flash 免费，到 open.bigmodel.cn 申请。',
                        style: TextStyle(color: c.textHint, fontSize: 10, height: 1.4)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: empty
                        ? null
                        : () {
                            ref
                                .read(configProvider.notifier)
                                .setGlmApiKey(_ctrl.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('GLM API key 已保存'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2)));
                          },
                    style: FilledButton.styleFrom(
                        backgroundColor: c.gold,
                        foregroundColor: Colors.black87),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
