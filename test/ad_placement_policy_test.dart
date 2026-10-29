import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/services/ad_service.dart';

void main() {
  test('출시 초기 광고 정책: 배너는 랭킹 탭에만 노출한다', () {
    // 이름 짓기·이름 분석 배너는 플래그로 꺼져 있고,
    // 다시 켤 때는 이 플래그만 바꾸면 된다.
    expect(AdService.bannerEnabledFor(AdPlacement.home), isFalse);
    expect(AdService.bannerEnabledFor(AdPlacement.analyze), isFalse);
    expect(AdService.bannerEnabledFor(AdPlacement.ranking), isTrue);
  });

  test('모든 위치가 플래그 맵에 있어 플래그만으로 재노출할 수 있다', () {
    // 배너 위젯·광고 단위 코드를 지운 게 아니라 플래그로만 껐으므로,
    // 재노출 시 코드를 다시 붙일 필요 없이 값만 바꾸면 된다.
    expect(AdService.bannerEnabled.keys.toSet(),
        {AdPlacement.home, AdPlacement.analyze, AdPlacement.ranking});
  });
}
