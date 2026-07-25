// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/glm_client.dart';
import '../../../core/ai/jiekua_store.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/history/history_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/decorative_panel.dart';

/// 解卦页（v3.1.0）：多轮对话式 AI 解卦，Markdown 渲染，本地会话历史，过渡动画。
///
/// v3.0.0 单次解读；v3.1.0 升级为智能体式多轮对话（AI 记上下文，可连续追问）。
class JiekuaPage extends ConsumerStatefulWidget {
  const JiekuaPage({super.key});

  @override
  ConsumerState<JiekuaPage> createState() => _JiekuaPageState();
}

class _JiekuaPageState extends ConsumerState<JiekuaPage> {
  final _input = TextEditingController();
  final _listKey = GlobalKey<AnimatedListState>();
  final _scrollCtrl = ScrollController();
  JiekuaSession? _session;
  HistoryEntry? _picked;
  List<JiekuaMessage> _bubbles = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _hasKey =>
      (ref.read(configProvider).valueOrNull?.glmApiKey ?? '').isNotEmpty;

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
    if (picked != null) setState(() => _picked = picked);
  }

  void _newSession() {
    setState(() {
      _session = null;
      _picked = null;
      _bubbles = const [];
      _error = null;
      _input.clear();
    });
  }

  void _loadSession(JiekuaSession s) {
    setState(() {
      _session = s;
      _picked = null;
      _bubbles = List.of(s.messages);
      _error = null;
      _input.clear();
    });
    // 重建 AnimatedList 后重建 key，让历史气泡整批淡入
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var i = 0; i < _bubbles.length; i++) {
        _listKey.currentState?.insertItem(i, duration: Duration.zero);
      }
      _scrollToBottom(jump: true);
    });
  }

  Future<void> _showHistory() async {
    final list = await JiekuaStore.load();
    if (!mounted) return;
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('解卦历史',
            style: TextStyle(color: c.goldBright, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: list.isEmpty
              ? Text('暂无解卦历史', style: TextStyle(color: c.textHint))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return ListTile(
                      title: Text('${s.techName} · ${s.summary}',
                          style: TextStyle(
                              color: c.textPrimary, fontSize: 13)),
                      subtitle: Text(
                          '${s.messages.length} 条对话 · ${s.updatedAt.toString().substring(0, 16)}',
                          style: TextStyle(
                              color: c.textMeta, fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _loadSession(s);
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: gradeBad, size: 20),
                        onPressed: () async {
                          await JiekuaStore.remove(s.id);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _showHistory();
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('关闭', style: TextStyle(color: c.textSubtitle))),
        ],
      ),
    );
  }

  void _addBubble(JiekuaMessage m) {
    setState(() => _bubbles = [..._bubbles, m]);
    _listKey.currentState?.insertItem(_bubbles.length - 1);
    _scrollToBottom();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (jump) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      } else {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _loading) return;
    final key = ref.read(configProvider).valueOrNull?.glmApiKey ?? '';
    if (key.isEmpty) {
      setState(() => _error = '未配置 GLM API key，请到设置页「AI 解卦」填写');
      return;
    }
    if (_session == null && _picked == null) {
      setState(() => _error = '请先选择卦象');
      return;
    }

    if (_session == null) {
      final p = _picked!;
      _session = JiekuaSession(
        id: JiekuaStore.generateId(),
        techName: p.techName,
        summary: p.summary,
        hexuanText: p.detail,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: const [],
      );
    }

    final userMsg =
        JiekuaMessage(role: 'user', content: q, time: DateTime.now());
    _addBubble(userMsg);
    _input.clear();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final customSystem =
          '${GlmClient.defaultSystemPrompt}\n\n用户提供的卦象 / 卜算结果：\n${_session!.hexuanText}';
      final glmMsgs =
          _bubbles.map((m) => GlmMessage(m.role, m.content)).toList();
      final reply = await GlmClient.chat(
          messages: glmMsgs, apiKey: key, systemPrompt: customSystem);
      if (!mounted) return;
      final aMsg = JiekuaMessage(
          role: 'assistant', content: reply, time: DateTime.now());
      _addBubble(aMsg);
      final updated = _session!.copyWith(
          messages: List.of(_bubbles), updatedAt: DateTime.now());
      _session = updated;
      await JiekuaStore.upsert(updated);
      if (!mounted) return;
      setState(() => _loading = false);
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
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: c.gold),
            tooltip: '解卦历史',
            onPressed: _showHistory,
          ),
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: c.gold),
            tooltip: '新会话',
            onPressed: _newSession,
          ),
        ],
      ),
      body: Column(
        children: [
          _hexuanBar(c),
          if (!_hasKey) _noKeyHint(c),
          Expanded(child: _chatArea(c)),
          if (_error != null) _errorBar(c),
          if (_loading) _loadingBar(c),
          _inputBar(c),
          _disclaimer(c),
        ],
      ),
    );
  }

  /// 卦象来源条（过渡切换）。
  Widget _hexuanBar(AppClr c) {
    final src = _session != null
        ? (_session!.techName, _session!.summary)
        : _picked != null
            ? (_picked!.techName, _picked!.summary)
            : null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: src == null
          ? Container(
              key: const ValueKey('empty'),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: DecorativePanel(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: GestureDetector(
                  onTap: _pickHexuan,
                  child: Row(children: [
                    Icon(Icons.add_chart, color: c.gold, size: 20),
                    const SizedBox(width: 8),
                    Text('选择卦象开始解卦',
                        style: TextStyle(color: c.goldBright, fontSize: 13)),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: c.textSubtitle, size: 18),
                  ]),
                ),
              ),
            )
          : Container(
              key: ValueKey(src.$1 + src.$2),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: DecorativePanel(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: GestureDetector(
                  onTap: _session == null ? _pickHexuan : null,
                  child: Row(children: [
                    Icon(Icons.auto_awesome, color: c.goldBright, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${src.$1} · ${src.$2}',
                          style: TextStyle(
                              color: c.goldBright,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (_session == null)
                      Text('更换', style: TextStyle(color: c.gold, fontSize: 12)),
                  ]),
                ),
              ),
            ),
    );
  }

  Widget _chatArea(AppClr c) {
    if (_bubbles.isEmpty) {
      return Center(
        child: Text(
            _session == null && _picked == null
                ? '请先选择卦象，再输入问题'
                : '输入你的问题，开始 AI 解卦',
            style: TextStyle(color: c.textHint, fontSize: 13)),
      );
    }
    return AnimatedList(
      key: _listKey,
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      initialItemCount: _bubbles.length,
      itemBuilder: (context, index, animation) =>
          _bubble(c, _bubbles[index], animation),
    );
  }

  /// 单条气泡：user 右金色 / assistant 左卡片 Markdown。
  Widget _bubble(AppClr c, JiekuaMessage m, Animation<double> anim) {
    final isUser = m.role == 'user';
    return SizeTransition(
      sizeFactor: anim,
      axisAlignment: 0,
      child: SlideTransition(
        position: Tween<Offset>(
                begin: Offset(isUser ? 0.2 : -0.2, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: anim,
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? c.gold.withValues(alpha: 0.16)
                    : c.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: Border.all(color: c.goldBorder),
              ),
              child: isUser
                  ? Text(m.content,
                      style: TextStyle(color: c.textPrimary, fontSize: 13, height: 1.5))
                  : MarkdownBody(
                      data: m.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: c.textBody, fontSize: 13, height: 1.65),
                        h2: TextStyle(
                            color: c.goldBright,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        h3: TextStyle(
                            color: c.goldBright, fontSize: 14, fontWeight: FontWeight.bold),
                        strong: TextStyle(color: c.goldBright, fontWeight: FontWeight.bold),
                        listBullet: TextStyle(color: c.gold),
                        blockSpacing: 6,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBar(AppClr c) => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.fireGlow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.fireGlow.withValues(alpha: 0.5)),
        ),
        child: Text(_error!,
            style: TextStyle(color: c.fireGlow, fontSize: 12, height: 1.5)),
      );

  Widget _loadingBar(AppClr c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: c.gold)),
            const SizedBox(width: 8),
            Text('解读中…', style: TextStyle(color: c.textSubtitle, fontSize: 12)),
          ],
        ),
      );

  Widget _inputBar(AppClr c) => Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.goldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(color: c.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '输入问题或追问…',
                  hintStyle: TextStyle(color: c.textHint, fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: IconButton(
                key: ValueKey(_loading),
                onPressed: _loading ? null : _send,
                icon: Icon(_loading ? Icons.hourglass_top : Icons.send,
                    color: _loading ? c.textHint : c.goldBright),
                style: IconButton.styleFrom(
                  backgroundColor: c.gold.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _disclaimer(AppClr c) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 86),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.fireGlow.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: c.fireGlow, size: 14),
            const SizedBox(width: 6),
            Expanded(
                child: Text('AI 生成未必全对，理性看待。',
                    style: TextStyle(color: c.fireGlow, fontSize: 10))),
          ],
        ),
      );

  Widget _noKeyHint(AppClr c) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.fireGlow.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.fireGlow.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.key, color: c.fireGlow, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text('未配置 GLM API key，请到设置页「AI 解卦」填写。',
                    style: TextStyle(color: c.textBody, fontSize: 12))),
            TextButton(
                onPressed: () => context.go('/settings'),
                child: Text('去设置', style: TextStyle(color: c.gold))),
          ],
        ),
      );
}
