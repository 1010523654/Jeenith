// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/profiles/profile_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/divination_loading_indicator.dart';
import '../../../shared/widgets/themed_dialog.dart';

/// 12 时辰名（子..亥）与代表小时（偶数，供 divine 时支推算）。
const _zhiNames = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
const _zhiHours = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22];

/// 档案页（v3.1.1 重做：主题化，去除原生 Material）。
class ProfilesPage extends ConsumerStatefulWidget {
  const ProfilesPage({super.key});

  @override
  ConsumerState<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends ConsumerState<ProfilesPage>
    with TickerProviderStateMixin {
  List<Profile> _list = const [];
  bool _loading = true;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _reload();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await ProfileStore.load();
    if (!mounted) return;
    setState(() {
      _list = list;
      _loading = false;
    });
    _entrance.forward(from: 0);
  }

  Future<void> _editProfile({Profile? profile}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProfileEditDialog(profile: profile),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(Profile p) async {
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ThemedDialog(
        title: '删除档案',
        actions: [
          _dialogAction('取消', c.textSubtitle, () => Navigator.of(context).pop(false)),
          _dialogAction('删除', gradeBad, () => Navigator.of(context).pop(true), bold: true),
        ],
        child: Text('确定删除「${p.name}」的档案？此操作不可撤销。',
            style: TextStyle(color: c.textBody, fontSize: 13, height: 1.6)),
      ),
    );
    if (ok == true) {
      await ProfileStore.remove(p.id);
      _reload();
    }
  }

  /// 弹窗内按钮（文字 + 下划线悬停感）。
  Widget _dialogAction(String label, Color color, VoidCallback onTap,
          {bool bold = false}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 2)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            const Text('档　案', style: TextStyle(fontSize: 18)),
            Text('生 辰 档 案',
                style:
                    TextStyle(fontSize: 10, color: c.textSubtitle, letterSpacing: 4)),
          ],
        ),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _editProfile(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, color: c.goldBright, size: 20),
                  const SizedBox(width: 4),
                  Text('新建',
                      style: TextStyle(
                          color: c.goldBright,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: DivinationLoadingIndicator(size: 48))
          : _list.isEmpty
              ? _emptyState(c)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  itemCount: _list.length,
                  itemBuilder: (context, i) {
                    final begin = (i * 0.08).clamp(0.0, 0.6);
                    return _entranceItem(begin, _profileCard(c, _list[i]));
                  },
                ),
    );
  }

  /// 错峰入场（fade + 上滑）。
  Widget _entranceItem(double begin, Widget child) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        final t = Curves.easeOutCubic
            .transform((( _entrance.value - begin) / (1 - begin)).clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - t)), child: child),
        );
      },
    );
  }

  Widget _emptyState(AppClr c) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, color: c.textHint, size: 48),
            const SizedBox(height: 12),
            Text('暂无档案，请新建',
                style: TextStyle(color: c.textHint, fontSize: 14)),
            const SizedBox(height: 16),
            GoldButton(text: '新建档案', onPressed: () => _editProfile()),
          ],
        ),
      );

  Widget _profileCard(AppClr c, Profile p) {
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    final zhiIdx = p.hour == null ? -1 : _zhiHours.indexOf(p.hour!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecorativePanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (p.isMale ? c.gold : c.waterDeepGlow)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: (p.isMale ? c.gold : c.waterDeepGlow)
                            .withValues(alpha: 0.5)),
                  ),
                  child: Icon(p.isMale ? Icons.male : Icons.female,
                      color: p.isMale ? c.goldBright : c.waterDeepGlow,
                      size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: TextStyle(
                              color: c.goldBright,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                          '${p.birthDisplay}${zhiIdx >= 0 ? "（${_zhiNames[zhiIdx]}时）" : ""}',
                          style:
                              TextStyle(color: c.textBody, fontSize: 12)),
                    ],
                  ),
                ),
                if (!p.hasHour)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.fireGlow.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: c.fireGlow.withValues(alpha: 0.55)),
                    ),
                    child: Text('时辰未知',
                        style: TextStyle(color: c.fireGlow, fontSize: 10)),
                  ),
              ],
            ),
            if (p.note != null && p.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.panel,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(p.note!,
                    style: TextStyle(color: c.textSubtitle, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GoldButton(
                    text: p.hasHour ? '全方位卜算' : '补全时辰',
                    onPressed: p.hasHour
                        ? () => context.go('/profiles/${p.id}/divination')
                        : () => _editProfile(profile: p),
                  ),
                ),
                const SizedBox(width: 8),
                _iconAction(c, Icons.edit_outlined, '编辑',
                    () => _editProfile(profile: p)),
                const SizedBox(width: 4),
                _iconAction(c, Icons.delete_outline, '删除',
                    () => _confirmDelete(p), color: gradeBad),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 卡片内图标按钮（GestureDetector + 主题色，无 inkwell）。
  Widget _iconAction(AppClr c, IconData icon, String tooltip, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color ?? c.textSubtitle, size: 20),
        ),
      ),
    );
  }
}

/// 档案新增/编辑弹窗（v3.1.1：ThemedDialog + 时辰 chip 网格 + 主题输入）。
class _ProfileEditDialog extends ConsumerStatefulWidget {
  final Profile? profile;
  const _ProfileEditDialog({this.profile});

  @override
  ConsumerState<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<_ProfileEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _year;
  late final TextEditingController _month;
  late final TextEditingController _day;
  late final TextEditingController _note;
  int? _hourIdx; // 0..11 对应子..亥；null = 未知
  bool _isMale = true;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p?.name ?? '');
    _year = TextEditingController(text: p?.year.toString() ?? '');
    _month = TextEditingController(text: p?.month.toString() ?? '');
    _day = TextEditingController(text: p?.day.toString() ?? '');
    _note = TextEditingController(text: p?.note ?? '');
    _hourIdx = p?.hour == null ? null : _zhiHours.indexOf(p!.hour!);
    if (_hourIdx != null && _hourIdx! < 0) _hourIdx = null;
    _isMale = p?.isMale ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _year, _month, _day, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final y = int.tryParse(_year.text) ?? 0;
    final m = int.tryParse(_month.text) ?? 0;
    final d = int.tryParse(_day.text) ?? 0;
    if (name.isEmpty ||
        y < 1900 ||
        y > 2100 ||
        m < 1 ||
        m > 12 ||
        d < 1 ||
        d > 31) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请填写姓名与合法生辰（年 1900-2100）'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final p = widget.profile;
    final profile = Profile(
      id: p?.id ?? ProfileStore.generateId(),
      name: name,
      year: y,
      month: m,
      day: d,
      hour: _hourIdx == null ? null : _zhiHours[_hourIdx!],
      isMale: _isMale,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: p?.createdAt ?? DateTime.now(),
    );
    if (p == null) {
      await ProfileStore.add(profile);
    } else {
      await ProfileStore.update(profile);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return ThemedDialog(
      title: widget.profile == null ? '新建档案' : '编辑档案',
      actions: [
        _dialogAction(c, '取消', c.textSubtitle, () => Navigator.pop(context, false)),
        _dialogAction(c, '保存', c.goldBright, _save, bold: true),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(c, '姓名'),
          _field(_name, '请输入姓名', text: true),
          const SizedBox(height: 10),
          _label(c, '公历生辰'),
          Row(
            children: [
              Expanded(child: _field(_year, '年')),
              const SizedBox(width: 6),
              Expanded(child: _field(_month, '月')),
              const SizedBox(width: 6),
              Expanded(child: _field(_day, '日')),
            ],
          ),
          const SizedBox(height: 12),
          _label(c, '时辰（未知则不可推演需时辰的术）'),
          const SizedBox(height: 6),
          _zhiGrid(c),
          const SizedBox(height: 12),
          _label(c, '性别'),
          const SizedBox(height: 6),
          Row(
            children: [
              _choice(c, '男', _isMale == true, () => setState(() => _isMale = true)),
              const SizedBox(width: 8),
              _choice(c, '女', _isMale == false, () => setState(() => _isMale = false)),
            ],
          ),
          const SizedBox(height: 10),
          _label(c, '备注'),
          _field(_note, '可选，记下问事背景…', text: true),
        ],
      ),
    );
  }

  Widget _label(AppClr c, String t) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Text(t, style: TextStyle(color: c.textSubtitle, fontSize: 11)),
      );

  /// 主题输入框（金边 + 透明填充 + 聚焦金亮）。
  Widget _field(TextEditingController controller, String hint,
          {bool text = false}) {
    final c = AppClr.of(context);
    return TextField(
        controller: controller,
        keyboardType:
            text ? TextInputType.text : TextInputType.number,
        style: TextStyle(color: c.textPrimary, fontSize: 13),
        cursorColor: c.gold,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: c.textHint, fontSize: 12),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.goldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.goldBright, width: 1.2),
          ),
        ),
      );
  }

  /// 时辰 chip 网格（12 时辰 + 未知）。
  Widget _zhiGrid(AppClr c) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < 12; i++)
          _zhiChip(c, '${_zhiNames[i]}时', i, _hourIdx == i),
        _zhiChip(c, '未知', -1, _hourIdx == null, isUnknown: true),
      ],
    );
  }

  Widget _zhiChip(AppClr c, String label, int idx, bool selected,
          {bool isUnknown = false}) =>
      GestureDetector(
        onTap: () => setState(() => _hourIdx = idx == -1 ? null : idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? (isUnknown
                    ? c.fireGlow.withValues(alpha: 0.18)
                    : c.gold.withValues(alpha: 0.18))
                : c.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected
                    ? (isUnknown ? c.fireGlow : c.gold)
                    : c.goldBorder,
                width: selected ? 1.2 : 1),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected
                    ? (isUnknown ? c.fireGlow : c.goldBright)
                    : c.textBody,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ),
      );

  Widget _choice(AppClr c, String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.gold.withValues(alpha: 0.18) : c.panel,
            borderRadius: BorderRadius.circular(8),
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

  Widget _dialogAction(AppClr c, String label, Color color, VoidCallback onTap,
          {bool bold = false}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 2)),
        ),
      );
}
