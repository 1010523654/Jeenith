// Copyright (c) 2026 Qore
import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 人物生辰档案（v3.0.0）。
///
/// [hour] 为 null 表示「时辰未知」——紫微/八字/称骨均需时辰，缺时辰时三术不可用。
class Profile {
  final String id;
  final String name;
  final int year;
  final int month;
  final int day;
  final int? hour; // null = 未知
  final bool isMale;
  final String? note;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.name,
    required this.year,
    required this.month,
    required this.day,
    this.hour,
    required this.isMale,
    this.note,
    required this.createdAt,
  });

  bool get hasHour => hour != null;

  String get birthDisplay {
    final h = hour == null ? '时辰未知' : '$hour时';
    return '$year年$month月$day日 $h';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'isMale': isMale,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['name'] as String,
        year: j['year'] as int,
        month: j['month'] as int,
        day: j['day'] as int,
        hour: j['hour'] as int?,
        isMale: j['isMale'] as bool? ?? true,
        note: j['note'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Profile copyWith({
    String? name,
    int? year,
    int? month,
    int? day,
    bool? isMale,
    String? note,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        year: year ?? this.year,
        month: month ?? this.month,
        day: day ?? this.day,
        hour: hour,
        isMale: isMale ?? this.isMale,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}

/// 档案存储（SharedPreferences JSON，原子读-改-写，仿 [HistoryStore]）。
class ProfileStore {
  static const _key = 'profiles';
  static Future<void> _chain = Future.value();
  static int _counter = 0;

  static String generateId() {
    final now = DateTime.now();
    _counter = (_counter + 1) & 0xFFFF;
    return 'p-${now.microsecondsSinceEpoch}-${_counter.toRadixString(16).padLeft(4, '0')}';
  }

  static Future<List<Profile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return const <Profile>[];
    try {
      final list = jsonDecode(s) as List;
      return list
          .map((j) => Profile.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Profile>[];
    }
  }

  static Future<T> _serialize<T>(Future<T> Function() task) {
    final prev = _chain;
    final completer = Completer<T>();
    _chain = prev
        .then((_) => task())
        .then(completer.complete, onError: completer.completeError);
    return completer.future;
  }

  static Future<void> add(Profile p) => _serialize(() async {
        final list = await load();
        list.insert(0, p);
        await _save(list);
      });

  static Future<void> update(Profile p) => _serialize(() async {
        final list = await load();
        for (var i = 0; i < list.length; i++) {
          if (list[i].id == p.id) {
            list[i] = p;
            break;
          }
        }
        await _save(list);
      });

  static Future<void> remove(String id) => _serialize(() async {
        final list = await load();
        list.removeWhere((e) => e.id == id);
        await _save(list);
      });

  static Future<void> _save(List<Profile> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
