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
import '../../../shared/widgets/tech_guide_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/copy_result_button.dart';
import '../../../shared/widgets/share_result_button.dart';
import '../../../shared/widgets/gold_button.dart';
import '../algorithm/divine.dart';
import '../algorithm/geju.dart';
import '../data/taiyi_data.dart';

/// 5×5 太乙盘布局：每格存十六间辰索引（-1 空 / -2 中宫）。
/// 外圈顺时针：巽 巳 午 未 坤 申 酉 戌 乾 亥 子 丑 艮 寅 卯 辰。
const _layout = <int>[
  8, 9, 10, 11, 12,
  7, -1, -1, -1, 13,
  6, -1, -2, -1, 14,
  5, -1, -1, -1, 15,
  4, 3, 2, 1, 0,
];

class TaiyiPage extends ConsumerStatefulWidget {
  const TaiyiPage({super.key});
  @override
  ConsumerState<TaiyiPage> createState() => _TaiyiPageState();
}

class _TaiyiPageState extends ConsumerState<TaiyiPage> {
  final _year = TextEditingController();
  final _month = TextEditingController();
  final _day = TextEditingController();
  final _hour = TextEditingController();
  TaiyiResult? _r;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestore();
      _maybeShowTechGuide();
    });
  }

  /// v2.7.0：首次进入太乙神数显示使用指引。
  Future<void> _maybeShowTechGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('tech_guide_taiyi') ?? false) return;
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TechGuideOverlay(
        title: '太乙神数 · 使用指引',
        steps: [
          GuideStep('排盘输入', '输入公历年月日时（0-23），点「排盘」以太乙积年推演年家盘。'),
          GuideStep('十六间辰盘', '5×5 盘面：外圈十六间辰各配一神与宫数，太乙/文昌/始击/主客将落位高亮。'),
          GuideStep('主客断法', '太乙为主、文昌始击定主客算，主客大将参将定胜负；迫/格/杜塞/囚/关为吉凶格局。'),
          GuideStep('历法', '冬至后阳遁、夏至后阴遁；太乙三年一宫、24 年一周、不入中五。'),
        ],
      ),
    );
    if (!mounted) return;
    await prefs.setBool('tech_guide_taiyi', true);
  }

  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'taiyi') return;
    final extra = restore.extra;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (extra == null) return;
    final y = extra['year'] as int?;
    final m = extra['month'] as int?;
    final d = extra['day'] as int?;
    final h = extra['hour'] as int?;
    if (y == null || m == null || d == null || h == null || h < 0 || h > 23) return;
    setState(() {
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
      techId: 'taiyi',
      techName: '太乙神数',
      time: DateTime.now(),
      summary: _r == null ? '' : '${_r!.isYang ? "阳" : "阴"}遁${_r!.ju}局·太乙${_r!.taiyiGong}宫',
      detail: _buildCopyText(),
      extra: {'year': y, 'month': m, 'day': d, 'hour': h},
    )));
  }

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
            const Text('太乙神数', style: TextStyle(fontSize: 18)),
            Text('三 式 之 首',
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
                Text('公历时辰（年 月 日 时 0-23）',
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
                GoldButton(text: '排盘', onPressed: _onDivine),
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

  Widget _buildResult(TaiyiResult r) {
    final c = AppClr.of(context);
    final enabled = ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('taiyi', AnimationKind.reveal) ??
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
            const SizedBox(height: 4),
            Text('太乙积年：${r.jinian}',
                style: TextStyle(color: c.textMeta, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(r.isYang ? '阳遁' : '阴遁',
                    style: TextStyle(
                        color: r.isYang ? c.gold : c.waterDeepGlow,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4)),
                const SizedBox(width: 16),
                Text('第 ${r.ju} 局',
                    style: TextStyle(
                        color: c.fireGlow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('太乙·${taiyiJianchen[r.taiyiJc]}${r.taiyiGong}宫',
                    style: TextStyle(
                        color: c.gold, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      sections: [
        Text('◆ 太乙十六间辰盘',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        DecorativePanel(
          padding: const EdgeInsets.all(6),
          child: _buildPlate(r),
        ),
        Text('◆ 主客神将',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        _buildGeneralsTable(r),
        Text('◆ 格局断辞',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        _buildGejuPanel(r),
      ],
    );
  }

  /// 5×5 太乙盘：每格显示间辰名/神名/宫数 + 角色标记。
  Widget _buildPlate(TaiyiResult r) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5,
      crossAxisSpacing: 3,
      mainAxisSpacing: 3,
      childAspectRatio: 0.82,
      children: [for (var pos = 0; pos < 25; pos++) _buildCell(pos, r)],
    );
  }

  Widget _buildCell(int pos, TaiyiResult r) {
    final c = AppClr.of(context);
    final jc = _layout[pos];

    if (jc == -1) {
      // 空格（盘内四角空白）
      return Container(decoration: BoxDecoration(color: c.bgInner.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)));
    }
    if (jc == -2) {
      // 中宫
      final roles = _rolesOfCenter(r);
      return Container(
        decoration: BoxDecoration(
          color: c.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.gold, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('中5', style: TextStyle(color: c.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            if (roles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(roles.join('\n'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.fireGlow, fontSize: 8, height: 1.2)),
              ),
          ],
        ),
      );
    }

    final gong = taiyiGongOfJianchen[jc];
    final roles = _rolesOf(jc, r);
    final isTaiyi = jc == r.taiyiJc;
    final border = isTaiyi
        ? c.gold
        : (roles.isNotEmpty ? c.goldBorder : c.goldBorder);
    final bg = isTaiyi
        ? c.gold.withValues(alpha: 0.18)
        : (roles.isNotEmpty ? c.card.withValues(alpha: 0.6) : c.card);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
            color: border, width: isTaiyi ? 1.6 : (roles.isNotEmpty ? 1.0 : 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 顶：宫数
          Text('$gong',
              style: TextStyle(
                  color: isTaiyi ? c.goldBright : c.textMeta,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          // 中：间辰 + 神名
          Column(
            children: [
              Text(taiyiJianchen[jc],
                  style: TextStyle(
                      color: isTaiyi ? c.gold : c.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Text(taiyiShishen[jc],
                  style: TextStyle(color: c.textSubtitle, fontSize: 8, height: 1.1)),
            ],
          ),
          // 底：角色标记
          if (roles.isNotEmpty)
            Text(roles.join(' '),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.fireGlow, fontSize: 8, height: 1.1)),
        ],
      ),
    );
  }

  /// 间辰角色（太乙/文昌/始击/计神/主客将）。
  List<String> _rolesOf(int jc, TaiyiResult r) {
    final out = <String>[];
    if (jc == r.taiyiJc) out.add('太乙');
    if (jc == r.wenchangJc) out.add('文昌');
    if (jc == r.shijiJc) out.add('始击');
    if (jc == r.jishenJc) out.add('计神');
    if (jc == r.gongToJc(r.mainDajiang)) out.add('主大');
    if (jc == r.gongToJc(r.mainCanjiang)) out.add('主参');
    if (jc == r.gongToJc(r.guestDajiang)) out.add('客大');
    if (jc == r.gongToJc(r.guestCanjiang)) out.add('客参');
    return out;
  }

  /// 中宫角色（落中5的将）。
  List<String> _rolesOfCenter(TaiyiResult r) {
    final out = <String>[];
    if (r.mainDajiang == 5) out.add('主大');
    if (r.mainCanjiang == 5) out.add('主参');
    if (r.guestDajiang == 5) out.add('客大');
    if (r.guestCanjiang == 5) out.add('客参');
    return out;
  }

  /// 主客神将详表。
  Widget _buildGeneralsTable(TaiyiResult r) {
    final c = AppClr.of(context);
    final rows = <(String, int, int)>[
      ('文昌（天目）', r.wenchangJc, taiyiGongOfJianchen[r.wenchangJc]),
      ('始击（地目）', r.shijiJc, taiyiGongOfJianchen[r.shijiJc]),
      ('计神', r.jishenJc, taiyiGongOfJianchen[r.jishenJc]),
    ];
    final generals = <(String, int)>[
      ('主算', r.mainSuan),
      ('主大将', r.mainDajiang),
      ('主参将', r.mainCanjiang),
      ('客算', r.guestSuan),
      ('客大将', r.guestDajiang),
      ('客参将', r.guestCanjiang),
    ];
    return DecorativePanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, jc, gong) in rows)
            _kv(name, '${taiyiJianchen[jc]}${taiyiShishen[jc]} · $gong宫', c),
          const Divider(height: 12),
          for (final (name, val) in generals)
            _kv(name, name.contains('算') ? '$val' : '$val宫', c),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, AppClr c) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
                width: 72,
                child: Text(k,
                    style: TextStyle(color: c.textMeta, fontSize: 12))),
            Expanded(
                child: Text(v,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold))),
          ],
        ),
      );

  /// 格局断辞面板。
  Widget _buildGejuPanel(TaiyiResult r) {
    final c = AppClr.of(context);
    final gejus = identifyGeju(r);
    return DecorativePanel(
      padding: const EdgeInsets.all(10),
      child: gejus.isEmpty
          ? Text('本盘无显著成格，太乙文昌始击各安其位，主客从容。',
              style: TextStyle(color: c.woodGlow, fontSize: 11, height: 1.5))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final g in gejus)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.fireGlow.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: c.fireGlow),
                          ),
                          child: Text('忌',
                              style: TextStyle(
                                  color: c.fireGlow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name,
                                  style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(g.text,
                                  style: TextStyle(
                                      color: c.textBody,
                                      fontSize: 11,
                                      height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  String _buildCopyText() {
    final r = _r;
    if (r == null) return '';
    final sb = StringBuffer('【太乙神数 · 三式之年家太乙】\n');
    sb.writeln('时间：${DateTime.now().toString().substring(0, 19)}');
    sb.writeln(r.lunarDisplay);
    sb.writeln('八字：${r.bazi}');
    sb.writeln('太乙积年：${r.jinian}');
    sb.writeln('遁型：${r.isYang ? "阳遁" : "阴遁"}  局数：第 ${r.ju} 局');
    sb.writeln('太乙：${taiyiJianchen[r.taiyiJc]}${taiyiShishen[r.taiyiJc]}（${r.taiyiGong}宫）');
    sb.writeln('\n—— 主客神将 ——');
    sb.writeln('文昌（天目）：${taiyiJianchen[r.wenchangJc]}${taiyiShishen[r.wenchangJc]}（${taiyiGongOfJianchen[r.wenchangJc]}宫）');
    sb.writeln('始击（地目）：${taiyiJianchen[r.shijiJc]}${taiyiShishen[r.shijiJc]}（${taiyiGongOfJianchen[r.shijiJc]}宫）');
    sb.writeln('计神：${taiyiJianchen[r.jishenJc]}${taiyiShishen[r.jishenJc]}（${taiyiGongOfJianchen[r.jishenJc]}宫）');
    sb.writeln('主算：${r.mainSuan}  主大将：${r.mainDajiang}宫  主参将：${r.mainCanjiang}宫');
    sb.writeln('客算：${r.guestSuan}  客大将：${r.guestDajiang}宫  客参将：${r.guestCanjiang}宫');
    final gejus = identifyGeju(r);
    if (gejus.isNotEmpty) {
      sb.writeln('\n—— 格局 ——');
      for (final g in gejus) {
        sb.writeln('${g.name}：${g.text}');
      }
    }
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }
}
