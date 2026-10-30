import '../data/hanja.dart';
import '../models.dart';
import 'hanja_order.dart';
import 'scoring.dart';

/// 이미 정한 한글 이름 2자(예: 도윤)에 쓸 한자 조합 중
/// 아기 사주 기준으로 종합 점수가 가장 높은 조합을 고른다.
/// 이름 분석 탭에서 한자를 일일이 고르지 않아도 되게 하는 자동 선택용.
///
/// 후보는 음절별 curated(추천 풀) 우선, 없으면 orderedHanja 상위 20자로
/// 제한해 조합 수를 최대 400개로 묶는다. 순수 함수 — 화면에서 분리됨.
({List<HanjaPick> picks, double total})? bestHanjaCombo({
  required String surname,
  required int surnameStrokes,
  required List<String> syllables, // 2자
  required SajuResult saju,
  required Gender gender,
}) {
  if (syllables.length != 2) return null;

  List<HanjaPick> candidates(String syllable) {
    final curated = hanjaBySyllable[syllable];
    if (curated != null && curated.isNotEmpty) return curated;
    return orderedHanja(syllable).take(20).toList();
  }

  final first = candidates(syllables[0]);
  final second = candidates(syllables[1]);
  if (first.isEmpty || second.isEmpty) return null;

  List<HanjaPick>? best;
  var bestTotal = -1.0;
  for (final a in first) {
    for (final b in second) {
      final picks = [a, b];
      final total = analyzeName(
        surname: surname,
        surnameStrokes: surnameStrokes,
        picks: picks,
        saju: saju,
        gender: gender,
      ).total;
      if (total > bestTotal) {
        bestTotal = total;
        best = picks;
      }
    }
  }
  if (best == null) return null;
  return (picks: best, total: bestTotal);
}
