import 'package:flutter/material.dart';

const kGreen      = Color(0xFF4CAF50);   // 清新绿
const kGreenLight = Color(0xFFE8F5E9);   // 浅绿背景
const kGreenDark  = Color(0xFF388E3C);   // 深绿（渐变用）
const kBgGray     = Color(0xFFF8F9FA);   // 极浅灰背景，更清爽
const kCardWhite  = Color(0xFFFFFFFF);
const kTextDark   = Color(0xFF212121);
const kTextGray   = Color(0xFF9E9E9E);
const kDivider    = Color(0xFFEEEEEE);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kGreen,
      primary: kGreen,
      surface: kCardWhite,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kBgGray,
    appBarTheme: const AppBarTheme(
      backgroundColor: kCardWhite,
      foregroundColor: kTextDark,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: kTextDark,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: kCardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: kCardWhite,
      selectedItemColor: kGreen,
      unselectedItemColor: Colors.grey.shade400,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(
      color: kDivider,
      thickness: 1,
      space: 1,
    ),
  );
}

// 评分颜色
Color scoreColor(double score) {
  if (score >= 80) return kGreen;
  if (score >= 60) return const Color(0xFFFF9800);
  return const Color(0xFFF44336);
}

// 时长格式化
String fmtDuration(int secs) {
  final m = (secs ~/ 60).toString().padLeft(2, '0');
  final s = (secs % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String fmtDurationChinese(int secs) {
  if (secs <= 0) return '-';
  if (secs < 60) return '$secs秒';
  final m = secs ~/ 60;
  final s = secs % 60;
  return s > 0 ? '$m分$s秒' : '$m分钟';
}
