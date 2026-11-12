import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models.dart';
import 'screens/analyze_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'services/baby_info_store.dart';
import 'theme.dart';

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
      body: IndexedStack(index: _index, children: [
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
