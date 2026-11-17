import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_links.dart';
import '../theme.dart';
import '../widgets/adfree_section.dart';
import '../widgets/common.dart';
import '../widgets/easter_egg_letter_dialog.dart';
import 'faq_screen.dart';
import 'favorites_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  /// 보관함 빈 화면 '이름 지으러 가기'를 눌렀을 때 이름 짓기 탭으로
  /// 보내는 콜백. MainNav에서 내려준다.
  final VoidCallback? onGoToNaming;
  const SettingsScreen({super.key, this.onGoToNaming});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// 이스터에그: 앱 버전 연속 탭 횟수 (안드로이드 개발자 메뉴 해제 방식).
  /// 10회 연속 탭하면 우주 아빠의 편지를 보여준다 (2026-11-17).
  int _versionTapCount = 0;
  DateTime? _lastVersionTapTime;

  @override
  void initState() {
    super.initState();
    // 편지 손글씨(동글)를 미리 내려받는다 — 팝업이 뜰 때 기본 폰트에서
    // 손글씨로 바뀌는 깜빡임을 막는다 (2026-11-17).
    // 호출 자체가 다운로드를 시작한다 (이미 받아져 있으면 아무 일도 안 한다).
    GoogleFonts.dongle();
  }

  /// 편지 손글씨 폰트가 준비될 때까지 기다린다.
  /// 이미 받아져 있으면 즉시 끝나고, 네트워크가 느리면 최대 2초만 기다린다.
  /// 준비에 실패하면 기본 폰트로 팝업을 띄운다 (깜빡임 대신 기본 폰트 유지).
  Future<void> _waitForLetterFont() async {
    try {
      await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 2));
    } catch (_) {
      // 무시하고 기본 폰트로 진행한다.
    }
  }

  Future<void> _onVersionTap() async {
    final now = DateTime.now();
    // 2초 넘게 쉬면 연속 탭이 끊긴 것으로 보고 처음부터 센다.
    if (_lastVersionTapTime != null &&
        now.difference(_lastVersionTapTime!).inMilliseconds > 2000) {
      _versionTapCount = 0;
    }
    _lastVersionTapTime = now;
    _versionTapCount++;
    // 첫 탭에서 손글씨 다운로드를 한 번 더 시작한다 — initState 때
    // 네트워크가 안 돼서 실패했다면 여기서 다시 시도한다 (2026-11-17).
    if (_versionTapCount == 1) GoogleFonts.dongle();
    // 1~5회 탭은 조용히 센다.
    if (_versionTapCount < 6) return;
    if (_versionTapCount < 10) {
      // 6회 탭부터 카운트다운 토스트 (5, 4, 3, 2번 남음).
      final messenger = ScaffoldMessenger.of(context);
      showSingleSnackBar(
        messenger,
        '${11 - _versionTapCount}번 남았습니다',
        duration: const Duration(seconds: 1),
        persist: false,
      );
      return;
    }
    // 10회 탭: '1번 남았습니다' 토스트를 보여주고 곧 편지를 띄운다.
    _versionTapCount = 0;
    _lastVersionTapTime = null;
    final messenger = ScaffoldMessenger.of(context);
    showSingleSnackBar(
      messenger,
      '1번 남았습니다',
      duration: const Duration(milliseconds: 800),
      persist: false,
    );
    // 토스트를 볼 시간과 손글씨 준비를 함께 기다린다 —
    // 폰트가 안 된 채로 팝업을 띄우면 기본 폰트에서 손글씨로
    // 바뀌는 깜빡임이 생긴다 (2026-11-17).
    // 지연은 1000ms: 토스트 표시 800ms + 사라지는 애니메이션(~200ms)이
    // 끝난 뒤 팝업을 띄워 토스트와 팝업이 겹치지 않게 한다 (오푸스 리뷰 5차).
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1000)),
      _waitForLetterFont(),
    ]);
    if (!mounted) return;
    await showEasterEggLetterDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경은 MainNav의 Starfield가 담당한다 (2026-11-13, 별빛 단일화).
      backgroundColor: Colors.transparent,
      body: SafeArea(
        // 하단 inset은 ListView 패딩이 처리한다 (2026-11-13 리뷰 반영).
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom),
          children: [
            // 헤더 — appHeader(부제목은 탭마다 다름)
            appHeader('소중히 모아둔 이름과 앱 환경을 관리해요'),
            const SizedBox(height: 20),
            // 내 정보
            _sectionTitle('저장한 이름'),
            _menuTile(
              icon: Icons.bookmark_border,
              title: '보관함',
              subtitle: '저장한 이름 목록',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FavoritesScreen(
                        onGoToNaming: widget.onGoToNaming)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 4),
              child: Text(
                '기기를 바꾸거나 앱을 다시 설치하면 보관함이 사라져요.',
                style: TextStyle(fontSize: 12, color: AppTheme.sub),
              ),
            ),
            const SizedBox(height: 16),

            // 광고 없이 사용
            _sectionTitle('광고 없이 사용'),
            const AdFreeSection(),
            const SizedBox(height: 16),

            // 지원
            _sectionTitle('지원'),
            _menuTile(
              icon: Icons.help_outline,
              title: '자주 묻는 질문',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FaqScreen()),
              ),
            ),
            _menuTile(
              icon: Icons.mail_outline,
              title: '문의하기',
              subtitle: AppLinks.contactEmail,
              onTap: _openEmail,
            ),
            _menuTile(
              icon: Icons.star_outline,
              title: '앱 평가하기',
              subtitle: 'Play 스토어에서 별점 남기기',
              onTap: _openStore,
            ),
            _menuTile(
              icon: Icons.share_outlined,
              title: '친구에게 공유하기',
              onTap: _shareApp,
            ),
            const SizedBox(height: 16),

            // 정보
            _sectionTitle('정보'),
            _menuTile(
              icon: Icons.description_outlined,
              title: '이용약관',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TermsScreen()),
              ),
            ),
            _menuTile(
              icon: Icons.privacy_tip_outlined,
              title: '개인정보처리방침',
              onTap: _openPrivacyPolicy,
            ),
            _menuTile(
              icon: Icons.info_outline,
              title: '앱 버전',
              subtitle: '1.0.0',
              onTap: _onVersionTap,
              // 정보만 보여주는 라벨처럼 보이게: chevron도, 터치 물결 효과도 없다.
              // (탭은 이스터에그 10회 연속 탭용으로 그대로 동작한다, 2026-11-17)
              isLabel: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final ok = await AppLinks.openUrl(AppLinks.privacyPolicyUrl);
    if (!ok && mounted) {
      _showFallback('페이지를 열 수 없어요', AppLinks.privacyPolicyUrl);
    }
  }

  Future<void> _openEmail() async {
    final ok = await AppLinks.sendEmail(subject: '[작명별 문의]');
    if (!ok && mounted) {
      _showFallback('메일 앱을 열 수 없어요', AppLinks.contactEmail);
    }
  }

  Future<void> _openStore() async {
    final ok = await AppLinks.openUrl(AppLinks.playStoreUrl);
    if (!ok && mounted) {
      _showFallback('스토어를 열 수 없어요', AppLinks.playStoreUrl);
    }
  }

  Future<void> _shareApp() async {
    final ok = await AppLinks.shareText(
      '👶 철학관 안 가고 끝내는 정통 사주 아기 작명! 우리 아이 사주에 부족한 오행을 채워줄 이름을 작명별로 찾아보세요. ✨\n${AppLinks.playStoreUrl}',
    );
    if (!ok && mounted) {
      _showFallback('공유하기를 열 수 없어요', AppLinks.playStoreUrl);
    }
  }

  void _showFallback(String message, String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message\n$value'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.sub,
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    // true면 정보 라벨처럼 보인다 — chevron을 안 붙이고 터치 물결 효과도
    // 제거한다. onTap은 그대로 동작한다 (이스터에그용, 2026-11-17).
    bool isLabel = false,
  }) {
    final tile = ListTile(
      leading: CircleIcon(icon: icon),
      title: Text(title,
          style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: (onTap != null && !isLabel)
          ? const Icon(Icons.chevron_right, color: AppTheme.sub)
          : null,
      onTap: onTap,
    );
    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: tile,
    );
    if (!isLabel) return card;
    // 터치 물결(ripple)·눌림 하이라이트를 투명하게 해 라벨처럼 보이게 한다.
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: card,
    );
  }

}
