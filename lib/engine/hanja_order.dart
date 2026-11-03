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
  // 뜻이 대부분 채워진 지금은 '뜻 있는 것 먼저'가 획수 순서를 깨뜨리기만
  // 하므로, 나머지는 획수 오름차순으로 단순화한다 (뜻 없는 자도 획수 순으로 섞인다).
  rest.sort((a, b) => a.strokes.compareTo(b.strokes));
  return [...curated, ...rest];
}

/// 한자 선택 검색 필터 (순수 함수)
/// - 빈 검색어면 전체를 그대로 돌려준다.
/// - 한자·뜻은 부분 일치, 획수는 '10' 또는 '10획' 정확 일치.
/// - 원래 순서 인덱스를 함께 유지해서 선택 상태가 필터링에 흔들리지 않는다.
List<MapEntry<int, HanjaPick>> filterHanjaOptions(
    List<HanjaPick> ordered, String query) {
  final all = ordered.asMap().entries.toList();
  final q = query.trim();
  if (q.isEmpty) return all;
  final digits = q.endsWith('획') ? q.substring(0, q.length - 1) : q;
  return all.where((e) {
    final h = e.value;
    return h.char.contains(q) ||
        h.meaning.contains(q) ||
        h.strokes.toString() == digits;
  }).toList();
}
