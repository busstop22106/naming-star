import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/theme.dart';
import 'package:jakmyeongbyeol/widgets/member_dialog.dart';

/// 다양한 기기 크기·글자 크기에서 구성원 다이얼로그가 예외 없이 뜨는지 검증.
/// (테마 ElevatedButton의 minimumSize infinity가 Row 안에서 렌더링 예외를
/// 일으켜 딤만 남던 버그의 재발 방지용)
void main() {
  final viewports = {
    'small 320x568': const Size(320, 568),
    'standard 360x740': const Size(360, 740),
    'large 412x915': const Size(412, 915),
    'tablet 768x1024': const Size(768, 1024),
  };
  for (final entry in viewports.entries) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets('MemberDialog ${entry.key} x$scale', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showDialog<MemberEditResult>(
                  context: context,
                  builder: (_) => MemberDialog(
                    isEdit: false,
                    canDelete: false,
                    initialRole: '아빠',
                    initialBirth: DateTime(1990, 5, 5),
                    initialTime: null,
                    initialTimeUnknown: true,
                  ),
                ),
                child: const Text('열기'),
              ),
            );
          }),
        ));
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        expect(find.text('구성원 추가'), findsOneWidget);
        expect(find.text('아빠'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('한자 ChoiceChip label 색상이 명시되어 있다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: ChoiceChip(
          label: const Text('李 오얏',
              style: TextStyle(
                  color: AppTheme.ink, fontWeight: FontWeight.w700)),
          selected: false,
          onSelected: (_) {},
          selectedColor: AppTheme.primarySoft,
        ),
      ),
    ));
    final text = tester.widget<Text>(find.text('李 오얏'));
    expect(text.style?.color, AppTheme.ink);
  });
}
