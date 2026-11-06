import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// 보관함 저장소
class FavoriteItem {
  final BabyInfo baby;
  final List<HanjaPick> picks;
  final double total;
  final DateTime savedAt;

  FavoriteItem({
    required this.baby,
    required this.picks,
    required this.total,
    required this.savedAt,
  });

  String get fullName => '${baby.surname}${picks.map((p) => p.syllable).join()}';
  String get hanjaName => picks.map((p) => p.char).join();

  Map<String, dynamic> toJson() => {
        'baby': baby.toJson(),
        'picks': picks.map((p) => p.toJson()).toList(),
        'total': total,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> j) => FavoriteItem(
        baby: BabyInfo.fromJson(j['baby'] as Map<String, dynamic>),
        picks: (j['picks'] as List)
            .map((e) => HanjaPick.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (j['total'] as num).toDouble(),
        savedAt: DateTime.parse(j['savedAt'] as String),
      );

  /// 파싱에 실패한 항목은 null을 돌려준다 — 불러올 때 그 항목만 건너뛴다.
  static FavoriteItem? tryFromJson(Map<String, dynamic> j) {
    try {
      final babyRaw = j['baby'];
      final picksRaw = j['picks'];
      final totalRaw = j['total'];
      final savedAtRaw = j['savedAt'];
      if (babyRaw is! Map<String, dynamic>) return null;
      if (picksRaw is! List) return null;
      if (totalRaw is! num) return null;
      if (savedAtRaw is! String) return null;
      final baby = BabyInfo.tryFromJson(babyRaw);
      if (baby == null) return null;
      final picks = <HanjaPick>[];
      for (final e in picksRaw) {
        if (e is! Map<String, dynamic>) return null;
        final pick = HanjaPick.tryFromJson(e);
        if (pick == null) return null;
        picks.add(pick);
      }
      return FavoriteItem(
        baby: baby,
        picks: picks,
        total: totalRaw.toDouble(),
        savedAt: DateTime.parse(savedAtRaw),
      );
    } catch (_) {
      return null;
    }
  }
}

/// 저장 형식 스키마 버전. 구버전은 항목만 담은 bare list였고,
/// v1부터는 {'version': 1, 'items': [...]} 형태다.
const _schemaVersion = 1;

const _key = 'jakmyeongbyeol_favorites';

/// 보관함 최대 개수. 100개를 넘으면 가장 오래된 항목부터 빠진다.
const _maxFavorites = 100;

/// 저장소에서 읽은 원본 상태.
/// - corrupt: 최상위 JSON 자체가 깨져 항목을 하나도 신뢰할 수 없음.
///   이 경우 저장 함수는 원본을 덮지 않는다 (손상된 원본 보존).
/// - unparseable: 항목별 파싱에 실패한 원본 JSON 조각. 저장할 때
///   그대로 되돌려 넣어, 깨진 항목 하나 때문에 나머지를 잃지 않는다.
class _StoredFavorites {
  final List<FavoriteItem> items;
  final List<dynamic> unparseable;
  final bool corrupt;

  // const 생성자가 아니다 — 저장 함수가 items를 바꿔야 하므로
  // 빈 리스트도 가변 리스트여야 한다.
  _StoredFavorites({
    required this.items,
    required this.unparseable,
    required this.corrupt,
  });
}

Future<_StoredFavorites> _loadStored() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_key);
  if (raw == null) {
    return _StoredFavorites(items: [], unparseable: [], corrupt: false);
  }
  try {
    final decoded = jsonDecode(raw);
    final List<dynamic> entries;
    if (decoded is Map<String, dynamic>) {
      final itemsRaw = decoded['items'];
      if (decoded['version'] != _schemaVersion || itemsRaw is! List) {
        return _StoredFavorites(
            items: [], unparseable: [], corrupt: true);
      }
      entries = itemsRaw;
    } else if (decoded is List) {
      // 구버전 bare list 형식 — 그대로 읽는다.
      entries = decoded;
    } else {
      return _StoredFavorites(items: [], unparseable: [], corrupt: true);
    }
    final items = <FavoriteItem>[];
    final unparseable = <dynamic>[];
    for (final e in entries) {
      if (e is Map<String, dynamic>) {
        final item = FavoriteItem.tryFromJson(e);
        if (item != null) {
          items.add(item);
        } else {
          unparseable.add(e);
        }
      } else {
        unparseable.add(e);
      }
    }
    return _StoredFavorites(
        items: items, unparseable: unparseable, corrupt: false);
  } catch (_) {
    return _StoredFavorites(items: [], unparseable: [], corrupt: true);
  }
}

/// 정상 항목 + 파싱 실패한 원본 조각을 스키마 버전과 함께 저장한다.
/// 저장 성공 여부를 반환한다 — 호출처가 실패를 사용자에게 알려야 한다.
Future<bool> _writeStored(
    List<FavoriteItem> items, List<dynamic> unparseable) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.setString(
    _key,
    jsonEncode({
      'version': _schemaVersion,
      'items': [
        ...items.map((e) => e.toJson()),
        ...unparseable,
      ],
    }),
  );
}

Future<List<FavoriteItem>> loadFavorites() async {
  return (await _loadStored()).items;
}

/// 저장 성공 여부를 반환한다. 저장값이 깨져 있거나 쓰기가 실패하면 false.
Future<bool> saveFavorite(FavoriteItem item) async {
  final stored = await _loadStored();
  // 저장값이 통째로 깨진 상태면 덮지 않는다 — 손상된 원본을 보존한다.
  if (stored.corrupt) return false;
  final items = stored.items;
  // 같은 이름+한자 중복 제거
  items.removeWhere((e) =>
      e.fullName == item.fullName && e.hanjaName == item.hanjaName);
  // 상한을 넘으면 가장 오래된 항목부터 빠진다.
  while (items.length >= _maxFavorites) {
    items.removeLast();
  }
  items.insert(0, item);
  return _writeStored(items, stored.unparseable);
}

Future<bool> removeFavorite(FavoriteItem item) async {
  final stored = await _loadStored();
  if (stored.corrupt) return false;
  final items = stored.items;
  items.removeWhere((e) =>
      e.fullName == item.fullName && e.hanjaName == item.hanjaName);
  return _writeStored(items, stored.unparseable);
}

Future<bool> isFavorite(String fullName, String hanjaName) async {
  final items = await loadFavorites();
  return items.any(
      (e) => e.fullName == fullName && e.hanjaName == hanjaName);
}

/// 보관함 전체를 교체한다 — 삭제 실행 취소 때 원래 순서 그대로 되돌리기 위함.
Future<bool> replaceFavorites(List<FavoriteItem> items) async {
  final stored = await _loadStored();
  if (stored.corrupt) return false;
  return _writeStored(items, stored.unparseable);
}
