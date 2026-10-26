import 'package:flutter/material.dart';
import '../services/app_links.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'faq_screen.dart';
import 'favorites_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          const StarHero(
            title: '작명별',
            subtitle: '사주와 성명학으로 짓는 아기 이름',
            imageSize: 64,
          ),
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
                  builder: (_) =>
                      const FavoritesScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // 앱 설정
          _sectionTitle('앱 설정'),
          _menuTile(
            icon: Icons.language_outlined,
            title: '언어',
            subtitle: '한국어',
            onTap: _showLanguageInfo,
          ),
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
            onTap: null,
          ),
        ],
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
      '사주와 전통 성명학으로 아기 이름을 추천해주는 앱, 작명별\n${AppLinks.playStoreUrl}',
    );
    if (!ok && mounted) {
      _showFallback('공유하기를 열 수 없어요', AppLinks.playStoreUrl);
    }
  }

  void _showLanguageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('언어'),
        content: const Text('작명별은 현재 한국어만 지원해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppTheme.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(fontSize: 12))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right,
                color: AppTheme.sub)
            : null,
        onTap: onTap,
      ),
    );
  }

}
