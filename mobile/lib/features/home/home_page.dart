// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/branding.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/divination/divination_registry.dart';
import '../../shared/widgets/animated_expand_icon.dart';
import '../../shared/widgets/entrance_item.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/hoverable_icon_button.dart';
import '../../shared/widgets/interactable_card.dart';
import '../../shared/widgets/svg_icon.dart';

/// 首页：选术卡片 grid。读 [visibleTechsProvider]，新术自动出现。
///
/// v2.4.2：全面主题感知（浅色模式适配 + 深浅渐变切换）。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _exit;
  bool _exiting = false;
  bool _guideExpanded = false; // 首页「使用方法」默认折叠（v2.5.0 用户偏好）
  final _guideController = ExpansibleController();

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowGuide());
  }

  Future<void> _maybeShowGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('hasSeenGuide') ?? false) return;
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const GuideDialog(),
    );
    if (!mounted) return;
    await prefs.setBool('hasSeenGuide', true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _exit.dispose();
    super.dispose();
  }

  static const _ritualTechs = {
    'xiaoliuren',
    'zhouyi',
    'ziwei',
    'qimen',
    'daliuren',
    'luopan',
    'meihua',
    'jiaobei',
    'chouqian',
    'cezi',
    'bazi',
    'name_test',
    'liuyao',
    'chenggu',
    'taiyi',
  };

  void _onTapTech(String id) {
    if (_exiting) return;
    final cfg = ref.read(configProvider).valueOrNull;
    final ritualOn =
        cfg?.isAnimationEnabled(id, AnimationKind.entrance) ?? true;
    final hasRitual = _ritualTechs.contains(id);
    final target = (ritualOn && hasRitual) ? '/ritual/$id' : '/tech/$id';
    _startExit(() => context.go(target));
  }

  void _startExit(void Function() then) {
    if (_exiting) return;
    _exiting = true;
    _exit.forward().then((_) {
      if (mounted) then();
    });
  }

  /// 首页置顶的「使用方法」卡片（可展开，默认折叠）。
  Widget _guideCard() {
    final c = AppClr.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: c.resolve(
                const Color.fromRGBO(212, 168, 87, 0.30),
                const Color.fromRGBO(155, 122, 42, 0.35))),
      ),
      child: ExpansionTile(
        controller: _guideController,
        initiallyExpanded: _guideExpanded,
        onExpansionChanged: (v) => setState(() => _guideExpanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconColor: c.gold,
        collapsedIconColor: c.textSubtitle,
        dense: true,
        trailing: AnimatedExpandIcon(
          expanded: _guideExpanded,
          color: _guideExpanded ? c.gold : c.textSubtitle,
          size: 22,
          onPressed: () {
            if (_guideExpanded) {
              _guideController.collapse();
            } else {
              _guideController.expand();
            }
          },
        ),
        title: Row(
          children: [
            Icon(Icons.menu_book, color: c.goldBright, size: 18),
            const SizedBox(width: 6),
            Text(
              '使用方法',
              style: TextStyle(
                color: c.goldBright,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 单一卜算术起卦',
                    style: TextStyle(
                        color: c.goldBright,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text('第一次问大致的问题，第二次问细致的问题。',
                    style:
                        TextStyle(color: c.textBody, fontSize: 12, height: 1.5)),
                const SizedBox(height: 8),
                Text('2. 多卜算术组合使用',
                    style: TextStyle(
                        color: c.goldBright,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text('先用一种卜算术起卦问大致的问题，再用另外一种起卦问细节上的问题。',
                    style:
                        TextStyle(color: c.textBody, fontSize: 12, height: 1.5)),
                const SizedBox(height: 8),
                Text(
                    '3. 可以将卦象的完整截图和问题一并发送给 AI，也可以自己查资料。',
                    style:
                        TextStyle(color: c.textBody, fontSize: 12, height: 1.5)),
                const SizedBox(height: 6),
                Text(
                    '4. 点击起卦按钮前，心里默念问题，集中注意力，注意力达到顶点的一刹那起卦。',
                    style:
                        TextStyle(color: c.textBody, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final techs = ref.watch(visibleTechsProvider);
    final c = AppClr.of(context);
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _exit,
          builder: (context, child) => Opacity(
            opacity: 1 - _exit.value,
            child: Transform.translate(
              offset: Offset(0, -36 * _exit.value),
              child: child,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 44),
                  EntranceItem(
                    animation: _entrance,
                    interval: const Interval(0.0, 0.30),
                    slide: 18,
                    child: Text(
                      Branding.appName,
                      style: TextStyle(
                        color: c.goldBright,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  EntranceItem(
                    animation: _entrance,
                    interval: const Interval(0.12, 0.40),
                    slide: 14,
                    child: Text(
                      Branding.tagline,
                      style: TextStyle(
                        color: c.textSubtitle,
                        fontSize: 12,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  EntranceItem(
                    animation: _entrance,
                    interval: const Interval(0.20, 0.50),
                    child: _guideCard(),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.86,
                      children: [
                        for (var i = 0; i < techs.length; i++)
                          Builder(
                            builder: (context) {
                              final meta = techs[i].meta;
                              return InteractableCard(
                                entrance: _entrance,
                                interval: Interval(
                                  // v2.10.2：begin 必须 clamp，否则 i>=10 时
                                  // 0.28+i*0.08 > 1.0 触发 Interval 断言崩溃。
                                  // clamp 上限 0.92 确保与 end(≤1.0) 至少差 0.08。
                                  (0.28 + i * 0.08).clamp(0.0, 0.92).toDouble(),
                                  (0.62 + i * 0.08).clamp(0.0, 1.0).toDouble(),
                                ),
                                color: meta.accentColor,
                                onTap: () => _onTapTech(meta.id),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: meta.accentColor.withValues(
                                          alpha: 0.28,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: meta.accentColor,
                                        size: 22,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      meta.displayName,
                                      style: TextStyle(
                                        color: meta.accentColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      meta.subtitle,
                                      style: TextStyle(
                                        color: c.textSubtitle,
                                        fontSize: 11,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Flexible(
                                      child: Text(
                                        meta.description,
                                        style: TextStyle(
                                          color: c.textBody,
                                          fontSize: 11,
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 6,
                left: 6,
                child: HoverableIconButton(
                  icon: const Icon(Icons.history),
                  tooltip: '历史记录',
                  onPressed: () => _startExit(() => context.go('/history')),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HoverableIconButton(
                      icon: const SvgIcon('manual'),
                      tooltip: '使用手册',
                      onPressed: () => _startExit(() => context.go('/manual')),
                    ),
                    const SizedBox(width: 8),
                    HoverableIconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: '设置',
                      onPressed: () =>
                          _startExit(() => context.go('/settings')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
