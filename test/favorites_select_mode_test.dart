import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/favorites.dart';
import 'package:jakmyeongbyeol/screens/favorites_screen.dart';
import 'favorites_flow_test.dart' show testBaby, testPicks;

void main() {
  testWidgets('선택 모드에서는 카드를 탭하면 상세로 가지 않고 항목을 돌려준다',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final item = FavoriteItem(
      baby: testBaby(),
      picks: testPicks(),
      total: 91.0,
      savedAt: DateTime(2026, 11, 3, 16, 30),
    );
    await saveFavorite(item);

    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    FavoriteItem? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              picked = await Navigator.of(ctx).push<FavoriteItem>(
                MaterialPageRoute(
                  builder: (_) =>
                      const FavoritesScreen(selectMode: true),
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('김도윤'), findsOneWidget);
    await tester.tap(find.text('김도윤'));
    await tester.pumpAndSettle();
    // 상세 화면이 아니라 버튼 페이지로 돌아오고, 항목이 전달됐다.
    expect(find.text('열기'), findsOneWidget);
    expect(picked?.fullName, '김도윤');
    expect(picked?.hanjaName, '度潤');
  });
}
