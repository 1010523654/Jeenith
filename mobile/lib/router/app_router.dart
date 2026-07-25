// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/animation/ritual/bazi_ritual.dart';
import '../core/animation/ritual/chenggu_ritual.dart';
import '../core/animation/ritual/taiyi_ritual.dart';
import '../core/animation/ritual/cezi_ritual.dart';
import '../core/animation/ritual/chouqian_ritual.dart';
import '../core/animation/ritual/daliuren_ritual.dart';
import '../core/animation/ritual/jiaobei_ritual.dart';
import '../core/animation/ritual/luopan_ritual.dart';
import '../core/animation/ritual/meihua_ritual.dart';
import '../core/animation/ritual/name_test_ritual.dart';
import '../core/animation/ritual/qimen_ritual.dart';
import '../core/animation/ritual/ziwei_ritual.dart';
import '../core/animation/ritual/zhouyi_ritual.dart';
import '../core/animation/transitions/tech_transitions.dart';
import '../core/config/app_config.dart';
import '../core/config/config_providers.dart';
import '../core/divination/divination_registry.dart';
import '../core/divination/divination_tech.dart';
import '../features/home/home_page.dart';
import '../features/history/history_page.dart';
import '../features/jiekua/ui/jiekua_page.dart';
import '../features/manual/manual_page.dart';
import '../features/profiles/ui/profiles_page.dart';
import '../features/profiles/ui/profile_divination_page.dart';
import '../features/settings/settings_page.dart';
import '../features/xiaoliuren/ui/xiaoliuren_ritual.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // v3.0.0：底部三栏导航（卜算 / 解卦 / 档案），各 tab 保状态。
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/',
                  builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/jiekua',
                  builder: (context, state) => const JiekuaPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profiles',
                  builder: (context, state) => const ProfilesPage()),
            ],
          ),
        ],
      ),
      // 顶层全屏页面（无底部导航）
      GoRoute(
        path: '/profiles/:id/divination',
        builder: (context, state) => ProfileDivinationPage(
            profileId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
          path: '/manual', builder: (context, state) => const ManualPage()),
      // 小六壬仪式入场动画
      GoRoute(
        path: '/ritual/xiaoliuren',
        builder: (context, state) =>
            XiaoliurenRitual(onCompleted: () => context.go('/tech/xiaoliuren')),
      ),
      GoRoute(
        path: '/ritual/zhouyi',
        builder: (context, state) =>
            ZhouyiRitual(onCompleted: () => context.go('/tech/zhouyi')),
      ),
      GoRoute(
        path: '/ritual/liuyao',
        builder: (context, state) => ZhouyiRitual(
            watermark: '六爻', onCompleted: () => context.go('/tech/liuyao')),
      ),
      GoRoute(
        path: '/ritual/ziwei',
        builder: (context, state) =>
            ZiweiRitual(onCompleted: () => context.go('/tech/ziwei')),
      ),
      GoRoute(
        path: '/ritual/qimen',
        builder: (context, state) =>
            QimenRitual(onCompleted: () => context.go('/tech/qimen')),
      ),
      GoRoute(
        path: '/ritual/daliuren',
        builder: (context, state) =>
            DaliurenRitual(onCompleted: () => context.go('/tech/daliuren')),
      ),
      GoRoute(
        path: '/ritual/luopan',
        builder: (context, state) =>
            LuopanRitual(onCompleted: () => context.go('/tech/luopan')),
      ),
      GoRoute(
        path: '/ritual/meihua',
        builder: (context, state) =>
            MeihuaRitual(onCompleted: () => context.go('/tech/meihua')),
      ),
      GoRoute(
        path: '/ritual/jiaobei',
        builder: (context, state) =>
            JiaobeiRitual(onCompleted: () => context.go('/tech/jiaobei')),
      ),
      GoRoute(
        path: '/ritual/chouqian',
        builder: (context, state) =>
            ChouqianRitual(onCompleted: () => context.go('/tech/chouqian')),
      ),
      GoRoute(
        path: '/ritual/cezi',
        builder: (context, state) =>
            CeziRitual(onCompleted: () => context.go('/tech/cezi')),
      ),
      GoRoute(
        path: '/ritual/bazi',
        builder: (context, state) =>
            BaziRitual(onCompleted: () => context.go('/tech/bazi')),
      ),
      GoRoute(
        path: '/ritual/name_test',
        builder: (context, state) =>
            NameTestRitual(onCompleted: () => context.go('/tech/name_test')),
      ),
      GoRoute(
        path: '/ritual/chenggu',
        builder: (context, state) =>
            ChengguRitual(onCompleted: () => context.go('/tech/chenggu')),
      ),
      GoRoute(
        path: '/ritual/taiyi',
        builder: (context, state) =>
            TaiyiRitual(onCompleted: () => context.go('/tech/taiyi')),
      ),
      GoRoute(
        path: '/tech/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final tech = ref.read(techByIdProvider(id));
          final Widget page = (tech == null)
              ? const Scaffold(body: Center(child: Text('未知卜算法')))
              : _TechPage(tech: tech);
          final transitionsEnabled = ref
                  .read(configProvider)
                  .valueOrNull
                  ?.isAnimationEnabled(id, AnimationKind.transition) ??
              true;
          return TechTransition.build(
            key: state.pageKey,
            child: page,
            techId: id,
            transitionsEnabled: transitionsEnabled,
          );
        },
      ),
    ],
  );
});

class _TechPage extends ConsumerWidget {
  final DivinationTech tech;
  const _TechPage({required this.tech});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      tech.buildPage(context, ref);
}
