import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/screens/settings_screen.dart';

void main() {
  testWidgets('설정 화면에 기기 변경·재설치 시 보관함 소실 안내가 보인다',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('기기를 바꾸거나 앱을 다시 설치하면 보관함이 사라져요.'),
      findsOneWidget,
    );
  });
}
