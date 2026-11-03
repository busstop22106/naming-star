import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';
import 'favorites_flow_test.dart' show testAnalysis, testBaby;

void main() {
  testWidgets('일대기 뱃지는 한 줄로 보인다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: DetailScreen(baby: testBaby(), analysis: testAnalysis())));
    await tester.pumpAndSettle();
    // 뱃지는 시기 이름만 한 줄에 보인다. 나이 범위가 붙으면
    // 줄바꿈되거나 넘쳐서, 범위는 빼고 제목만 남긴다.
    for (final label in ['유년기', '청년기', '중년기', '말년기']) {
      final t = tester.widget<Text>(find.text(label));
      expect(t.softWrap, isFalse);
    }
    expect(find.text('청년기 · 13~29세'), findsNothing);
    expect(find.text('중년기 · 30~54세'), findsNothing);
  });
}
