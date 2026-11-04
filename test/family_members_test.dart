import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/screens/analyze_screen.dart';
import 'package:jakmyeongbyeol/services/family_members.dart';

void main() {
  group('FamilyMemberInput JSON', () {
    test('시간 포함 구성원이 그대로 복원된다', () {
      final m = FamilyMemberInput('형 2', DateTime(2018, 3, 5),
          time: const TimeOfDay(hour: 14, minute: 30), timeUnknown: false);
      final back = FamilyMemberInput.tryFromJson(m.toJson())!;
      expect(back.role, '형 2');
      expect(back.birth, DateTime(2018, 3, 5));
      expect(back.time!.hour, 14);
      expect(back.time!.minute, 30);
      expect(back.timeUnknown, isFalse);
    });

    test('시간 모름 구성원이 그대로 복원된다', () {
      final m = FamilyMemberInput('할머니', DateTime(1955, 1, 1));
      final back = FamilyMemberInput.tryFromJson(m.toJson())!;
      expect(back.role, '할머니');
      expect(back.time, isNull);
      expect(back.timeUnknown, isTrue);
    });

    test('깨진 항목은 null을 돌려준다', () {
      expect(FamilyMemberInput.tryFromJson({'role': '', 'birth': 'x'}),
          isNull);
      expect(
          FamilyMemberInput.tryFromJson({'birth': '2020-01-01'}), isNull);
      expect(
          FamilyMemberInput.tryFromJson(
              {'role': '아빠', 'birth': '2020-01-01', 'hour': 25, 'minute': 0}),
          isNull);
    });
  });

  group('가족 구성원 저장/불러오기', () {
    test('저장한 목록이 그대로 불러와진다', () async {
      SharedPreferences.setMockInitialValues({});
      await saveFamilyMembers([
        FamilyMemberInput('아빠', DateTime(1990, 5, 5)),
        FamilyMemberInput('엄마', DateTime(1992, 7, 7),
            time: const TimeOfDay(hour: 9, minute: 0), timeUnknown: false),
      ]);
      final loaded = await loadFamilyMembers();
      expect(loaded.length, 2);
      expect(loaded[0].role, '아빠');
      expect(loaded[1].time!.hour, 9);
    });

    test('깨진 저장값은 빈 목록으로, 기본값으로 돌아간다', () async {
      SharedPreferences.setMockInitialValues(
          {'jakmyeongbyeol_family_members': 'not-json[['});
      expect(await loadFamilyMembers(), isEmpty);
    });

    test('목록 중 깨진 항목만 건너뛰고 나머지는 살린다', () async {
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_family_members': jsonEncode([
          {'role': '아빠', 'birth': '1990-05-05T00:00:00.000'},
          {'role': '', 'birth': 'x'},
          {'role': '할머니', 'birth': '1955-01-01T00:00:00.000'},
        ]),
      });
      final loaded = await loadFamilyMembers();
      expect(loaded.map((m) => m.role).toList(), ['아빠', '할머니']);
    });

    test('6명을 넘기면 6명까지만 불러온다', () async {
      SharedPreferences.setMockInitialValues({});
      await saveFamilyMembers(List.generate(
          8, (i) => FamilyMemberInput('동생 $i', DateTime(2020, 1, 1))));
      expect((await loadFamilyMembers()).length, 6);
    });
  });

  group('이름 분석 화면 복원', () {
    testWidgets('저장된 구성원이 앱 재시작 후에도 가족 카드에 보인다',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_family_members': jsonEncode([
          {'role': '할아버지', 'birth': '1955-01-01T00:00:00.000'},
          {'role': '엄마', 'birth': '1992-07-07T00:00:00.000'},
        ]),
      });
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: AnalyzeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('가족 궁합'));
      await tester.pumpAndSettle();
      // 저장된 구성원이 기본값(아빠·엄마)을 대체한다.
      expect(find.text('할아버지'), findsOneWidget);
      expect(find.text('아빠'), findsNothing);
    });
  });
}
