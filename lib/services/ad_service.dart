import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 광고 관리
/// - 디버그 빌드: Google 공식 테스트 ID 사용
/// - 릴리즈(Android): 실제 광고 단위 ID (2026-10-22 AdMob 등록 완료)
/// - 릴리즈(iOS): 실제 ID 미발급 상태라 테스트 ID 유지 (iOS 출시 시 교체)
/// 배너가 표시되는 화면 위치 (화면별 광고 단위 분리용)
enum AdPlacement { home, analyze, ranking }

class AdService {
  /// 배너 노출 위치 플래그.
  /// 출시 초기 모객을 위해 랭킹 탭에만 배너를 둔다.
  /// 나중에 다시 노출할 때는 배너 위젯을 다시 붙일 필요 없이
  /// 아래 값만 true로 바꾸면 된다 (광고 단위 ID는 그대로 유지).
  static const Map<AdPlacement, bool> bannerEnabled = {
    AdPlacement.home: false,
    AdPlacement.analyze: false,
    AdPlacement.ranking: true,
  };

  static bool bannerEnabledFor(AdPlacement placement) =>
      bannerEnabled[placement] ?? false;

  static String get bannerAdUnitId => bannerAdUnitIdFor(AdPlacement.home);

  static String bannerAdUnitIdFor(AdPlacement placement) {
    if (kDebugMode) {
      return _testBannerId;
    }
    if (Platform.isAndroid) {
      switch (placement) {
        case AdPlacement.analyze:
          return 'ca-app-pub-2198921607879570/9461880362';
        case AdPlacement.ranking:
          return 'ca-app-pub-2198921607879570/2623467280';
        case AdPlacement.home:
          return 'ca-app-pub-2198921607879570/5516707015';
      }
    }
    return _testBannerId;
  }

  static String get _testBannerId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }
}

/// 하단 배너 광고 위젯
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, this.placement = AdPlacement.home});

  final AdPlacement placement;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdService.bannerAdUnitIdFor(widget.placement);
    if (adUnitId.isEmpty) return;
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
