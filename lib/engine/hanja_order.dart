import '../data/hanja.dart';
import '../data/hanja_full.dart';
import '../models.dart';

/// 음절의 전체 한자를 curated 우선으로 정렬
///
/// curated(추천 풀)에 있는 한자를 curated 순서대로 먼저, 나머지는
/// 획수 오름차순으로 뒤에 배치한다. 순수 함수 — 화면에서 분리됨.
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
  rest.sort((a, b) => a.strokes.compareTo(b.strokes));
  return [...curated, ...rest];
}
