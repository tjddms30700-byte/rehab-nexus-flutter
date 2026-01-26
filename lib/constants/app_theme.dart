import 'package:flutter/material.dart';

/// AQU LAB Care 앱 테마 (Material Design 3)
class AppTheme {
  // === 브랜드 컬러 (수중재활 테마) ===
  static const Color primary = Color(0xFF0077BE); // 밝은 블루 (물)
  static const Color primaryDark = Color(0xFF005A8C); // 진한 블루
  static const Color secondary = Color(0xFF00C9A7); // 청록색 (생명력)
  static const Color accent = Color(0xFFFF9E00); // 오렌지 (에너지)

  // === 기능별 컬러 ===
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // === 역할별 컬러 ===
  static const Color therapistColor = Color(0xFF0077BE);
  static const Color guardianColor = Color(0xFF8E24AA);
  static const Color adminColor = Color(0xFFE65100);

  // === 난이도 레벨 컬러 ===
  static const Color level1 = Color(0xFF81C784); // 녹색 (쉬움)
  static const Color level2 = Color(0xFF64B5F6); // 밝은 파랑
  static const Color level3 = Color(0xFFFFB74D); // 주황
  static const Color level4 = Color(0xFFFF8A65); // 진한 주황
  static const Color level5 = Color(0xFFE57373); // 빨강 (어려움)

  // === 라이트 테마 ===
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
  );

  // === 다크 테마 ===
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  // === 레벨별 컬러 가져오기 ===
  static Color getLevelColor(int level) {
    switch (level) {
      case 1:
        return level1;
      case 2:
        return level2;
      case 3:
        return level3;
      case 4:
        return level4;
      case 5:
        return level5;
      default:
        return level3;
    }
  }

  // === 역할별 컬러 가져오기 ===
  static Color getRoleColor(String role) {
    switch (role) {
      case 'THERAPIST':
      case 'CENTER_ADMIN':
        return therapistColor;
      case 'GUARDIAN':
        return guardianColor;
      case 'SUPER_ADMIN':
        return adminColor;
      default:
        return primary;
    }
  }
}
