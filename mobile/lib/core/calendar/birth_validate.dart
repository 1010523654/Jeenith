// Copyright (c) 2026 Qore

/// 校验公历生辰范围（v3.1.5：超范围提示，避免 lunar 库异常）。
///
/// 返回 null 表示合法；否则返回中文提示文案。
/// 年 1900-2100 / 月 1-12 / 日 1-31 / 时 0-23。
String? validateBirth(int year, int month, int day, int hour) {
  if (year < 1900 || year > 2100) return '年份需在 1900–2100 之间';
  if (month < 1 || month > 12) return '月份需在 1–12 之间';
  if (day < 1 || day > 31) return '日期需在 1–31 之间';
  if (hour < 0 || hour > 23) return '时辰需在 0–23 之间';
  return null;
}

/// 仅年月日（无时辰）校验，用于档案缺时辰等场景。
String? validateBirthYmd(int year, int month, int day) {
  if (year < 1900 || year > 2100) return '年份需在 1900–2100 之间';
  if (month < 1 || month > 12) return '月份需在 1–12 之间';
  if (day < 1 || day > 31) return '日期需在 1–31 之间';
  return null;
}
