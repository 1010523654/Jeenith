// Copyright (c) 2026 Qore
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeenith/core/profiles/profile_store.dart';

void main() {
  group('Profile 模型', () {
    test('toJson/fromJson 往返', () {
      final p = Profile(
        id: 'p1',
        name: '张三',
        year: 1990,
        month: 5,
        day: 15,
        hour: 8,
        isMale: true,
        note: '备注',
        createdAt: DateTime(2026, 7, 24),
      );
      final p2 = Profile.fromJson(p.toJson());
      expect(p2.name, '张三');
      expect(p2.year, 1990);
      expect(p2.hour, 8);
      expect(p2.hasHour, true);
      expect(p2.note, '备注');
    });

    test('hour null = 时辰未知', () {
      final p = Profile(
        id: 'p2',
        name: '李四',
        year: 2000,
        month: 1,
        day: 1,
        hour: null,
        isMale: false,
        createdAt: DateTime(2026, 7, 24),
      );
      expect(p.hasHour, false);
      expect(p.birthDisplay.contains('时辰未知'), true);
    });

    test('copyWith 保留 hour 与其他字段', () {
      final p = Profile(
        id: 'p3',
        name: '王五',
        year: 1985,
        month: 3,
        day: 20,
        hour: 12,
        isMale: true,
        createdAt: DateTime(2026, 7, 24),
      );
      final p2 = p.copyWith(name: '赵六');
      expect(p2.name, '赵六');
      expect(p2.hour, 12);
      expect(p2.year, 1985);
    });
  });

  group('ProfileStore', () {
    test('add 到空存储不崩溃（v3.1.1 曾因 const list 崩溃）', () async {
      SharedPreferences.setMockInitialValues({});
      final p = Profile(
        id: 's1',
        name: '测试',
        year: 2000,
        month: 1,
        day: 1,
        hour: null,
        isMale: true,
        createdAt: DateTime(2026, 7, 26),
      );
      await ProfileStore.add(p);
      final list = await ProfileStore.load();
      expect(list.length, 1);
      expect(list.first.name, '测试');
    });

    test('update/remove 正常', () async {
      SharedPreferences.setMockInitialValues({});
      final p = Profile(
        id: 's2',
        name: '原',
        year: 1990,
        month: 6,
        day: 6,
        hour: 4,
        isMale: true,
        createdAt: DateTime(2026, 7, 26),
      );
      await ProfileStore.add(p);
      await ProfileStore.update(p.copyWith(name: '改'));
      var list = await ProfileStore.load();
      expect(list.first.name, '改');
      await ProfileStore.remove('s2');
      list = await ProfileStore.load();
      expect(list, isEmpty);
    });
  });
}
