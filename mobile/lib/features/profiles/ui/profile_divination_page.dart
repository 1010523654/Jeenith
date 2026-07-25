// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lunar/lunar.dart';

import '../../../core/profiles/profile_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/divination_loading_indicator.dart';
import '../../ziwei/algorithm/divine.dart';
import '../../ziwei/data/stars.dart';
import '../../chenggu/algorithm/divine.dart' as chenggu;

/// 全方位卜算页（v3.0.0）：对单档案一次性推演紫微 + 八字 + 称骨，融合展示。
///
/// 缺时辰（hour == null）时三术均不可用，降级提示并引导返回档案补全。
class ProfileDivinationPage extends ConsumerStatefulWidget {
  final String profileId;
  const ProfileDivinationPage({super.key, required this.profileId});

  @override
  ConsumerState<ProfileDivinationPage> createState() =>
      _ProfileDivinationPageState();
}

class _ProfileDivinationPageState
    extends ConsumerState<ProfileDivinationPage> {
  Profile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ProfileStore.load();
    final p = list.where((e) => e.id == widget.profileId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profiles')),
        title: const Text('全方位卜算'),
      ),
      body: _loading
          ? const Center(child: DivinationLoadingIndicator(size: 48))
          : _profile == null
              ? Center(
                  child: Text('档案不存在',
                      style: TextStyle(color: c.textHint)))
              : _profile!.hasHour
                  ? _fullResult(c, _profile!)
                  : _missingHour(c, _profile!),
    );
  }

  /// 缺时辰降级：三术不可用 + 返回补全。
  Widget _missingHour(AppClr c, Profile p) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, color: c.fireGlow, size: 48),
              const SizedBox(height: 12),
              Text('「${p.name}」时辰未知',
                  style: TextStyle(
                      color: c.fireGlow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  '紫微斗数、八字推演、称骨算命 均需时辰方可推演。\n请返回档案补全时辰后再卜算。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textBody, fontSize: 13, height: 1.6)),
              const SizedBox(height: 20),
              GoldButton(
                  text: '返回档案补全',
                  onPressed: () => context.go('/profiles')),
            ],
          ),
        ),
      );

  /// 完整时辰：紫微 + 八字 + 称骨 三术融合。
  Widget _fullResult(AppClr c, Profile p) {
    const dz = [
      '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'
    ];
    final zr = divine(p.year, p.month, p.day, p.hour!, isMale: p.isMale);
    final cr = chenggu.divine(p.year, p.month, p.day, p.hour!);
    final ec = Solar.fromYmdHms(p.year, p.month, p.day, p.hour!, 0, 0)
        .getLunar()
        .getEightChar();

    final mingMain = zr.stars.gongStars[zr.mingGong]
        .where((s) => s.category == StarCategory.main)
        .map((s) => s.name + (s.sihua != null ? '·${s.sihua!.label}' : ''))
        .join('、');
    final fateText = p.isMale ? cr.fate.male : cr.fate.female;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        DecorativePanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(p.isMale ? Icons.male : Icons.female, color: c.goldBright),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: TextStyle(
                            color: c.goldBright,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('${p.birthDisplay} · ${p.isMale ? "男" : "女"}',
                        style: TextStyle(color: c.textBody, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _title(c, '◆ 紫微斗数'),
        _card(c, [
          _row(c, '命宫', '${zr.mingGanZhi}（${dz[zr.mingGong]}）'),
          _row(c, '五行局', zr.wuxingJu),
          _row(c, '命宫主星', mingMain.isEmpty ? '无主星（借对宫）' : mingMain),
        ]),
        const SizedBox(height: 14),
        _title(c, '◆ 八字推演'),
        _card(c, [
          _row(c, '年柱', ec.getYear()),
          _row(c, '月柱', ec.getMonth()),
          _row(c, '日柱', ec.getDay()),
          _row(c, '时柱', ec.getTime()),
        ]),
        const SizedBox(height: 14),
        _title(c, '◆ 称骨算命'),
        _card(c, [
          _row(c, '总骨重', cr.weightLabel),
          _row(c, '命格', cr.fate.title),
          const SizedBox(height: 8),
          Text(cr.fate.poem,
              style: TextStyle(color: c.gold, fontSize: 12, height: 1.7)),
          const SizedBox(height: 6),
          Text(fateText,
              style: TextStyle(color: c.textBody, fontSize: 12, height: 1.6)),
        ]),
      ],
    );
  }

  Widget _title(AppClr c, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      );

  Widget _card(AppClr c, List<Widget> children) => DecorativePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _row(AppClr c, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 72,
                child: Text(label,
                    style: TextStyle(color: c.textSubtitle, fontSize: 12))),
            Expanded(
                child: Text(value,
                    style: TextStyle(color: c.textPrimary, fontSize: 13))),
          ],
        ),
      );
}
