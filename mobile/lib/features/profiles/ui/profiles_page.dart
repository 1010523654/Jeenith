// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/profiles/profile_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/divination_loading_indicator.dart';

/// 档案页（v3.0.0）：人物生辰档案 CRUD + 进入全方位卜算。
class ProfilesPage extends ConsumerStatefulWidget {
  const ProfilesPage({super.key});

  @override
  ConsumerState<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends ConsumerState<ProfilesPage> {
  List<Profile> _list = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await ProfileStore.load();
    if (!mounted) return;
    setState(() {
      _list = list;
      _loading = false;
    });
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
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('删除档案',
            style: TextStyle(
                color: c.goldBright, fontWeight: FontWeight.bold)),
        content: Text('确定删除「${p.name}」的档案？此操作不可撤销。',
            style: TextStyle(color: c.textBody, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消', style: TextStyle(color: c.textSubtitle))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('删除', style: TextStyle(color: gradeBad))),
        ],
      ),
    );
    if (ok == true) {
      await ProfileStore.remove(p.id);
      _reload();
    }
  }

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
          IconButton(
            icon: Icon(Icons.person_add, color: c.gold),
            tooltip: '新建档案',
            onPressed: () => _editProfile(),
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
                  itemBuilder: (context, i) => _profileCard(c, _list[i]),
                ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecorativePanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(p.isMale ? Icons.male : Icons.female,
                    color: c.goldBright, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(p.name,
                      style: TextStyle(
                          color: c.goldBright,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                if (!p.hasHour)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.fireGlow.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: c.fireGlow.withValues(alpha: 0.6)),
                    ),
                    child: Text('时辰未知',
                        style: TextStyle(color: c.fireGlow, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(p.birthDisplay,
                style: TextStyle(color: c.textBody, fontSize: 12)),
            if (p.note != null && p.note!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('备注：${p.note}',
                  style: TextStyle(color: c.textSubtitle, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
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
                IconButton(
                  icon: Icon(Icons.edit, color: c.textSubtitle, size: 20),
                  tooltip: '编辑',
                  onPressed: () => _editProfile(profile: p),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: gradeBad, size: 20),
                  tooltip: '删除',
                  onPressed: () => _confirmDelete(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 档案新增/编辑弹窗。
class _ProfileEditDialog extends ConsumerStatefulWidget {
  final Profile? profile; // null = 新增
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
  int? _hour; // null = 未知
  bool _isMale = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p?.name ?? '');
    _year = TextEditingController(text: p?.year.toString() ?? '');
    _month = TextEditingController(text: p?.month.toString() ?? '');
    _day = TextEditingController(text: p?.day.toString() ?? '');
    _note = TextEditingController(text: p?.note ?? '');
    _hour = p?.hour;
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
    setState(() => _saving = true);
    final p = widget.profile;
    final profile = Profile(
      id: p?.id ?? ProfileStore.generateId(),
      name: name,
      year: y,
      month: m,
      day: d,
      hour: _hour,
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
    return AlertDialog(
      backgroundColor: c.card,
      title: Text(widget.profile == null ? '新建档案' : '编辑档案',
          style: TextStyle(color: c.goldBright, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_name, '姓名'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _field(_year, '年')),
                const SizedBox(width: 6),
                Expanded(child: _field(_month, '月')),
                const SizedBox(width: 6),
                Expanded(child: _field(_day, '日')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('时辰', style: TextStyle(color: c.textBody, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int?>(
                    value: _hour,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                          value: null,
                          child: Text('未知（需时辰的卜算不可用）',
                              style: TextStyle(color: c.fireGlow))),
                      for (var h = 0; h < 24; h++)
                        DropdownMenuItem(value: h, child: Text('$h 时')),
                    ],
                    onChanged: (v) => setState(() => _hour = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('性别', style: TextStyle(color: c.textBody, fontSize: 12)),
                const SizedBox(width: 10),
                _genderChip('男', true),
                const SizedBox(width: 6),
                _genderChip('女', false),
              ],
            ),
            const SizedBox(height: 8),
            _field(_note, '备注（可选）'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: c.textSubtitle))),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
              backgroundColor: c.gold, foregroundColor: Colors.black87),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String hint) => TextField(
        controller: controller,
        keyboardType: (hint.contains('姓名') || hint.contains('备注'))
            ? TextInputType.text
            : TextInputType.number,
        decoration: InputDecoration(hintText: hint, isDense: true),
      );

  Widget _genderChip(String label, bool male) {
    final c = AppClr.of(context);
    final selected = _isMale == male;
    return GestureDetector(
      onTap: () => setState(() => _isMale = male),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c.gold.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? c.gold : c.goldBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? c.goldBright : c.textBody,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
