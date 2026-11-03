import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/favorites.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/favorites_screen.dart';

void main() {
  testWidgets('보관함 삭제 토스트는 3초 뒤에 사라진다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final item = FavoriteItem(
      baby: BabyInfo(
        surname: '한',
        surnameHanja: '韓',
        surnameStrokes: 17,
        gender: Gender.boy,
        birth: DateTime(2024, 7, 11),
      ),
      picks: [
        orderedHanja('지').firstWhere((p) => p.char == '志'),
        orderedHanja('민').firstWhere((p) => p.char == '旻'),
      ],
      total: 91,
      savedAt: DateTime.now(),
    );
    await saveFavorite(item);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: FavoritesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('보관함에서 삭제했어요.'), findsOneWidget);

    // 3초가 지나면 퇴장 애니메이션이 시작되고, 제거는 그 다음
    // 프레임에서 일어나서 pump 한 번으로는 안 끝난다.
    // settle까지 돌려야 완전히 사라진다.
    // (액션이 있으면 persist 기본값이 true라 duration만으로는
    // 안 사라진다 — persist: false를 명시한 것이 이 테스트의 전제다.)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('보관함에서 삭제했어요.'), findsNothing);
  });
}
