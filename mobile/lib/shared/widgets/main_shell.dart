// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// 主壳：底部三栏导航（卜算 / 解卦 / 档案）。
///
/// v3.0.0：用 [StatefulNavigationShell] 驱动，三个 tab 各保状态；
/// 中间「解卦」凸起圆形按钮 + 金色呼吸发光动画，视觉突出。
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _go(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBar()),
        ],
      ),
    );
  }

  Widget _buildBar() {
    final c = AppClr.of(context);
    final current = widget.navigationShell.currentIndex;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.goldBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _sideItem(c, current, 0, Icons.apps, '卜算'),
              ),
              _jiekuaButton(c, current),
              Expanded(
                child:
                    _sideItem(c, current, 2, Icons.person_outline, '档案'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 左右普通 tab 项。
  Widget _sideItem(
      AppClr c, int current, int index, IconData icon, String label) {
    final selected = current == index;
    final color = selected ? c.goldBright : c.textSubtitle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(index),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  /// 中间解卦：凸起圆形 + 金色发光呼吸动画（视觉突出）。
  Widget _jiekuaButton(AppClr c, int current) {
    final selected = current == 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(1),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          final scale = (selected ? 1.05 : 1.0) + 0.04 * t;
          final glow = (selected ? 0.45 : 0.25) + 0.20 * t;
          return Transform.translate(
            offset: const Offset(0, -16),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.goldBright, c.fireGlow],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.gold.withValues(alpha: glow),
                      blurRadius: 14 + 10 * t,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.lightbulb,
                    color: Colors.white, size: 26),
              ),
            ),
          );
        },
      ),
    );
  }
}
