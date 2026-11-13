import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models.dart';
import 'screens/analyze_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'services/baby_info_store.dart';
import 'services/purchase_service.dart';
import 'services/share_link.dart';
import 'theme.dart';
import 'widgets/night_sky.dart';

/// 공유 딥링크로 들어올 때 DetailScreen을 띄우는 네비게이터 키.
/// 링크는 MainNav의 initState보다 먼저 도착할 수 있어, context 대신
/// 이 키로 push한다.
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 기본 진단 출력은 유지하고, 추가로 로그를 남긴다.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    defaultOnError?.call(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  // AdMob 초기화가 실패하거나 끝나지 않아도 앱 진입은 보장한다.
  // (초기화 예외/무한 대기가 runApp을 막아 검은 화면이 되는 것을 방지)
  try {
    await AdService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('AdMob 초기화 실패 — 광고 없이 계속: $e');
  }
  // 인앱결제 초기화: 스토어 구매 내역으로 평생 광고 제거 권한을 복원한다.
  // 실패해도 앱 진입은 보장한다.
  try {
    await PurchaseService.instance.init().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('구매 서비스 초기화 실패 — 광고 제거 없이 계속: $e');
  }
  runZonedGuarded(
    () => runApp(const JakmyeongbyeolApp()),
    (error, stack) {
      debugPrint('미처리 오류: $error\n$stack');
    },
  );
}

class JakmyeongbyeolApp extends StatelessWidget {
  const JakmyeongbyeolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '작명별',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.theme,
      locale: const Locale('ko'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
      home: const MainNav(),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  /// 탭 간 공유하는 아기 기본 정보 — 한 탭에서 바꾸면 다른 탭에도 그대로 이어진다.
  /// 시작할 때 저장된 값을 복원하고, 바뀔 때마다 저장한다.
  SharedBaby _baby = SharedBaby.initial();

  @override
  void initState() {
    super.initState();
    _restoreBaby();
    _initDeepLinks();
  }

  /// 공유 딥링크 수신 — 앱이 꺼진 채로 열린 경우(getInitialLink)와
  /// 실행 중에 열린 경우(uriLinkStream)를 둘 다 받는다.
  /// 파싱·분석에 실패한 링크는 조용히 무시한다 (크래시 금지).
  StreamSubscription<Uri>? _linkSub;
  String? _lastHandledLink;

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    _linkSub = appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object e) => debugPrint('딥링크 수신 실패: $e'),
    );
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handleDeepLink(initial);
    } catch (e) {
      debugPrint('초기 딥링크 확인 실패: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    // 초기 링크가 스트림으로도 한 번 더 오는 경우가 있어 같은 링크는
    // 2초 안에는 한 번만 처리한다.
    final key = uri.toString();
    if (key == _lastHandledLink) return;
    _lastHandledLink = key;
    Future.delayed(const Duration(seconds: 2), () {
      if (_lastHandledLink == key) _lastHandledLink = null;
    });
    final params = parseShareUri(uri);
    if (params == null) return;
    final resolved = resolveSharedAnalysis(params);
    if (resolved == null) return;
    // 첫 프레임 전일 수 있으니 다음 프레임에 이동한다.
    // 전면 광고·RevealScreen은 거치지 않고 결과 화면으로 바로 간다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => DetailScreen(
            baby: resolved.baby,
            analysis: resolved.analysis,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _restoreBaby() async {
    final saved = await BabyInfoStore.load();
    if (saved != null && mounted) {
      setState(() => _baby = saved);
    }
  }

  void _onBabyChanged(SharedBaby baby) {
    setState(() => _baby = baby);
    // 저장 실패가 UI를 막지 않게 fire-and-forget.
    unawaited(BabyInfoStore.save(baby));
  }

  /// 랭킹 탭에서 분석으로 넘길 이름 요청 (소비되면 null로 되돌린다).
  String? _analyzeName;
  Gender? _analyzeGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // Starfield와 IndexedStack 모두 body 영역을 채움 (2026-11-13 리뷰 반영)
        children: [
          // 밤하늘 별빛 배경 — 4개 탭 공용 (2026-11-13, 별빛 단일화)
          const Starfield(),
          IndexedStack(index: _index, children: [
            HomeScreen(
              baby: _baby,
              onBabyChanged: _onBabyChanged,
            ),
            AnalyzeScreen(
              baby: _baby,
              onBabyChanged: _onBabyChanged,
              analyzeNameRequest: _analyzeName,
              analyzeGenderRequest: _analyzeGender,
              onAnalyzeNameConsumed: () => setState(() {
                _analyzeName = null;
                _analyzeGender = null;
              }),
            ),
            RankingScreen(
              onAnalyzeName: (name, gender) => setState(() {
                _index = 1;
                _analyzeName = name;
                _analyzeGender = gender;
              }),
            ),
            SettingsScreen(
                onGoToNaming: () => setState(() => _index = 0)),
          ]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primarySoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '이름 짓기',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '이름 분석',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: '랭킹',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
