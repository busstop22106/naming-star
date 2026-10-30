import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models.dart';
import 'screens/analyze_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.init();
  runApp(const JakmyeongbyeolApp());
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
  SharedBaby _baby = SharedBaby.initial();

  /// 랭킹 탭에서 분석으로 넘길 이름 요청 (소비되면 null로 되돌린다).
  String? _analyzeName;
  Gender? _analyzeGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        HomeScreen(
          baby: _baby,
          onBabyChanged: (b) => setState(() => _baby = b),
        ),
        AnalyzeScreen(
          baby: _baby,
          onBabyChanged: (b) => setState(() => _baby = b),
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
        const SettingsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
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
