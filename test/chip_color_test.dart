import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/theme.dart';
import 'package:jakmyeongbyeol/widgets/hanja_picker_sheet.dart';
import 'package:jakmyeongbyeol/widgets/surname_picker.dart';

/// ChoiceChip 라벨 색상 규칙 (AGENTS.md):
/// 선택: primaryDark, 미선택: ink, 체크: primaryDark.
/// 세 곳의 칩(한자 시트·성씨 퀵칩·역할 칩)은 모두 체크 표시를 끄고
/// 테두리로 선택을 표시하므로, 체크 색상은 렌더링되지 않는다.
/// 이 파일은 실제 위젯을 펌프해서 선택/미선택 라벨 색상과
/// 테두리·체크 표시 여부를 확인한다. (역할 칩은 chip_hint_test.dart에서 다룬다.)

/// 칩 라벨은 RichText(한자 span + 부가정보 span)라서 전체 문장으로 찾는다.
Finder richTextContaining(String s) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(s));

void main() {
  group('한자 칩 (HanjaPickerSheet)', () {
    // '윤'의 한자: 㣧 11획(뜻없음), 䦞 15획(뜻없음), 潤 16획(젖을).
    final yoonOpts = orderedHanja('윤');
    final runIdx = yoonOpts.indexWhere((o) => o.char == '潤');

    Future<void> pumpSheet(WidgetTester tester) async {
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
              options: yoonOpts,
              selectedIndex: runIdx,
              onSelected: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('선택 칩 라벨은 primaryDark, 미선택 칩 라벨은 ink이다',
        (tester) async {
      await pumpSheet(tester);
      // 루트 TextSpan 색이 라벨 색상이다 (부가정보 span은 별도 색상).
      final selected =
          tester.widget<RichText>(richTextContaining('潤 젖을 16획'));
      expect((selected.text as TextSpan).style?.color,
          AppTheme.primaryDark);
      final unselected =
          tester.widget<RichText>(richTextContaining('㣧 뜻없음 11획'));
      expect((unselected.text as TextSpan).style?.color, AppTheme.ink);
    });

    testWidgets('한자 칩은 체크 표시 없이 테두리로 선택을 표시한다',
        (tester) async {
      await pumpSheet(tester);
      final chips = find.byType(ChoiceChip);
      expect(chips, findsWidgets);
      for (final e in chips.evaluate()) {
        expect((e.widget as ChoiceChip).showCheckmark, isFalse);
      }
      // 선택 칩은 진한 테두리 1.5, 미선택 칩은 연한 테두리 1.
      ChoiceChip chipOf(String label) {
        final rich = find.ancestor(
            of: richTextContaining(label),
            matching: find.byType(ChoiceChip));
        return tester.widget<ChoiceChip>(rich);
      }

      final selected = chipOf('潤 젖을 16획');
      expect(selected.selected, isTrue);
      expect(selected.side?.color, AppTheme.primary);
      expect(selected.side?.width, 1.5);
      final unselected = chipOf('㣧 뜻없음 11획');
      expect(unselected.selected, isFalse);
      expect(unselected.side?.color, AppTheme.chipBorder);
      expect(unselected.side?.width, 1);
    });
  });

  group('성씨 퀵칩 (showSurnamePicker)', () {
    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () async {
                await showSurnamePicker(
                  context,
                  const SurnamePick(
                      name: '김', hanja: '金', strokes: 8),
                );
              },
              child: const Text('열기'),
            );
          }),
        ),
      ));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
    }

    /// 퀵칩 라벨 Text가 'name'인 ChoiceChip을 찾는다.
    /// (목록 행에도 같은 성씨 Text가 있어 find.text로는 구분이 안 된다.)
    ChoiceChip quickChip(WidgetTester tester, String name) {
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      return chips.firstWhere((c) => (c.label as Text).data == name);
    }

    testWidgets('선택된 성씨 퀵칩 라벨은 primaryDark, 나머지는 ink이다',
        (tester) async {
      await pumpSheet(tester);
      expect((quickChip(tester, '김').label as Text).style?.color,
          AppTheme.primaryDark);
      expect((quickChip(tester, '이').label as Text).style?.color,
          AppTheme.ink);
    });

    testWidgets('성씨 퀵칩은 체크 표시 없이 테두리로 선택을 표시한다',
        (tester) async {
      await pumpSheet(tester);
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips, isNotEmpty);
      for (final c in chips) {
        expect(c.showCheckmark, isFalse);
      }
      final selected = quickChip(tester, '김');
      expect(selected.selected, isTrue);
      expect(selected.side?.color, AppTheme.primary);
      expect(selected.side?.width, 1.5);
      final unselected = quickChip(tester, '이');
      expect(unselected.selected, isFalse);
      expect(unselected.side?.color, AppTheme.chipBorder);
      expect(unselected.side?.width, 1);
    });
  });
}
