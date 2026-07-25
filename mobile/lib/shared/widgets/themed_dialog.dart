// Copyright (c) 2026 Qore
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 主题弹窗（替代原生 AlertDialog，v3.1.1+）。
///
/// 背景模糊渐入 + 主题卡片（金边 + 深色）+ scale easeOutBack 入场，
/// 标题带鎏金竖条。用 [show] 弹出（barrierDismissible）。
class ThemedDialog extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;

  const ThemedDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  /// 便捷弹出。
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget> actions = const [],
  }) =>
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => ThemedDialog(
            title: title, actions: actions, child: child),
      );

  @override
  State<ThemedDialog> createState() => _ThemedDialogState();
}

class _ThemedDialogState extends State<ThemedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) {
        final scaleT = Curves.easeOutBack.transform(_enter.value);
        final blurT = Curves.easeOutCubic.transform(_enter.value);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * blurT, sigmaY: 4 * blurT),
          child: Container(
            color: Colors.black.withValues(alpha: 0.38 * blurT),
            child: Center(
              child: Opacity(
                opacity: _enter.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.88 + 0.12 * scaleT,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.goldBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 380,
                          maxHeight: MediaQuery.of(context).size.height * 0.72,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 标题（鎏金竖条 + 金字）
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                      width: 3,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: c.goldBright,
                                        borderRadius: BorderRadius.circular(2),
                                      )),
                                  const SizedBox(width: 8),
                                  Text(widget.title,
                                      style: TextStyle(
                                          color: c.goldBright,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2)),
                                ],
                              ),
                            ),
                            Flexible(
                                child: SingleChildScrollView(
                                    child: widget.child)),
                            if (widget.actions.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: widget.actions,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
