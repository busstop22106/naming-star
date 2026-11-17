import 'dart:async';

import 'package:flutter/material.dart';
import '../services/adfree_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import 'adfree_price_label.dart';
import 'common.dart';

/// 평생 광고 제거(₩4,900) 구매 섹션.
/// - 구매 전: 설명 + 구매 버튼(스토어 가격) + 구매 복원하기 버튼.
/// - 구매 후: "평생 광고 없이 사용 적용됐어요" 표시 (버튼 아님, 그냥 문구).
/// 구매·복원은 버튼을 눌렀을 때만 시작한다.
/// settings_screen.dart의 _AdFreeSection을 공용 위젯으로 분리했다 (2026-11-17).
class AdFreeSection extends StatefulWidget {
  const AdFreeSection({super.key});

  @override
  State<AdFreeSection> createState() => _AdFreeSectionState();
}

class _AdFreeSectionState extends State<AdFreeSection> {
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
    final result = await PurchaseService.instance.restore();
    if (!mounted) return;
    // 복원할 구매가 없을 때와 스토어 연결·타임아웃으로 실패했을 때를
    // 구분해 안내한다 (2026-11-16).
    showSingleSnackBar(
      ScaffoldMessenger.of(context),
      switch (result) {
        RestoreResult.restored => '구매를 복원했어요.',
        RestoreResult.none => '복원할 구매가 없어요.',
        RestoreResult.failed => '스토어 연결이 느려요. 다시 시도해 주세요.',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdFree = AdFreeService.instance.isAdFree;
    final busy = PurchaseService.instance.isBusy;
    final productsAvailable = PurchaseService.instance.productsAvailable;
    final productsChecked =
        PurchaseService.instance.productsCheckedNotifier.value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleIcon(
                    icon: isAdFree
                        ? Icons.check_circle
                        : Icons.block_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAdFree ? '평생 광고 없이 사용 적용됐어요' : '평생 광고 없이 사용',
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
                      : const AdFreePriceLabel(
                          prefix: '평생 광고 없이 사용 · '),
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
                      '상품 정보를 불러오지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.',
                      style: TextStyle(fontSize: 12, color: AppTheme.sub)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
