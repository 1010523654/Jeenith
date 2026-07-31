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

/// 洛书九宫在 3×3 网格中的展示顺序（行优先：上→中→下）。
/// 4巽 9离 2坤 / 3震 5中 7兑 / 8艮 1坎 6乾
const _luoshuDisplay = [4, 9, 2, 3, 5, 7, 8, 1, 6];

class QimenPage extends ConsumerStatefulWidget {
  const QimenPage({super.key});
  @override
  ConsumerState<QimenPage> createState() => _QimenPageState();
}

class _QimenPageState extends ConsumerState<QimenPage> {
  final _year = TextEditingController();
  final _month = TextEditingController();
  final _day = TextEditingController();
  final _hour = TextEditingController();
  QimenResult? _r;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestore();
      _maybeShowTechGuide();
    });
  }

  /// v2.4.4：首次进入奇门遁甲时显示使用指引（SharedPreferences 控制只弹一次）。
  Future<void> _maybeShowTechGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('tech_guide_qimen') ?? false) return;
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TechGuideOverlay(
        title: '奇门遁甲 · 使用指引',
        steps: [
          GuideStep('排盘输入', '输入公历年月日时（0-23），点「排盘」按节气定阴阳遁与局数。'),
          GuideStep('四盘九宫', '九宫叠加天盘九星 / 地盘九干 / 人盘八门 / 神盘八神；值符值使宫位高亮。'),
          GuideStep('历法', '奇门用节气干支历（立春换年），与农历无关。'),
        ],
      ),
    );
    if (!mounted) return;
    await prefs.setBool('tech_guide_qimen', true);
  }

  /// v2.4.3：从历史记录恢复，按 extra 重建时辰 + 排盘。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'qimen') return;
    final extra = restore.extra;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (extra == null) return;
    final y = extra['year'] as int?;
    final m = extra['month'] as int?;
    final d = extra['day'] as int?;
    final h = extra['hour'] as int?;
    if (y == null || m == null || d == null || h == null || h < 0 || h > 23) {
      return;
    }
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
      techId: 'qimen',
      techName: '奇门遁甲',
      time: DateTime.now(),
      summary: _r == null ? '' : '${_r!.dunType}第${_r!.ju}局',
      detail: _buildCopyText(),
      extra: {'year': y, 'month': m, 'day': d, 'hour': h},
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
            const Text('奇门遁甲', style: TextStyle(fontSize: 18)),
            Text('时 家 奇 门',
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
                // v2.4.0: 一键获取当前时间
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

  /// 生成详细结果文本（供复制）。
  String _buildCopyText() {
    final r = _r;
    if (r == null) return '';
    final p = r.plate;
    final sb = StringBuffer('【奇门遁甲 · 时家奇门 v2 四盘】\n');
    sb.writeln('时间：${DateTime.now().toString().substring(0, 19)}');
    sb.writeln(p.lunarDisplay);
    sb.writeln('八字：${p.bazi}');
    sb.writeln('节气：${p.jieqi}');
    sb.writeln('遁型：${p.dunType}  局数：第 ${p.ju} 局');
    sb.writeln('值符：${p.zhiFu}（第${p.zhiFuGong}宫）  值使：${p.zhiShi}（第${p.zhiShiGong}宫）');
    sb.writeln('\n—— 九宫四盘 ——');
    for (var i = 0; i < 9; i++) {
      final palace = _luoshuDisplay[i];
      final name = palaceNames[palace - 1];
      final xing = p.tianPanXing[palace - 1];
      final gan = p.diPanGan[palace - 1];
      final men = p.renPanMen[palace - 1];
      final shen = p.shenPanShen[palace - 1];
      sb.writeln('第$palace宫（$name）：'
          '天盘「$xing」  地盘「$gan」  '
          '${men.isEmpty ? "" : "人盘「$men」  "} '
          '${shen.isEmpty ? "" : "神盘「$shen」"}');
    }
    sb.writeln('\n—— 四盘详表 ——');
    sb.writeln('天盘九星：${p.tianPanXing.asMap().entries.map((e) => "${palaceNames[e.key]}:${e.value}").join("  ")}');
    sb.writeln('天盘九干：${p.tianPanGan.asMap().entries.map((e) => "${palaceNames[e.key]}:${e.value}").join("  ")}');
    sb.writeln('地盘九干：${p.diPanGan.asMap().entries.map((e) => "${palaceNames[e.key]}:${e.value}").join("  ")}');
    sb.writeln('人盘八门：${p.renPanMen.asMap().entries.where((e) => e.value.isNotEmpty).map((e) => "${palaceNames[e.key]}:${e.value}").join("  ")}');
    sb.writeln('神盘八神：${p.shenPanShen.asMap().entries.where((e) => e.value.isNotEmpty).map((e) => "${palaceNames[e.key]}:${e.value}").join("  ")}');
    // 格局断辞
    final gejus = identifyGeju(p);
    if (gejus.isNotEmpty) {
      sb.writeln('\n—— 格局断辞 ——');
      for (final g in gejus) {
        sb.writeln('[${g.auspicious ? "吉" : "凶"}] ${g.name}${g.palace > 0 ? "·${palaceNames[g.palace - 1]}宫" : ""}：${g.text}');
      }
    }
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }

  Widget _buildResult(QimenResult r) {
    final p = r.plate;
    final c = AppClr.of(context);
    final dunColor =
        r.dunType == '阳遁' ? c.gold : c.waterDeepGlow;
    final enabled = ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('qimen', AnimationKind.reveal) ??
        true;
    return RevealAnimation(
      enabled: enabled,
      replayKey: r,
      hero: DecorativePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.lunarDisplay,
                style: TextStyle(
                    color: c.goldBright,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('八字：${p.bazi}',
                style: TextStyle(
                    color: c.textBody, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(r.dunType,
                    style: TextStyle(
                        color: dunColor,
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
                if (p.jieqi.isNotEmpty)
                  Text(p.jieqi,
                      style: TextStyle(
                          color: c.textMeta, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: c.goldBorder, width: 1),
              ),
              child: Row(
                children: [
                  Text('值符',
                      style: TextStyle(
                          color: c.textMeta, fontSize: 11)),
                  const SizedBox(width: 6),
                  Text('${p.zhiFu}·${palaceNames[p.zhiFuGong - 1]}宫',
                      style: TextStyle(
                          color: c.goldBright,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text('值使',
                      style: TextStyle(
                          color: c.textMeta, fontSize: 11)),
                  const SizedBox(width: 6),
                  Text('${p.zhiShi}·${palaceNames[p.zhiShiGong - 1]}宫',
                      style: TextStyle(
                          color: c.woodGlow,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      sections: [
        Text('◆ 局盘九宫（天地人神四盘叠加）',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        DecorativePanel(
          padding: const EdgeInsets.all(8),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 0.78,
            children: [
              for (var i = 0; i < 9; i++)
                _buildPalaceCell(_luoshuDisplay[i], p),
            ],
          ),
        ),
        Text('◆ 格局断辞',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        _buildGejuPanel(p),
        Text('◆ 四盘详表',
            style: TextStyle(
                color: c.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        _buildPanTable('天盘九星', p.tianPanXing, c.goldBright),
        _buildPanTable('天盘九干', p.tianPanGan, c.gold),
        _buildPanTable('地盘九干', p.diPanGan, c.textPrimary),
        _buildPanTable('人盘八门', p.renPanMen, c.woodGlow,
            skipEmpty: true),
        _buildPanTable('神盘八神', p.shenPanShen, c.waterDeepGlow,
            skipEmpty: true),
      ],
    );
  }

  /// 格局断辞面板：吉格（金）/ 凶格（火）分行列出，附落宫与断辞。
  Widget _buildGejuPanel(QimenPlate p) {
    final c = AppClr.of(context);
    final gejus = identifyGeju(p);
    return DecorativePanel(
      padding: const EdgeInsets.all(10),
      child: gejus.isEmpty
          ? Text('本盘无明显成格，以八门九星生克与值符值使论断。',
              style: TextStyle(color: c.textHint, fontSize: 11, height: 1.5))
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
                            color: (g.auspicious ? c.gold : c.fireGlow)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: g.auspicious ? c.gold : c.fireGlow),
                          ),
                          child: Text(g.auspicious ? '吉' : '凶',
                              style: TextStyle(
                                  color: g.auspicious ? c.gold : c.fireGlow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${g.name}${g.palace > 0 ? " · ${palaceNames[g.palace - 1]}宫" : ""}',
                                style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
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

  /// 9 宫格单格：显示天盘星 + 地盘干 + 人盘门 + 神盘神四层叠加。
  Widget _buildPalaceCell(int palace, QimenPlate p) {
    final name = palaceNames[palace - 1];
    final xing = p.tianPanXing[palace - 1];
    final gan = p.diPanGan[palace - 1];
    final men = p.renPanMen[palace - 1];
    final shen = p.shenPanShen[palace - 1];
    final isZhiFu = palace == p.zhiFuGong;
    final isZhiShi = palace == p.zhiShiGong;
    final isCenter = palace == 5;
    final c = AppClr.of(context);

    final border = isZhiFu
        ? c.gold
        : (isZhiShi ? c.woodGlow : c.goldBorder);
    final borderWidth = (isZhiFu || isZhiShi) ? 1.8 : 1.0;
    final bg = isCenter
        ? c.gold.withValues(alpha: 0.10)
        : (isZhiFu
            ? c.gold.withValues(alpha: 0.08)
            : (isZhiShi ? c.wood.withValues(alpha: 0.08) : c.card));

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: borderWidth),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 顶部：宫名 + 标识
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name,
                  style: TextStyle(
                      color: isZhiFu
                          ? c.goldBright
                          : (isZhiShi ? c.woodGlow : c.textMeta),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              if (isZhiFu || isZhiShi)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(isZhiFu ? '符' : '使',
                      style: TextStyle(
                          color: isZhiFu ? c.gold : c.woodGlow,
                          fontSize: 9)),
                ),
            ],
          ),
          Divider(height: 1, color: c.goldBorder),
          // 天盘星
          Text(xing,
              style: TextStyle(color: c.goldBright, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3)),
          // 地盘干
          Text(gan,
              style: TextStyle(color: c.textPrimary, fontSize: 11, height: 1.3)),
          // 人盘门
          if (men.isNotEmpty)
            Text(men,
                style: TextStyle(color: c.woodGlow, fontSize: 10, height: 1.3)),
          // 神盘神
          if (shen.isNotEmpty)
            Text(shen,
                style: TextStyle(color: c.waterDeepGlow, fontSize: 10, height: 1.3)),
        ],
      ),
    );
  }

  /// 单盘详表（横向 9 宫，按洛书顺序）。
  Widget _buildPanTable(String title, List<String> values, Color valueColor,
      {bool skipEmpty = false}) {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: c.gold, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var palace = 1; palace <= 9; palace++)
                if (!skipEmpty || values[palace - 1].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.bgInner.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: c.goldBorder),
                    ),
                    child: Text(
                      '${palaceNames[palace - 1]}:${values[palace - 1]}',
                      style: TextStyle(color: valueColor, fontSize: 11),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
