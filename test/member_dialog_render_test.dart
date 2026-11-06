import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/theme.dart';
import 'package:jakmyeongbyeol/widgets/hanja_picker_sheet.dart';
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

  // 한자 ChoiceChip 라벨 색상: 테스트 안에서 만든 칩이 아니라 실제
  // HanjaPickerSheet를 펌프해서 선택/미선택 칩의 라벨 색상을 확인한다.
  // (예전에는 테스트 안에서 직접 만든 ChoiceChip에 색상을 하드코딩한 뒤
  // assert하는 자기충족 테스트라, 실제 칩 색상이 깨져도 실패하지 않았다.)
  testWidgets('한자 ChoiceChip label 색상이 명시되어 있다', (tester) async {
    final opts = orderedHanja('윤');
    final runIdx = opts.indexWhere((o) => o.char == '潤');
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: SizedBox(
          height: 1200,
          child: HanjaPickerSheet(
            syllable: '윤',
            options: opts,
            selectedIndex: runIdx,
            onSelected: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // 칩 라벨은 RichText(한자 span + 부가정보 span)라서 전체 문장으로 찾는다.
    Finder richTextContaining(String s) => find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains(s));
    // 선택된 칩(潤): 루트 TextSpan 색이 primaryDark
    final selected =
        tester.widget<RichText>(richTextContaining('潤 젖을 16획'));
    expect((selected.text as TextSpan).style?.color,
        AppTheme.primaryDark);
    // 미선택 칩(㣧): 루트 TextSpan 색이 ink
    final unselected =
        tester.widget<RichText>(richTextContaining('㣧 뜻없음 11획'));
    expect((unselected.text as TextSpan).style?.color, AppTheme.ink);
  });
}
