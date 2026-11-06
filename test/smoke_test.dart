import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/generator.dart';
import 'package:jakmyeongbyeol/engine/saju.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/data/hanja.dart';
import 'package:jakmyeongbyeol/models.dart';

void main() {
  test('일주 기준일 검증: 2026-08-30 = 병자', () {
    final baby = BabyInfo(
      surname: '김', surnameStrokes: 8, gender: Gender.boy,
      birth: DateTime(2026, 8, 30), birthHour: 12, birthMinute: 0,
    );
    final saju = computeSaju(baby);
    // 리서치에서 검증된 값: 2026-08-30 = 병자일
    expect(saju.day.stem, '병');
    expect(saju.day.branch, '자');
  });

  test('연주 검증: 2026년 = 병오년', () {
    final baby = BabyInfo(
      surname: '김', surnameStrokes: 8, gender: Gender.boy,
      birth: DateTime(2026, 10, 19),
    );
    final saju = computeSaju(baby);
    expect(saju.year.stem, '병');
    expect(saju.year.branch, '오');
  });

  test('이름 분석 동작 확인: 김도윤', () {
    final baby = BabyInfo(
      surname: '김', surnameStrokes: 8, gender: Gender.boy,
      birth: DateTime(2026, 10, 19), birthHour: 10, birthMinute: 30,
    );
    final saju = computeSaju(baby);
    final bySyl = hanjaBySyllable;
    final analysis = analyzeName(
      surname: '김',
      surnameStrokes: 8,
      picks: [bySyl['도']!.first, bySyl['윤']!.first],
      saju: saju,
      gender: Gender.boy,
    );
    expect(analysis.total, inInclusiveRange(0, 100));
    expect(analysis.dimensions.length, 5);
    // ignore: avoid_print
    print('김도윤 종합: ${analysis.total.toStringAsFixed(1)}');
    for (final d in analysis.dimensions) {
      // ignore: avoid_print
      print('  ${d.title}: ${d.score.toStringAsFixed(0)} (${d.grade.label})');
    }
    // ignore: avoid_print
    print('용신: ${saju.yongsin}, 희신: ${saju.huishin}, 신강: ${saju.strongBody}');
  });

  test('이름 생성 동작 확인', () {
    final baby = BabyInfo(
      surname: '김', surnameStrokes: 8, gender: Gender.girl,
      birth: DateTime(2026, 10, 19), birthHour: 10, birthMinute: 30,
    );
    final saju = computeSaju(baby);
    final names = generateNames(baby, saju, limit: 10);
    expect(names.length, 10);
    expect(names.first.total, greaterThanOrEqualTo(names.last.total));
    // ignore: avoid_print
    print('여아 TOP3: ${names.take(3).map((n) => '${n.fullName}(${n.total.toStringAsFixed(0)})').join(', ')}');
  });
}
