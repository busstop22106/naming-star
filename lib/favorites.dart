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
///   이 경우 저장 함수는 원본을 백업 키에 옮기고 새로 시작한다
///   (깨진 채로 두면 저장이 영원히 안 되는 교착에 빠진다, 2026-11-17).
/// - readFailed: 저장소를 아예 못 읽음(일시적 I/O 오류 등).
///   데이터가 깨진 게 아니라 읽기에 실패한 것이므로, 저장 함수는
///   덮지 않고 false를 돌려준다 — 정상 데이터를 빈 목록으로
///   덮어버리는 데이터 손실을 막기 위함 (오푸스 리뷰, 2026-11-17).
/// - unparseable: 항목별 파싱에 실패한 원본 JSON 조각. 저장할 때
///   그대로 되돌려 넣어, 깨진 항목 하나 때문에 나머지를 잃지 않는다.
class _StoredFavorites {
  final List<FavoriteItem> items;
  final List<dynamic> unparseable;
  final bool corrupt;
  final bool readFailed;
  // 손상된 원본 JSON 문자열 (백업용). 깨지지 않았으면 null.
  final String? raw;

  // const 생성자가 아니다 — 저장 함수가 items를 바꿔야 하므로
  // 빈 리스트도 가변 리스트여야 한다.
  _StoredFavorites({
    required this.items,
    required this.unparseable,
    required this.corrupt,
    this.readFailed = false,
    this.raw,
  });
}

/// 손상된 저장값을 백업 키에 옮긴다 — 복구 시 참고용으로 남긴다.
/// 백업 자체가 실패해도 저장은 계속 진행한다.
Future<void> _backupCorruptRaw(String? raw) async {
  if (raw == null) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_key}_corrupt_backup', raw);
  } catch (_) {
    // 백업 실패는 저장 실패 사유가 아니다.
  }
}

Future<_StoredFavorites> _loadStored() async {
  // SharedPreferences 자체를 못 읽어도 던지지 않는다 — 호출처가
  // 빈 목록으로 보고 빈 화면을 보여주게 한다 (오류 화면 대신).
  // (2026-11-17: 저장값이 깨지면 불러오기 오류 화면만 뜨고
  // 저장이 영원히 안 되는 교착이 실기기에서 재현됐다.)
  String? raw;
  try {
    final prefs = await SharedPreferences.getInstance();
    raw = prefs.getString(_key);
  } catch (_) {
    // 저장소를 못 읽음 — 데이터 손상과 다르니 덮지 않게 readFailed로 구분한다.
    return _StoredFavorites(
        items: [], unparseable: [], corrupt: false, readFailed: true);
  }
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
            items: [], unparseable: [], corrupt: true, raw: raw);
      }
      entries = itemsRaw;
    } else if (decoded is List) {
      // 구버전 bare list 형식 — 그대로 읽는다.
      entries = decoded;
    } else {
      return _StoredFavorites(
          items: [], unparseable: [], corrupt: true, raw: raw);
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
    return _StoredFavorites(
        items: [], unparseable: [], corrupt: true, raw: raw);
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
  // _loadStored는 예외를 던지지 않으니 빈 목록이면 빈 화면이 뜬다.
  return (await _loadStored()).items;
}

/// 저장 성공 여부를 반환한다. 저장값이 깨져 있으면 원본을 백업하고
/// 새로 시작한다 — 깨진 채로 두면 저장이 영원히 안 된다 (2026-11-17).
/// 저장소를 못 읽었으면(readFailed) 덮지 않고 false를 돌려준다
/// (정상 데이터를 날릴 수 있다. 오푸스 리뷰, 2026-11-17).
/// 쓰기 자체가 실패하면 false.
Future<bool> saveFavorite(FavoriteItem item) async {
  final stored = await _loadStored();
  if (stored.readFailed) return false;
  if (stored.corrupt) await _backupCorruptRaw(stored.raw);
  final items = stored.corrupt ? <FavoriteItem>[] : stored.items;
  final unparseable = stored.corrupt ? <dynamic>[] : stored.unparseable;
  // 같은 이름+한자 중복 제거
  items.removeWhere((e) =>
      e.fullName == item.fullName && e.hanjaName == item.hanjaName);
  // 상한을 넘으면 가장 오래된 항목부터 빠진다.
  while (items.length >= _maxFavorites) {
    items.removeLast();
  }
  items.insert(0, item);
  return _writeStored(items, unparseable);
}

Future<bool> removeFavorite(FavoriteItem item) async {
  final stored = await _loadStored();
  if (stored.readFailed) return false;
  if (stored.corrupt) await _backupCorruptRaw(stored.raw);
  final items = stored.corrupt ? <FavoriteItem>[] : stored.items;
  final unparseable = stored.corrupt ? <dynamic>[] : stored.unparseable;
  items.removeWhere((e) =>
      e.fullName == item.fullName && e.hanjaName == item.hanjaName);
  return _writeStored(items, unparseable);
}

Future<bool> isFavorite(String fullName, String hanjaName) async {
  final items = await loadFavorites();
  return items.any(
      (e) => e.fullName == fullName && e.hanjaName == hanjaName);
}

/// 보관함 전체를 교체한다 — 삭제 실행 취소 때 원래 순서 그대로 되돌리기 위함.
/// 저장값이 깨져 있으면 원본을 백업하고 주어진 목록으로 새로 쓴다.
/// 저장소를 못 읽었으면 덮지 않고 false를 돌려준다.
Future<bool> replaceFavorites(List<FavoriteItem> items) async {
  final stored = await _loadStored();
  if (stored.readFailed) return false;
  if (stored.corrupt) await _backupCorruptRaw(stored.raw);
  final unparseable = stored.corrupt ? <dynamic>[] : stored.unparseable;
  return _writeStored(items, unparseable);
}
