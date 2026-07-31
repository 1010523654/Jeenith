// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animation/reveal/reveal_animation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/calendar/birth_validate.dart';
import '../../../core/history/history_store.dart';
import '../../../core/history/history_providers.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/copy_result_button.dart';
import '../../../shared/widgets/share_result_button.dart';
import '../../../shared/widgets/gold_button.dart';
import '../algorithm/divine.dart';
import '../data/chenggu_data.dart';

class ChengguPage extends ConsumerStatefulWidget {
  const ChengguPage({super.key});
  @override
  ConsumerState<ChengguPage> createState() => _ChengguPageState();
}

class _ChengguPageState extends ConsumerState<ChengguPage> {
  final _year = TextEditingController();
  final _month = TextEditingController();
  final _day = TextEditingController();
  final _hour = TextEditingController();
  bool _isMale = true;
  ChengguResult? _r;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestore());
  }

  /// v2.6.0：从历史记录恢复，按 extra 重建生辰 + 性别 + 称骨。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'chenggu') return;
    final extra = restore.extra;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (extra == null) return;
    final y = extra['year'] as int?;
    final m = extra['month'] as int?;
    final d = extra['day'] as int?;
    final h = extra['hour'] as int?;
    if (y == null || m == null || d == null || h == null || h < 0 || h > 23) return;
    final male = extra['isMale'] as bool? ?? true;
    setState(() {
      _isMale = male;
      _year.text = y.toString();
      _month.text = m.toString();
      _day.text = d.toString();
      _hour.text = h.toString();
      _r = divine(y, m, d, h);
    });
  }

  @override
  void dispose() {
    for (final c in [_year, _month, _day, _hour]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onDivine() {
    final y = int.tryParse(_year.text) ?? 0;
    final m = int.tryParse(_month.text) ?? 0;
    final d = int.tryParse(_day.text) ?? 0;
    final h = int.tryParse(_hour.text) ?? -1;
    final berr = validateBirth(y, m, d, h);
    if (berr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(berr), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _r = divine(y, m, d, h));
    FocusScope.of(context).unfocus();
    unawaited(HistoryStore.add(HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'chenggu',
      techName: '称骨算命',
      time: DateTime.now(),
      summary: _r == null ? '' : _r!.weightLabel,
      detail: _buildCopyText(),
      extra: {'year': y, 'month': m, 'day': d, 'hour': h, 'isMale': _isMale},
    )));
  }

  /// v2.4.0: 一键填充当前公历时辰。
  void _fillNow() {
    final now = DateTime.now();
    setState(() {
      _year.text = now.year.toString();
      _month.text = now.month.toString();
      _day.text = now.day.toString();
      _hour.text = now.hour.toString();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          children: [
            const Text('称骨算命', style: TextStyle(fontSize: 18)),
            Text('袁 天 罡 称 骨',
                style: TextStyle(
                    fontSize: 10, color: c.textSubtitle, letterSpacing: 4)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          DecorativePanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('公历生辰（年 月 日 时 0-23）',
                    style: TextStyle(color: c.textBody, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _f(_year, '年')),
                    const SizedBox(width: 6),
                    Expanded(child: _f(_month, '月')),
                    const SizedBox(width: 6),
                    Expanded(child: _f(_day, '日')),
                    const SizedBox(width: 6),
                    Expanded(child: _f(_hour, '时')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('性别',
                        style: TextStyle(color: c.textBody, fontSize: 12)),
                    const SizedBox(width: 10),
                    _genderChip('男', true),
                    const SizedBox(width: 6),
                    _genderChip('女', false),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _fillNow,
                    icon: const Icon(Icons.access_time, size: 16),
                    label: const Text('获取当前时间',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: c.goldBright,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GoldButton(text: '称骨', onPressed: _onDivine),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CopyResultButton(text: _buildCopyText(), enabled: _r != null),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShareResultButton(
                        boundaryKey: _boundaryKey,
                        enabled: _r != null,
                        fallbackText: _buildCopyText(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_r != null)
            RepaintBoundary(key: _boundaryKey, child: _buildResult(_r!)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String hint) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: hint, isDense: true),
      );

  Widget _genderChip(String label, bool male) {
    final c = AppClr.of(context);
    final selected = _isMale == male;
    return GestureDetector(
      onTap: () => setState(() => _isMale = male),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.gold.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? c.gold : c.goldBorder),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? c.goldBright : c.textBody,
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildResult(ChengguResult r) {
    final c = AppClr.of(context);
    final enabled = ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('chenggu', AnimationKind.reveal) ??
        true;
    return RevealAnimation(
      enabled: enabled,
      replayKey: r,
      hero: DecorativePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.lunarDisplay,
                style: TextStyle(
                    color: c.goldBright,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('八字：${r.bazi}',
                style: TextStyle(color: c.textBody, fontSize: 13)),
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Text(r.weightLabel,
                      style: TextStyle(
                          color: c.gold,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.fire.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: c.fireGlow),
                    ),
                    child: Text(r.fate.title,
                        style: TextStyle(
                            color: c.fireGlow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      sections: [
        Text('◆ 四骨重量',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        _buildWeightBreakdown(r),
        Text('◆ 称骨歌',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        DecorativePanel(
          padding: const EdgeInsets.all(12),
          child: Text(r.fate.poem,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.goldBright,
                  fontSize: 15,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1)),
        ),
        Text('◆ ${_isMale ? "男" : "女"}命详解',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        DecorativePanel(
          padding: const EdgeInsets.all(12),
          child: Text(
            _isMale ? r.fate.male : r.fate.female,
            style: TextStyle(color: c.textBody, fontSize: 13, height: 1.7),
          ),
        ),
      ],
    );
  }

  /// 四骨重明细：年（甲子 一两二钱）/ 月 / 日 / 时。
  Widget _buildWeightBreakdown(ChengguResult r) {
    final c = AppClr.of(context);
    // 从八字提取年柱用于显示
    final yearGz = r.bazi.split(' ').first;
    final rows = <(String, String, int)>[
      ('年', '$yearGz · ${chengguWeightLabel(r.yearQian)}', r.yearQian),
      ('月', chengguWeightLabel(r.monthQian), r.monthQian),
      ('日', chengguWeightLabel(r.dayQian), r.dayQian),
      ('时', chengguWeightLabel(r.hourQian), r.hourQian),
    ];
    return DecorativePanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (final (label, desc, qian) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(label,
                        style: TextStyle(
                            color: c.textMeta,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(desc,
                        style: TextStyle(color: c.textPrimary, fontSize: 13)),
                  ),
                  Text(chengguWeightDecimal(qian).split('（').first,
                      style: TextStyle(color: c.fireGlow, fontSize: 12)),
                ],
              ),
            ),
          Divider(height: 12, color: c.goldBorder),
          Row(
            children: [
              Text('总骨重',
                  style: TextStyle(
                      color: c.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(chengguWeightDecimal(r.totalQian),
                  style: TextStyle(
                      color: c.goldBright,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  /// 生成详细结果文本（供复制）。
  String _buildCopyText() {
    final r = _r;
    if (r == null) return '';
    final yearGz = r.bazi.split(' ').first;
    final sb = StringBuffer('【称骨算命 · 袁天罡称骨】\n');
    sb.writeln('时间：${DateTime.now().toString().substring(0, 19)}');
    sb.writeln(r.lunarDisplay);
    sb.writeln('八字：${r.bazi}');
    sb.writeln('\n—— 四骨重量 ——');
    sb.writeln('年（$yearGz）：${chengguWeightDecimal(r.yearQian)}');
    sb.writeln('月：${chengguWeightDecimal(r.monthQian)}');
    sb.writeln('日：${chengguWeightDecimal(r.dayQian)}');
    sb.writeln('时：${chengguWeightDecimal(r.hourQian)}');
    sb.writeln('\n总骨重：${chengguWeightDecimal(r.totalQian)}');
    sb.writeln('命格：${r.fate.title}');
    sb.writeln('\n—— 称骨歌 ——');
    sb.writeln(r.fate.poem);
    sb.writeln('\n—— 男命 ——');
    sb.writeln(r.fate.male);
    sb.writeln('\n—— 女命 ——');
    sb.writeln(r.fate.female);
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }
}
