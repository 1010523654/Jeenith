// Copyright (c) 2026 Qore
import 'dart:convert';

import 'package:http/http.dart' as http;

/// GLM-4-Flash 大模型客户端（v3.0.0 解卦用）。
///
/// 智谱 AI openai 兼容接口，免费模型 `glm-4-flash`。key 由用户在设置页填入，
/// 不硬编码。
class GlmClient {
  static const _endpoint =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  /// 解读卦象：用户问题 + 卦象文本 → 中文解读与建议。
  ///
  /// [apiKey] 智谱 API key；[question] 用户问题；[hexuanText] 卦象/卜算结果文本。
  /// 失败抛异常（网络 / 鉴权 / 解析），由调用方处理。
  static Future<String> interpret({
    required String question,
    required String hexuanText,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('未配置 GLM API key，请在设置页填写');
    }
    const systemPrompt = '你是一位精通中国传统卜算（周易、紫微斗数、八字、梅花易数等）的解卦师。'
        '用户会提供一个卦象或卜算结果的详细文本，以及想问的问题。'
        '请结合卦象本身做详细、全面的解读，并给出可行、正面的建议。'
        '分点清晰、语言自然，使用中文回答；不要编造卦象中没有的事实。';
    final userPrompt = '我想问：$question\n\n卦象 / 卜算结果：\n$hexuanText';

    final resp = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'glm-4-flash',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
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
}
