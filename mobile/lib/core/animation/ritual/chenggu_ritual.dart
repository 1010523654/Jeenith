// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// 称骨算命仪式入场（v3.0.0）：鎏金铜钱落定 + 旋转，「称骨算命」标题浮现。
class ChengguRitual extends RitualAnimation {
  const ChengguRitual({super.key, super.onCompleted});

  @override
  ConsumerState<ChengguRitual> createState() => _ChengguRitualState();
}

class _ChengguRitualState extends RitualAnimationState<ChengguRitual> {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualBazi),
    )..forward().then((_) => complete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ritualScaffold(
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 铜钱：scale + 旋转入场（0.0-0.5）
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value;
                final enter = Curves.easeOutBack
                    .transform((t / 0.5).clamp(0.0, 1.0));
                final spin = (t < 0.5) ? (1 - t / 0.5) * 0.6 : 0.0;
                return Opacity(
                  opacity: (t / 0.2).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * enter,
                    child: Transform.rotate(
                      angle: spin * 3.1416,
                      child: Icon(Icons.monetization_on,
                          size: 104, color: AppColors.goldBright),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            // 标题淡入（0.7-1.0）
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final a = ((_ctrl.value - 0.7) / 0.3).clamp(0.0, 1.0);
                return Opacity(
                  opacity: a,
                  child: Text('称 骨 算 命',
                      style: TextStyle(
                          color: AppColors.goldBright,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
