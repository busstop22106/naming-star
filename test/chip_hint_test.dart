import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/theme.dart';
import 'package:jakmyeongbyeol/widgets/member_dialog.dart';

void main() {
  testWidgets('역할 칩 라벨이 명시적 색상으로 보인다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => showDialog<MemberEditResult>(
              context: context,
              builder: (_) => MemberDialog(
                isEdit: false,
                canDelete: false,
                initialRole: '형',
                initialBirth: DateTime(2021, 3, 5),
                initialTime: null,
                initialTimeUnknown: true,
              ),
            ),
            child: const Text('열기'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    // 선택된 역할 칩은 진한 바이올렛, 미선택 칩은 잉크색
    final selected = tester.widget<Text>(find.text('형'));
    expect(selected.style?.color, AppTheme.primaryDark);
    final unselected = tester.widget<Text>(find.text('아빠'));
    expect(unselected.style?.color, AppTheme.ink);
  });

  test('입력 힌트는 밝은 회색이다', () {
    expect(AppTheme.theme.inputDecorationTheme.hintStyle?.color,
        AppTheme.hint);
  });

  testWidgets('역할 칩은 체크 표시 없이 테두리로 선택을 표시한다',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => showDialog<MemberEditResult>(
              context: context,
              builder: (_) => MemberDialog(
                isEdit: false,
                canDelete: false,
                initialRole: '형',
                initialBirth: DateTime(2021, 3, 5),
                initialTime: null,
                initialTimeUnknown: true,
              ),
            ),
            child: const Text('열기'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    final chips = find.byType(ChoiceChip);
    expect(chips, findsWidgets);
    // 모든 역할 칩에 체크 표시가 없다 (라벨이 늘어나지 않음).
    for (final e in chips.evaluate()) {
      expect((e.widget as ChoiceChip).showCheckmark, isFalse);
    }
    // 선택된 칩은 진한 테두리, 미선택 칩은 연한 테두리.
    final selected = tester.widget<ChoiceChip>(find.ancestor(
        of: find.text('형'), matching: find.byType(ChoiceChip)));
    expect(selected.side?.color, AppTheme.primary);
    final unselected = tester.widget<ChoiceChip>(find.ancestor(
        of: find.text('아빠'), matching: find.byType(ChoiceChip)));
    expect(unselected.side?.color, AppTheme.chipBorder);
  });
}
