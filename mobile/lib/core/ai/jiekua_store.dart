// Copyright (c) 2026 Qore
import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 解卦对话中的一条消息（v3.1.0）。
class JiekuaMessage {
  final String role; // user / assistant
  final String content;
  final DateTime time;

  const JiekuaMessage({
    required this.role,
    required this.content,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'time': time.toIso8601String(),
      };

  factory JiekuaMessage.fromJson(Map<String, dynamic> j) => JiekuaMessage(
        role: j['role'] as String,
        content: j['content'] as String,
        time: DateTime.parse(j['time'] as String),
      );
}

/// 一次解卦会话：基于某卦象的多轮对话（v3.1.0）。
class JiekuaSession {
  final String id;
  final String techName;
  final String summary;
  final String hexuanText; // 卦象原文（AI 上下文）
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<JiekuaMessage> messages;

  const JiekuaSession({
    required this.id,
    required this.techName,
    required this.summary,
    required this.hexuanText,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'techName': techName,
        'summary': summary,
        'hexuanText': hexuanText,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory JiekuaSession.fromJson(Map<String, dynamic> j) => JiekuaSession(
        id: j['id'] as String,
        techName: j['techName'] as String,
        summary: j['summary'] as String,
        hexuanText: j['hexuanText'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        messages: ((j['messages'] as List?) ?? const [])
            .map((m) => JiekuaMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  JiekuaSession copyWith({
    List<JiekuaMessage>? messages,
    DateTime? updatedAt,
  }) =>
      JiekuaSession(
        id: id,
        techName: techName,
        summary: summary,
        hexuanText: hexuanText,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messages: messages ?? this.messages,
      );
}

/// 解卦会话存储（SharedPreferences JSON，原子读-改-写，仿 [HistoryStore]）。
class JiekuaStore {
  static const _key = 'jiekua_sessions';
  static Future<void> _chain = Future.value();
  static int _counter = 0;

  static String generateId() {
    final now = DateTime.now();
    _counter = (_counter + 1) & 0xFFFF;
    return 'j-${now.microsecondsSinceEpoch}-${_counter.toRadixString(16).padLeft(4, '0')}';
  }

  static Future<List<JiekuaSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return const <JiekuaSession>[];
    try {
      final list = jsonDecode(s) as List;
      return list
          .map((j) => JiekuaSession.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <JiekuaSession>[];
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

  /// 新建或更新会话（按 id 覆盖，最新在前）。
  static Future<void> upsert(JiekuaSession s) => _serialize(() async {
        final list = <JiekuaSession>[...await load()];
        var found = false;
        for (var i = 0; i < list.length; i++) {
          if (list[i].id == s.id) {
            list[i] = s;
            found = true;
            break;
          }
        }
        if (!found) list.insert(0, s);
        await _save(list);
      });

  static Future<void> remove(String id) => _serialize(() async {
        final list = <JiekuaSession>[...await load()];
        list.removeWhere((e) => e.id == id);
        await _save(list);
      });

  static Future<void> _save(List<JiekuaSession> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
