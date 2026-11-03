import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';
import 'favorites_flow_test.dart' show testAnalysis, testBaby;

void main() {
  testWidgets('뜻 없는 한자는 한자 바꾸기에서 뜻없음으로 보인다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // 화면을 길게 잡아 한자 바꾸기 섹션까지 한 번에 빌드되게 한다.
    tester.view.physicalSize = const Size(390, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: DetailScreen(baby: testBaby(), analysis: testAnalysis())));
    await tester.pumpAndSettle();
    // '윤'의 뜻 없는 한자: 㣧 11획, 䦞 15획 (다른 음에도 같은 획수가 있어 복수).
    expect(find.text('뜻없음 · 11획'), findsWidgets);
    expect(find.text('뜻없음 · 15획'), findsWidgets);
  });
}
