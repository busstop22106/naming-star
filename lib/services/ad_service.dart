import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'adfree_service.dart';

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
    // 디버그·프로필 빌드는 Google 공식 테스트 ID를 쓴다.
    // (프로필 빌드도 실제 광고 ID가 나가면 안 된다.)
    if (kDebugMode || kProfileMode) {
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

  /// 전면(인터스티셜) 광고 단위 ID.
  /// 디버그·프로필 빌드는 Google 공식 테스트 ID, 릴리즈 Android는 실제 ID.
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _releaseInterstitialId =
      'ca-app-pub-2198921607879570/5708799197';

  static String get interstitialAdUnitId {
    if (kDebugMode || kProfileMode) {
      return _testInterstitialId;
    }
    if (Platform.isAndroid) {
      return _releaseInterstitialId;
    }
    return _testInterstitialId;
  }

  static InterstitialAd? _interstitialAd;
  static bool _interstitialLoading = false;

  /// 미리 로드된 전면 광고가 있는지 여부.
  static bool get isInterstitialReady => _interstitialAd != null;

  /// 전면 광고를 미리 로드한다. 이미 로드됐거나 로딩 중이면 바로 반환한다.
  /// 로드 실패 시 재시도 타이머를 두지 않는다. 다음 로드 기회
  /// (다음 표시 시도, 앱 시작 시 init)에 다시 시도한다.
  static Future<void> loadInterstitialAd() async {
    if (_interstitialAd != null || _interstitialLoading) return;
    _interstitialLoading = true;
    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialLoading = false;
          },
          onAdFailedToLoad: (error) {
            // 로드 실패 시에는 광고 객체가 만들어지지 않으므로 dispose할
            // 대상이 없다. 다음 로드 기회에 다시 시도한다.
            _interstitialAd = null;
            _interstitialLoading = false;
          },
        ),
      );
    } catch (_) {
      _interstitialAd = null;
      _interstitialLoading = false;
    }
  }

  /// 준비된 전면 광고를 보여준다. 광고가 닫힐 때까지 기다린 뒤 true를 반환한다.
  /// 광고가 준비돼 있지 않으면 다음 차례를 위해 로드를 한 번 걸어두고
  /// false를 반환한다. 표시 실패 시에도 false를 반환한다.
  /// 광고는 한 번만 보여준다 (보여준 뒤에는 다음 광고를 미리 로드한다).
  static Future<bool> showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) {
      unawaited(loadInterstitialAd());
      return false;
    }
    _interstitialAd = null;
    final completer = Completer<bool>();
    void finish(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish(true);
        unawaited(loadInterstitialAd());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        finish(false);
        unawaited(loadInterstitialAd());
      },
    );
    try {
      await ad.show();
    } catch (_) {
      ad.dispose();
      unawaited(loadInterstitialAd());
      return false;
    }
    return completer.future;
  }

  static Future<void> init() async {
    await MobileAds.instance.initialize();
    unawaited(loadInterstitialAd());
    unawaited(loadRewardedAd());
  }

  /// 보상형 광고 단위 ID.
  /// 디버그·프로필 빌드는 Google 공식 테스트 ID, 릴리즈 Android는 실제 ID.
  /// TODO(사용자: AdMob 콘솔에서 보상형 광고 단위를 생성한 뒤
  /// _releaseRewardedId를 실제 ID로 교체할 것).
  /// 교체 전에는 릴리즈에서 로드가 실패하고, 1위 결과는 가려진 채로 둔다.
  static const String _testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _releaseRewardedId =
      'TODO_REPLACE_WITH_REAL_REWARDED_AD_UNIT_ID';

  static String get rewardedAdUnitId {
    if (kDebugMode || kProfileMode) {
      return _testRewardedId;
    }
    if (Platform.isAndroid) {
      return _releaseRewardedId;
    }
    return _testRewardedId;
  }

  static RewardedAd? _rewardedAd;
  static bool _rewardedLoading = false;

  /// 미리 로드된 보상형 광고가 있는지 여부.
  static bool get isRewardedReady => _rewardedAd != null;

  /// 보상형 광고를 미리 로드한다. 이미 로드됐거나 로딩 중이면 바로 반환한다.
  static Future<void> loadRewardedAd() async {
    if (_rewardedAd != null || _rewardedLoading) return;
    _rewardedLoading = true;
    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedLoading = false;
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _rewardedLoading = false;
          },
        ),
      );
    } catch (_) {
      _rewardedAd = null;
      _rewardedLoading = false;
    }
  }

  /// 준비된 보상형 광고를 보여준다. 끝까지 봐서 보상을 받으면
  /// [RewardedAdResult.earned], 보상 없이 닫히면 dismissed,
  /// 광고가 준비되지 않았거나 표시에 실패하면 unavailable을 반환한다.
  /// 광고는 한 번만 보여준다 (보여준 뒤에는 다음 광고를 미리 로드한다).
  static Future<RewardedAdResult> showRewardedAd() async {
    final ad = _rewardedAd;
    if (ad == null) {
      unawaited(loadRewardedAd());
      return RewardedAdResult.unavailable;
    }
    _rewardedAd = null;
    var earned = false;
    final completer = Completer<RewardedAdResult>();
    void finish(RewardedAdResult value) {
      if (!completer.isCompleted) completer.complete(value);
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish(
            earned ? RewardedAdResult.earned : RewardedAdResult.dismissed);
        unawaited(loadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        finish(RewardedAdResult.unavailable);
        unawaited(loadRewardedAd());
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } catch (_) {
      ad.dispose();
      unawaited(loadRewardedAd());
      return RewardedAdResult.unavailable;
    }
    return completer.future;
  }
}

/// 보상형 광고 시청 결과.
enum RewardedAdResult {
  /// 끝까지 봐서 보상을 받음.
  earned,

  /// 보상 없이 닫음.
  dismissed,

  /// 광고가 준비되지 않았거나 표시에 실패함.
  unavailable,
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

  /// 로드 실패 재시도 상태. 랭킹 화면은 IndexedStack에 상주해
  /// initState가 세션당 1회만 실행되므로, 실패 시 여기서 직접 재시도한다.
  int _retryCount = 0;
  Timer? _retryTimer;
  static const _maxRetries = 3;
  static const _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  @override
  void initState() {
    super.initState();
    AdFreeService.instance.isAdFreeNotifier.addListener(_onAdFreeChanged);
    if (!AdFreeService.instance.isAdFree) {
      _loadAd();
    }
  }

  /// 평생 광고 제거를 구매하면 로드된 배너를 버리고 다시 로드하지 않는다.
  void _onAdFreeChanged() {
    if (!AdFreeService.instance.isAdFree) return;
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) {
      setState(() => _loaded = false);
    }
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
          if (mounted) {
            setState(() {
              _loaded = true;
              _retryCount = 0;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
          _scheduleRetry();
        },
      ),
    )..load();
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;
    final delay = _retryDelays[_retryCount];
    _retryCount++;
    _retryTimer = Timer(delay, () {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    AdFreeService.instance.isAdFreeNotifier.removeListener(_onAdFreeChanged);
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 평생 광고 제거 상태면 배너를 만들지 않는다.
    if (AdFreeService.instance.isAdFree) {
      return const SizedBox.shrink();
    }
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
