import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/screens/analyze_screen.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';

void main() {
  testWidgets('순우리말 모드에서 한글 2자 입력 시 분석이 진행돼야 함', (tester) async {
    // 긴 폼이 한 화면에 다 들어오도록 뷰포트를 크게 설정
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AnalyzeScreen()));

    // 순우리말 모드 선택
    await tester.tap(find.text('순우리말'));
    await tester.pumpAndSettle();

    // 이름 2자 입력
    await tester.enterText(find.byType(TextField), '하늘');
    await tester.pumpAndSettle();

    // 분석 버튼 탭
    await tester.tap(find.text('이 이름으로 분석하기'));
    await tester.pumpAndSettle();

    // 오류 토스트가 없고 상세 화면으로 이동했는지 확인
    expect(find.text('한글 2자로 입력해주세요.'), findsNothing);
    expect(find.byType(DetailScreen), findsOneWidget);
  });
}
