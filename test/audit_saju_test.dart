import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/saju.dart';
import 'package:jakmyeongbyeol/models.dart';

BabyInfo b(int y, int m, int d, [int? h]) => BabyInfo(
      surname: '김', surnameHanja: '金', surnameStrokes: 8,
      gender: Gender.boy, birth: DateTime(y, m, d),
      birthHour: h, birthMinute: 0,
    );

void main() {
  test('연주 기준: 2024 갑진, 2025 을사, 2026 병오, 입춘 전은 전년', () {
    expect(computeSaju(b(2024, 3, 10)).year.stem, '갑');
    expect(computeSaju(b(2024, 3, 10)).year.branch, '진');
    expect(computeSaju(b(2025, 6, 1)).year.stem, '을');
    expect(computeSaju(b(2026, 6, 1)).year.stem, '병');
    expect(computeSaju(b(2024, 2, 3)).year.branch, '묘'); // 입춘 전 = 계묘년
    expect(computeSaju(b(2024, 2, 4)).year.branch, '진');
  });
  test('기준일 2000-01-01 = 무오일', () {
    final s = computeSaju(b(2000, 1, 1));
    expect(s.day.stem, '무');
    expect(s.day.branch, '오');
  });
  test('월주 절기 경계: 1월 초는 자월이어야 한다', () {
    // 2024-01-03은 소한(1/6) 이전 = 자월(전년도 12월 절기)
    final s = computeSaju(b(2024, 1, 3));
    // ignore: avoid_print
    print('2024-01-03 month branch: ${s.month.branch} (expect 자)');
    expect(s.month.branch, '자');
  });
  test('월주 표준: 2024년 3월 경칩 이후는 묘월, 정월은 병인월(갑년)', () {
    final s = computeSaju(b(2024, 3, 10));
    expect(s.month.branch, '묘');
    final s2 = computeSaju(b(2024, 2, 10)); // 입춘 이후 인월
    expect(s2.month.stem, '병');
    expect(s2.month.branch, '인');
  });
  test('시주 오자둔법: 23시는 다음날 일간 기준 (무오 다음날 기미일 자시는 갑자)', () {
    final s = computeSaju(b(2000, 1, 1, 23));
    expect(s.day.stem, '기'); // 다음날 기미일
    expect(s.hour?.stem, '갑');
    expect(s.hour?.branch, '자');
  });
  test('1월 초 월간: 2024-01-03은 계묘년 갑자월', () {
    final s = computeSaju(b(2024, 1, 3));
    expect(s.month.branch, '자');
    expect(s.month.stem, '갑');
  });

  test('월간 전월 대조: 갑년 해월 을해, 자월 병자, 축월 정축', () {
    expect(computeSaju(b(2024, 11, 10)).month.stem, '을'); // 갑년 해월
    expect(computeSaju(b(2024, 11, 10)).month.branch, '해');
    expect(computeSaju(b(2024, 12, 10)).month.stem, '병'); // 갑년 자월
    expect(computeSaju(b(2024, 12, 10)).month.branch, '자');
    expect(computeSaju(b(2025, 1, 10)).month.stem, '정'); // 갑년 축월
    expect(computeSaju(b(2025, 1, 10)).month.branch, '축');
  });
}
