import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/favorites.dart';
import 'package:jakmyeongbyeol/models.dart';

/// 보관함 상한(100개)과 쓰기 결과 확인:
/// 101개를 저장하면 가장 오래된 1개가 빠지고 100개가 유지되며,
/// saveFavorite은 성공 여부를 bool로 돌려준다.

FavoriteItem itemAt(int i) => FavoriteItem(
      baby: BabyInfo(
        surname: '김',
        surnameHanja: '金',
        surnameStrokes: 8,
        gender: Gender.boy,
        birth: DateTime(2024, 3, 10),
      ),
      picks: [
        const HanjaPick(
            syllable: '도', char: '度', meaning: '헤아릴', strokes: 9, element: '토'),
        HanjaPick(
            syllable: '윤',
            char: String.fromCharCode(0x4E00 + i),
            meaning: '뜻',
            strokes: 5,
            element: '수'),
      ],
      total: 80.0,
      savedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
    );

void main() {
  test('101개를 저장하면 가장 오래된 1개가 빠지고 100개가 유지된다', () async {
    SharedPreferences.setMockInitialValues({});
    for (var i = 0; i <= 100; i++) {
      expect(await saveFavorite(itemAt(i)), isTrue);
    }
    final loaded = await loadFavorites();
    expect(loaded, hasLength(100));
    // 가장 최근(i=100)이 맨 앞, 가장 오래된(i=0)은 빠졌다.
    expect(loaded.first.hanjaName, itemAt(100).hanjaName);
    expect(loaded.last.hanjaName, itemAt(1).hanjaName);
    expect(loaded.any((e) => e.hanjaName == itemAt(0).hanjaName), isFalse);
  });
}
