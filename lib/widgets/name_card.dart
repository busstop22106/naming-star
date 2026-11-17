import 'package:flutter/material.dart';
import '../data/pure_korean_names.dart';
import '../engine/reason_line.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// 추천 이름 카드 — 저장은 상세 화면에서만 한다 (카드 북마크는 2026-10-30 제거).
/// [masked]가 true면 1위 이름·점수를 '???'로 가리고 자물쇠를 보여준다.
/// (한자·뜻·근거 문구는 이름을 유추할 수 있어 함께 숨긴다.)
/// recommend_screen.dart의 _NameCard를 공용 위젯으로 분리했다 (2026-11-17).
/// baby 인자는 build에서 쓰지 않아 빼었다.
class NameCard extends StatelessWidget {
  final int rank;
  final NameAnalysis analysis;
  final bool masked;
  final VoidCallback onTap;
  const NameCard({
    super.key,
    required this.rank,
    required this.analysis,
    this.masked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    // 스크롤 버벅임 방지: 카드별 래스터 캐시를 만들어 스크롤 중 재그리기를 막는다.
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('$rank',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          // 금색 #FFC53D는 흰 배경 1.58:1로 순위 숫자에 쓸 수
                          // 없어 진한 primaryDark로 바꿨다. 금색은 별·아이콘
                          // 같은 큰 그래픽 요소에만 쓴다.
                          color: rank <= 3
                              ? AppTheme.primaryDark
                              : AppTheme.sub)),
                ),
                Expanded(
                  child: masked
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('???',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 14, color: AppTheme.sub),
                                SizedBox(width: 4),
                                Text('탭해서 1위 이름 확인하기',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.sub,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(a.fullName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 8),
                                if (a.isPureKorean)
                                  Flexible(
                                    child: Text(
                                        pureKoreanMeaning(a.givenName) ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.sub)),
                                  )
                                else
                                  Flexible(
                                    child: Text(a.hanjaName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.sub)),
                                  ),
                                if (a.rankBoy != null ||
                                    a.rankGirl != null) ...[
                                  const SizedBox(width: 6),
                                  const GradeChip('흔한 이름', AppTheme.warn),
                                ],
                              ],
                            ),
                            // 한자 뜻 — 리스트에서 뜻을 모르고 일일이 눌러보지 않게 한다.
                            if (!a.isPureKorean &&
                                a.picks.any(
                                    (p) => p.meaning.isNotEmpty)) ...[
                              const SizedBox(height: 4),
                              Text(
                                a.picks
                                    .map((p) => p.meaning.isNotEmpty
                                        ? '${p.char} ${p.meaning}'
                                        : '${p.char} 뜻없음')
                                    .join(' · '),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.sub,
                                    fontFamilyFallback:
                                        AppTheme.hanjaFontFallback),
                              ),
                            ],
                            // 추천 근거 한 줄 — 점수가 뒷받침하는 이유만 문장으로 쓴다.
                            const SizedBox(height: 4),
                            Text(
                              recommendReason(a),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              children: a.dimensions.map((d) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.scoreColor(d.score),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(d.title,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.sub)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
                if (masked)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primarySoft,
                    ),
                    child: const Icon(Icons.lock_outline,
                        size: 28, color: AppTheme.gold),
                  )
                else
                  ScoreRing(score: a.total, size: 64, strokeWidth: 7),
                const Icon(Icons.chevron_right, color: AppTheme.sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
