import 'package:flutter/material.dart';

/// 작명별 디자인 시스템 — '반짝이는 별 친구' 컨셉
///
/// 앱 아이콘(노란 별 캐릭터 + 라벤더 하늘)의 색감을 화면으로 가져왔다.
/// 둥글림을 키우고 그림자를 부드럽게 해서, 보기만 해도 기분 좋아지는
/// 귀엽고 따뜻한 무드를 만든다. 폰트는 시스템 폰트 유지
/// (커스텀 폰트 파일은 GitHub 스냅샷 푸시가 불가해서 별도 단계로).
class AppTheme {
  static const bg = Color(0xFFFFF9F1);
  static const surface = Colors.white;
  static const primary = Color(0xFF5B4DBC); // 밝은 바이올렛 (아이콘 하늘빛)
  static const primaryDark = Color(0xFF3D348B); // 강조·그라데이션용 진한 바이올렛
  static const primarySoft = Color(0xFFEDE8FB);
  static const gold = Color(0xFFFFC53D); // 별 노랑
  static const starBg = Color(0xFFFFF6D8); // 별 배경 크림
  static const blush = Color(0xFFFFE9E9); // 볼터치 핑크 배경
  static const coral = Color(0xFFF4845F);
  static const ink = Color(0xFF2B2440);
  static const sub = Color(0xFF8A839E);
  static const hint = Color(0xFFB8B0CC); // 입력 힌트용 밝은 회색
  static const line = Color(0xFFF0E7D8);
  static const boy = Color(0xFF5B8DEF);
  static const girl = Color(0xFFF472A0);
  static const good = Color(0xFF43A06B);
  static const warn = Color(0xFFE0A030);
  static const bad = Color(0xFFE05D5D);

  /// 카드 그림자 — 인디고 틴트의 부드러운 그림자
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.10),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: gold,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: ink),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: line),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        selectedColor: primarySoft,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: hint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: ink),
        titleSmall: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: ink),
        bodyMedium: TextStyle(color: ink, height: 1.55),
        bodySmall: TextStyle(color: sub, height: 1.5),
      ),
    );
  }

  static Color scoreColor(double score) {
    if (score >= 85) return good;
    if (score >= 70) return gold;
    if (score >= 55) return warn;
    return bad;
  }

  static String scoreWord(double score) {
    if (score >= 90) return '최상';
    if (score >= 80) return '우수';
    if (score >= 70) return '양호';
    if (score >= 55) return '보통';
    return '주의';
  }
}
