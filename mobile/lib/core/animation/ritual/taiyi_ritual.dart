// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// 太乙神数仪式入场（v3.0.0）：九宫星点逐个点亮，「太乙神数」标题浮现。
class TaiyiRitual extends RitualAnimation {
  const TaiyiRitual({super.key, super.onCompleted});

  @override
  ConsumerState<TaiyiRitual> createState() => _TaiyiRitualState();
}

class _TaiyiRitualState extends RitualAnimationState<TaiyiRitual> {
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
            // 九宫星点：3×3 逐个点亮（0.0-0.6），中心最亮
            SizedBox(
              width: 180,
              height: 180,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return GridView.count(
                    crossAxisCount: 3,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < 9; i++)
                        _star(i, _ctrl.value),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            // 标题淡入（0.7-1.0）
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final a = ((_ctrl.value - 0.7) / 0.3).clamp(0.0, 1.0);
                return Opacity(
                  opacity: a,
                  child: Text('太 乙 神 数',
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

  Widget _star(int i, double t) {
    // 中心(i=4)最先，其余按距中心顺序点亮
    final order = [4, 1, 3, 5, 7, 0, 2, 6, 8].indexOf(i);
    final lightT = ((t - order * 0.06) / 0.18).clamp(0.0, 1.0);
    final isCenter = i == 4;
    return Center(
      child: Opacity(
        opacity: lightT,
        child: Transform.scale(
          scale: 0.5 + 0.5 * Curves.easeOut.transform(lightT),
          child: Icon(
            isCenter ? Icons.auto_awesome : Icons.star,
            size: isCenter ? 40 : 22,
            color: isCenter
                ? AppColors.goldBright
                : AppColors.gold.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
