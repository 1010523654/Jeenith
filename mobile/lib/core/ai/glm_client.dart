// Copyright (c) 2026 Qore
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 一条对话消息（role: system / user / assistant）。
class GlmMessage {
  final String role;
  final String content;
  const GlmMessage(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// GLM-4-Flash 大模型客户端（v3.0.0 解卦；v3.1.0 加多轮对话）。
///
/// 智谱 AI openai 兼容接口，免费模型 `glm-4-flash`。key 由用户在设置页填入。
class GlmClient {
  static const _endpoint =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  /// 默认系统提示：解卦师人格。
  static const defaultSystemPrompt =
      '你是一位精通中国传统卜算（周易、紫微斗数、八字、梅花易数等）的解卦师。'
      '用户会提供卦象或卜算结果，以及想问的问题。'
      '请结合卦象做详细、全面的解读，并给出可行、正面的建议。'
      '可使用 Markdown 分点、加粗、标题等排版，语言自然，使用中文；不要编造卦象中没有的事实。'
      '用户可能连续追问，请结合此前对话上下文回答。';

  /// 多轮对话：[messages] 为 user/assistant 历史对话（不含 system，内部自动前置系统提示）。
  static Future<String> chat({
    required List<GlmMessage> messages,
    required String apiKey,
    String? systemPrompt,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('未配置 GLM API key，请在设置页填写');
    }
    final all = <Map<String, dynamic>>[
      GlmMessage('system', systemPrompt ?? defaultSystemPrompt).toJson(),
      ...messages.map((m) => m.toJson()),
    ];

    final resp = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'glm-4-flash',
            'messages': all,
            'stream': false,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (resp.statusCode != 200) {
      throw Exception('GLM 请求失败（${resp.statusCode}）：${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('GLM 返回为空');
    }
    final msg = (choices[0] as Map<String, dynamic>)['message'];
    return msg['content'] as String;
  }

  /// 单次解读（便捷，内部走 [chat]）。保留向后兼容。
  static Future<String> interpret({
    required String question,
    required String hexuanText,
    required String apiKey,
  }) =>
      chat(
        apiKey: apiKey,
        messages: [
          GlmMessage('user', '我想问：$question\n\n卦象 / 卜算结果：\n$hexuanText')
        ],
      );
}
