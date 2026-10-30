import '../data/hanja.dart';
import '../data/hanja_full.dart';
import '../models.dart';

/// 음절의 전체 한자를 curated 우선으로 정렬
///
/// curated(추천 풀)에 있는 한자를 curated 순서대로 먼저, 나머지는
/// 뜻이 있는 한자를 먼저·획수 오름차순으로 뒤에 배치한다.
/// 뜻 없는 한자를 무심코 고르는 일을 줄이기 위한 순서이며,
/// 첫 번째 항목(기본 선택)은 curated 순서라 바뀌지 않는다.
/// 순수 함수 — 화면에서 분리됨.
List<HanjaPick> orderedHanja(String syllable) {
  final full = hanjaFullBySyllable[syllable] ?? [];
  final curatedOrder =
      hanjaBySyllable[syllable]?.map((e) => e.char).toList() ?? [];
  final curatedSet = curatedOrder.toSet();
  final curated =
      full.where((e) => curatedSet.contains(e.char)).toList();
  final rest =
      full.where((e) => !curatedSet.contains(e.char)).toList();
  curated.sort((a, b) => curatedOrder
      .indexOf(a.char)
      .compareTo(curatedOrder.indexOf(b.char)));
  rest.sort((a, b) {
    final aHas = a.meaning.isNotEmpty ? 0 : 1;
    final bHas = b.meaning.isNotEmpty ? 0 : 1;
    if (aHas != bHas) return aHas.compareTo(bHas);
    return a.strokes.compareTo(b.strokes);
  });
  return [...curated, ...rest];
}
