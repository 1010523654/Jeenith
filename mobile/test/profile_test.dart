// Copyright (c) 2026 Qore
import 'package:flutter_test/flutter_test.dart';
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
}
