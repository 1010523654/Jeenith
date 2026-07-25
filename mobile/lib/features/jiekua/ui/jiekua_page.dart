// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/glm_client.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/history/history_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/divination_loading_indicator.dart';

/// 解卦页（v3.0.0）：选历史卦象 + 输入问题 → GLM-4-Flash 大模型解读 + 建议。
///
/// 底部常驻「AI 生成未必全对，理性看待」提醒。无 API key 时引导去设置页。
class JiekuaPage extends ConsumerStatefulWidget {
  const JiekuaPage({super.key});

  @override
  ConsumerState<JiekuaPage> createState() => _JiekuaPageState();
}

class _JiekuaPageState extends ConsumerState<JiekuaPage> {
  HistoryEntry? _selected;
  final _question = TextEditingController();
  String? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _pickHexuan() async {
    final list = await HistoryStore.load();
    if (!mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('暂无历史卦象，先去卜算一卦吧'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final c = AppClr.of(context);
    final picked = await showDialog<HistoryEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('选择卦象',
            style: TextStyle(color: c.goldBright, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i];
              return ListTile(
                title: Text('${e.techName} · ${e.summary}',
                    style: TextStyle(color: c.textPrimary, fontSize: 13)),
                subtitle: Text(e.time.toString().substring(0, 19),
                    style: TextStyle(color: c.textMeta, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, e),
              );
            },
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _selected = picked;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _interpret() async {
    final entry = _selected;
    if (entry == null) {
      setState(() => _error = '请先选择一个卦象');
      return;
    }
    final q = _question.text.trim();
    if (q.isEmpty) {
      setState(() => _error = '请输入想问的问题');
      return;
    }
    final key = ref.read(configProvider).valueOrNull?.glmApiKey ?? '';
    if (key.isEmpty) {
      setState(() => _error = '未配置 GLM API key，请到设置页「AI 解卦」填写');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final text = await GlmClient.interpret(
          question: q, hexuanText: entry.detail, apiKey: key);
      if (!mounted) return;
      setState(() {
        _result = text;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '解读失败：$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    final hasKey =
        (ref.watch(configProvider).valueOrNull?.glmApiKey ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            const Text('解　卦', style: TextStyle(fontSize: 18)),
            Text('AI 卦 象 解 读',
                style:
                    TextStyle(fontSize: 10, color: c.textSubtitle, letterSpacing: 4)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (!hasKey) _noKeyHint(c),
          // 卦象来源
          DecorativePanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('卦象来源',
                    style: TextStyle(
                        color: c.goldBright,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_selected == null)
                  GoldButton(text: '从历史记录选择卦象', onPressed: _pickHexuan)
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.goldBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_selected!.techName} · ${_selected!.summary}',
                            style: TextStyle(
                                color: c.goldBright,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        Text(_selected!.time.toString().substring(0, 19),
                            style: TextStyle(
                                color: c.textMeta, fontSize: 11)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: _pickHexuan,
                              child: Text('更换',
                                  style: TextStyle(color: c.gold))),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 问题
          DecorativePanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('你的问题',
                    style: TextStyle(
                        color: c.goldBright,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _question,
                  maxLines: 3,
                  style: TextStyle(color: c.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '想问什么？越具体越好…',
                    hintStyle: TextStyle(color: c.textHint, fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: c.goldBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: c.goldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: c.goldBright)),
                  ),
                ),
                const SizedBox(height: 10),
                GoldButton(
                    text: _loading ? '解读中…' : 'AI 解读',
                    onPressed: _loading ? null : _interpret),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: DivinationLoadingIndicator(size: 40))),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.fireGlow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.fireGlow.withValues(alpha: 0.5)),
              ),
              child: Text(_error!,
                  style: TextStyle(color: c.fireGlow, fontSize: 12, height: 1.5)),
            ),
          if (_result != null)
            DecorativePanel(
              padding: const EdgeInsets.all(14),
              child: SelectableText(_result!,
                  style: TextStyle(color: c.textBody, fontSize: 13, height: 1.7)),
            ),
          const SizedBox(height: 16),
          // 底部常驻提醒
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.fireGlow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: c.fireGlow, size: 16),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('AI 生成未必全对，理性看待。',
                        style: TextStyle(color: c.fireGlow, fontSize: 11))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noKeyHint(AppClr c) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DecorativePanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.key, color: c.fireGlow),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      '未配置 GLM API key，请到设置页「AI 解卦」填写（智谱 GLM-4-Flash 免费申请）。',
                      style: TextStyle(color: c.textBody, fontSize: 12))),
              TextButton(
                  onPressed: () => context.go('/settings'),
                  child: Text('去设置', style: TextStyle(color: c.gold))),
            ],
          ),
        ),
      );
}
