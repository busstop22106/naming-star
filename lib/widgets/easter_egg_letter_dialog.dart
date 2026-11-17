import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 설정 > 앱 버전 10회 연속 탭 이스터에그 — 우주 아빠가 가족에게 보내는 편지.
/// 편지지처럼 크림색 종이에 손글씨(나눔펜)로 보여준다 (2026-11-17).
/// 글꼴은 google_fonts가 런타임에 내려받아 캐시한다 — 네트워크가 안 되면
/// 시스템 폰트로 그려진다.
Future<void> showEasterEggLetterDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _EasterEggLetterDialog(),
  );
}

class _EasterEggLetterDialog extends StatelessWidget {
  const _EasterEggLetterDialog();

  // 편지지 크림색·잉크색 (밤하늘 다크 테마와 대비되는 따뜻한 종이 느낌).
  static const _paper = Color(0xFFFFF8E7);
  static const _paperEdge = Color(0xFFE8DCC3);
  static const _ink = Color(0xFF3B2F2A);
  static const _inkSoft = Color(0xFF7A6A5E);
  static const _gold = Color(0xFFB98A1F);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: _paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 닫기 버튼 (우상단).
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _inkSoft),
                  tooltip: '닫기',
                ),
              ),
              // 편지 본문 (스크롤 가능 — 작은 화면에서도 다 읽힌다).
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 상단 장식: 별 + 가는 선 (작명별 별 모티프).
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 18, color: _gold),
                          SizedBox(width: 8),
                          Icon(Icons.star, size: 12, color: _gold),
                          SizedBox(width: 8),
                          Icon(Icons.star, size: 18, color: _gold),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        color: _paperEdge,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _letterBody,
                        style: GoogleFonts.nanumPenScript(
                          fontSize: 22,
                          color: _ink,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _letterSignature,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.nanumPenScript(
                          fontSize: 22,
                          color: _ink,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        color: _paperEdge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '편지를 접어요',
                  style: GoogleFonts.nanumPenScript(
                    fontSize: 20,
                    color: _gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 편지 본문 (사용자가 준 원문 그대로, 2026-11-17).
const String _letterBody = '''나에게 우주를 보여준 한우주야,

네 이름을 지어주며 품었던 설렘과 사랑을 기억하면서, 아빠는 너를 생각하는 마음으로 이 작명 어플을 만들었단다. 엄마 아빠의 세상에 가장 눈부신 우주가 되어줘서 고마워.

사랑하는 윤경아,

소중한 우리 우주를 세상에 보여줘서, 그리고 언제나 내 곁에 있어줘서 고마워. 우주를 키우면서 힘든 날도 많겠지만 그럴 때마다 서로를 가장 먼저 다독이고 의지하면서 잘 이겨내보자.

앱 속 깊은 곳에 숨겨둔 이 작은 편지처럼, 우리 가족의 모든 날에도 반짝이는 행복이 가득하기를 바랄게.''';

/// 편지 맺음말 (우측 정렬).
const String _letterSignature = '''우리 가족, 언제나 사랑해.
2026.11.17 우주 아빠가''';
