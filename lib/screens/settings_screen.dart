import 'dart:async';

import 'package:flutter/material.dart';
import '../services/adfree_service.dart';
import '../services/app_links.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
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

            // 광고 없이 사용하기
            _sectionTitle('광고 없이 사용하기'),
            const _AdFreeSection(),
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

/// 평생 광고 제거(₩4,900) 구매 섹션.
/// - 구매 전: 설명 + 구매 버튼(스토어 가격) + 구매 복원하기 버튼.
/// - 구매 후: "평생 유료 멤버쉽 적용됐어요" 표시 (버튼 아님, 그냥 문구).
/// 구매·복원은 버튼을 눌렀을 때만 시작한다.
class _AdFreeSection extends StatefulWidget {
  const _AdFreeSection();

  @override
  State<_AdFreeSection> createState() => _AdFreeSectionState();
}

class _AdFreeSectionState extends State<_AdFreeSection> {
  @override
  void initState() {
    super.initState();
    AdFreeService.instance.isAdFreeNotifier.addListener(_rebuild);
    PurchaseService.instance.priceNotifier.addListener(_rebuild);
    PurchaseService.instance.busyNotifier.addListener(_rebuild);
    PurchaseService.instance.productsAvailableNotifier.addListener(_rebuild);
    PurchaseService.instance.productsCheckedNotifier.addListener(_rebuild);
    PurchaseService.instance.errorNotifier.addListener(_onPurchaseError);
    unawaited(PurchaseService.instance.refreshProducts());
  }

  @override
  void dispose() {
    AdFreeService.instance.isAdFreeNotifier.removeListener(_rebuild);
    PurchaseService.instance.priceNotifier.removeListener(_rebuild);
    PurchaseService.instance.busyNotifier.removeListener(_rebuild);
    PurchaseService.instance.productsAvailableNotifier
        .removeListener(_rebuild);
    PurchaseService.instance.productsCheckedNotifier.removeListener(_rebuild);
    PurchaseService.instance.errorNotifier.removeListener(_onPurchaseError);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onPurchaseError() {
    final error = PurchaseService.instance.errorNotifier.value;
    if (error == null || !mounted) return;
    PurchaseService.instance.errorNotifier.value = null;
    showSingleSnackBar(ScaffoldMessenger.of(context), error);
  }

  Future<void> _restore() async {
    final ok = await PurchaseService.instance.restore();
    if (!mounted) return;
    showSingleSnackBar(
      ScaffoldMessenger.of(context),
      ok ? '구매를 복원했어요.' : '복원할 구매가 없어요.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdFree = AdFreeService.instance.isAdFree;
    final busy = PurchaseService.instance.isBusy;
    final productsAvailable = PurchaseService.instance.productsAvailable;
    final productsChecked =
        PurchaseService.instance.productsCheckedNotifier.value;
    final price = PurchaseService.instance.price;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppTheme.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isAdFree
                          ? Icons.check_circle
                          : Icons.block_outlined,
                      size: 20,
                      color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAdFree ? '평생 유료 멤버쉽 적용됐어요' : '평생 광고 없이 사용하기',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isAdFree
                  ? '배너·전면 광고 없이 사용하고 있어요. 1위 결과도 항상 바로 볼 수 있어요.'
                  : '한 번 결제하면 평생 배너·전면 광고 없이 사용하고, 1위 결과도 항상 바로 볼 수 있어요.',
              style: const TextStyle(fontSize: 13, color: AppTheme.sub),
            ),
            if (!isAdFree) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy || (productsChecked && !productsAvailable)
                      ? null
                      : () => PurchaseService.instance.buyAdFree(),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('평생 광고 없이 사용하기 · $price'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: busy ? null : _restore,
                  child: const Text('이미 구입하셨나요? 구매 복원하기'),
                ),
              ),
              if (productsChecked && !productsAvailable)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      '상품 정보를 불러오지 못했어요. 스토어에 상품을 등록한 뒤 다시 시도해 주세요.',
                      style: TextStyle(fontSize: 12, color: AppTheme.sub)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
