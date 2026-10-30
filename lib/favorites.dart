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
}

const _key = 'jakmyeongbyeol_favorites';

Future<List<FavoriteItem>> loadFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_key);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveFavorite(FavoriteItem item) async {
  final prefs = await SharedPreferences.getInstance();
  final items = await loadFavorites();
  // 같은 이름+한자 중복 제거
  items.removeWhere((e) =>
      e.fullName == item.fullName && e.hanjaName == item.hanjaName);
  items.insert(0, item);
  await prefs.setString(
      _key, jsonEncode(items.map((e) => e.toJson()).toList()));
}

Future<void> removeFavorite(FavoriteItem item) async {
  final prefs = await SharedPreferences.getInstance();
  final items = await loadFavorites();
  items.removeWhere((e) =>
      e.fullName == item.fullName && e.hanjaName == item.hanjaName);
  await prefs.setString(
      _key, jsonEncode(items.map((e) => e.toJson()).toList()));
}

Future<bool> isFavorite(String fullName, String hanjaName) async {
  final items = await loadFavorites();
  return items.any(
      (e) => e.fullName == fullName && e.hanjaName == hanjaName);
}

/// 보관함 전체를 교체한다 — 삭제 실행 취소 때 원래 순서 그대로 되돌리기 위함.
Future<void> replaceFavorites(List<FavoriteItem> items) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      _key, jsonEncode(items.map((e) => e.toJson()).toList()));
}
