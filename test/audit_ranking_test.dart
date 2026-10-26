import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/data/rankings.dart';

void main() {
  test('최신 랭킹 연도 확인', () {
    // ignore: avoid_print
    print('rankingYears: $rankingYears');
    // ignore: avoid_print
    print('latestRankingYear: $latestRankingYear');
    expect(latestRankingYear, 2025);
    // 2025년 1위 남자 이름이 실제 데이터와 맞는지 (대조용 출력)
    // ignore: avoid_print
    print('2025 boy #1: ${rankingsByYear[2025]?.boy.first.name}');
  });
}
