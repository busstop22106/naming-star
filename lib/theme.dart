import 'package:flutter/material.dart';

/// 작명별 디자인 시스템 — '밤하늘' 컨셉 (2026-11-12 변경)
///
/// 예전 '반짝이는 별 친구'(크림 배경·바이올렛)에서 밤하늘 다크로 바꿨다.
/// 색은 결정사주 프로토타입 3번 '밤하늘 다크'의 팔레트와 같다.
/// 깊은 밤하늘 배경에 금빛 포인트, 카드 위에 별빛이 박힌 느낌이다.
/// 폰트는 시스템 폰트 유지 (커스텀 폰트 파일은 GitHub 스냅샷 푸시가
/// 불가해서 별도 단계로). 단, 한자는 기기 기본 CJK 글꼴이 명조/궁서
/// 계열로 잡히는 경우가 있어 한자 글꼴 폴백(hanjaFontFallback)으로
/// 고딕 계열을 우선 지정한다.
///
/// 명암비: 모든 텍스트 토큰은 카드(#151D38) 위에서 WCAG AA(4.5:1)를
/// 만족하도록 골랐다 (2026-11-12 계산 확인 — ink 14.71:1, sub 6.34:1,
/// hint 4.88:1, gold 8.97:1, boyDark 7.92:1, girlDark 7.69:1,
/// goodDark 9.53:1, warnDark 9.89:1, danger 7.27:1).
class AppTheme {
  static const bg = Color(0xFF0C1226); // 밤하늘
  static const surface = Color(0xFF151D38); // 카드
  static const primary = Color(0xFFE3B959); // 금빛 (액센트)
  // 다크 테마라 '진한' 변형도 같은 금빛이다 — 글자가 어두운 면 위에
  // 놓이기 때문에 밝은 금색이 텍스트용이다. 선택 칩 라벨·순위 숫자 등
  // 텍스트 자리에 쓴다 (선택: primaryDark, 미선택: ink 규칙 유지).
  static const primaryDark = Color(0xFFE3B959);
  static const primarySoft = Color(0xFF2B3048); // 선택 칩 배경 — 금빛 틴트 진한 네이비
  static const gold = Color(0xFFE3B959); // 별·강조 금빛
  // 금색 버튼 위 어두운 글자 (프로토타입 --pacc-ink #131A30).
  static const onGold = Color(0xFF131A30);
  // 헤더 카드용 깊은 네이비 그라데이션 (프로토타입 decision 카드).
  static const deepNavy = Color(0xFF1D2A52);
  static const deepNavyDark = Color(0xFF131C3A);
  static const deepBorder = Color(0xFF33477F);
  static const ink = Color(0xFFEEF1FA);
  static const sub = Color(0xFF93A0BE); // 보조 문구용
  static const hint = Color(0xFF7C8BB0); // 입력 힌트용
  static const chipBorder = Color(0xFF27335A); // 미선택 칩 테두리용
  static const line = Color(0xFF27335A);
  /// 한자 글꼴 폴백 — 가장 일반적인 고딕(산세리프) 한자부터 찾는다.
  /// 앞 이름이 없는 기기에서는 시스템 산세리프로 떨어지는데, 그 산세리프의
  /// CJK 글꼴도 고딕 계열이라 명조/궁서 계열로 보이는 일은 없다.
  static const hanjaFontFallback = [
    'Noto Sans CJK KR',
    'Noto Sans CJK',
    'Noto Sans KR',
    'sans-serif',
  ];

  // 성별 채움색 — 흰 글자가 올라가니 진한 쪽으로 골랐다
  // (흰 글자: boy 5.49:1, girl 5.57:1).
  // 2026-11-12 톤다운: 랭킹 트렌드 카드에서 기존 색(#2F6BDB/#D6336C)이
  // 채도 70%/65%로 너무 쨍하다는 지적 → 채도 45%로 낮췄다.
  // 흰 글자 명암비는 오히려 올라갔다(4.94/4.62 → 5.49/5.57).
  static const boy = Color(0xFF4169AA);
  static const girl = Color(0xFFAE4266);
  // ── 명암비용 밝은 변형 — boy/girl 채움색은 어두워 카드 위 작은
  // 텍스트에는 쓸 수 없어, 텍스트용 밝은 토큰을 둔다.
  // 채움·선·아이콘 같은 그래픽 요소에는 원래 색을 그대로 쓴다.
  static const boyDark = Color(0xFF8FB4F5); // 카드 위 7.92:1
  static const girlDark = Color(0xFFFF8FA5); // 카드 위 7.69:1
  static const pink = Color(0xFFFF5C7A); // 궁합 강조 핑크 (그래픽용)
  static const pinkDark = Color(0xFFFF8FA5); // 궁합 텍스트용 밝은 핑크
  static const pinkSoft = Color(0xFF3A2233); // 궁합 강조 배경 (어두운 장미)
  static const pinkLight = Color(0xFFFF8FA5); // 흐르는 하트
  static const mapLine = Color(0xFF33477F); // 궁합 지도 일반 연결선
  static const goldDark = Color(0xFFE3B959); // 금색 구간 텍스트용 (8.97:1)
  static const goodDark = Color(0xFF4ADE80); // 9.53:1
  static const warnDark = Color(0xFFF2C14E); // 9.89:1
  static const danger = Color(0xFFFF8A80); // 삭제 등 위험 텍스트용 (7.27:1)
  static const good = Color(0xFF4ADE80);
  static const warn = Color(0xFFF2C14E);
  static const bad = Color(0xFFF47070);
  static const warnSoft = Color(0xFF2E2410); // 경고 박스 배경 (어두운 호박)

  /// 카드 그림자 — 어두운 배경에서는 인디고 틴트가 안 보여 검정 그림자로.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primary,
        primary: primary,
        onPrimary: onGold,
        secondary: gold,
        surface: surface,
        onSurface: ink,
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
        shadowColor: Colors.black.withValues(alpha: 0.35),
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
      // 세그먼트 버튼 선택 상태 — 하단 CTA 버튼과 같은 금빛 채움 + 남색 글자.
      // 기본값(secondaryContainer)은 금빛 시드에서 파생된 올리브빛이라
      // 밤하늘 테마와 안 맞아 실기기에서 어색하게 보인다 (2026-11-13 지적).
      // 미선택 상태는 기본값(어두운 배경·밝은 글자·테두리) 그대로 둔다.
      // styleFrom에는 선택 아이콘 색상 파라미터가 없어 ButtonStyle을 직접 만든다.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? primary : null),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? onGold : null),
          iconColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? onGold : null),
        ),
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
          foregroundColor: onGold,
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
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primarySoft,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: surface),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: surface),
      dividerTheme: const DividerThemeData(color: line),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: ink),
        titleSmall: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: ink),
        bodyMedium: TextStyle(color: ink, height: 1.55),
        bodySmall: TextStyle(color: sub, height: 1.5),
      ).apply(fontFamilyFallback: hanjaFontFallback),
    );
  }

  static Color scoreColor(double score) {
    if (score >= 85) return good;
    if (score >= 70) return gold;
    if (score >= 55) return warn;
    return bad;
  }

  /// 점수 구간별 텍스트용 색상 — scoreColor는 링·막대 같은 그래픽용이고,
  /// 글자에는 카드 위에서 AA를 만족하는 밝은 변형을 쓴다.
  static Color scoreTextColor(double score) {
    if (score >= 85) return goodDark;
    if (score >= 70) return goldDark;
    if (score >= 55) return warnDark;
    return danger;
  }

  static String scoreWord(double score) {
    if (score >= 90) return '최상';
    if (score >= 80) return '우수';
    if (score >= 70) return '양호';
    if (score >= 55) return '보통';
    return '주의';
  }
}
