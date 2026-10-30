import 'package:flutter/material.dart';
import '../theme.dart';

/// 자주 묻는 질문 (앱 내 화면)
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    (
      q: '작명별은 어떤 앱인가요?',
      a: '사주(四柱)와 전통 성명학으로 아기 이름을 추천·분석해주는 앱이에요. '
          '이름 짓기(한자·순우리말), 이름 분석, 연도별 인기 이름 랭킹, 보관함 기능을 무료로 쓸 수 있어요.',
    ),
    (
      q: '이름 점수는 어떻게 계산되나요?',
      a: '수리(35%)·사주 보완(25%)·발음(20%)·음양(10%)·사용성(10%) 다섯 가지 기준을 100점 만점으로 합산해요. '
          '수리는 81수리의 길흉을 보고, 사주 보완은 아기의 일주(日柱)를 기준으로 부족한 오행을 채워주는지를 봐요.',
    ),
    (
      q: '사주 분석이 정확한가요?',
      a: '앱의 사주는 간이 만세력으로 계산한 참고용 결과예요. 출생 시간이 정확하지 않거나(모름으로 입력 가능) '
          '세밀한 해석이 필요하면 전문가 상담을 권해드려요. 재미와 참고용으로 가볍게 활용해주세요.',
    ),
    (
      q: '순우리말 이름도 지을 수 있나요?',
      a: '네. 한자 없이 한글 이름 후보를 추천하고, 한글 자모의 획수와 초성의 오행으로 간이 분석을 해줘요.',
    ),
    (
      q: '랭킹은 어떤 자료인가요?',
      a: '법원 전자가족관계등록시스템에서 발표한 연도별 남녀 아기 이름 TOP 20을 2016년부터 2025년까지 담았어요. '
          '연도를 바꿔가며 이름 트렌드가 어떻게 변했는지 볼 수 있어요.',
    ),
    (
      q: '광고가 나오는데 없앨 수 있나요?',
      a: '작명별은 모든 기능을 무료로 제공하기 위해 랭킹 탭 하단에 작은 배너 광고를 보여줘요. '
          '현재는 광고 제거 옵션이 없어요.',
    ),
    (
      q: '입력한 정보가 서버로 전송되나요?',
      a: '아니요. 이름·생년월일시 등 입력한 정보와 보관함은 이용자의 기기 안에서만 처리·저장되고 외부 서버로 전송되지 않아요. '
          '광고 제공을 위한 Google AdMob의 자동 수집(광고 ID 등)에 대한 내용은 개인정보처리방침에서 확인할 수 있어요.',
    ),
    (
      q: '저장한 이름은 어디서 보나요?',
      a: '마음에 드는 이름은 상세 화면에서 저장해두면, 설정 → 보관함에서 언제든 다시 볼 수 있어요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자주 묻는 질문')),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
        itemCount: _faqs.length,
        itemBuilder: (context, i) {
          final item = _faqs[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                item.q,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink),
              ),
              iconColor: AppTheme.primary,
              collapsedIconColor: AppTheme.sub,
              children: [
                Padding(
                  // 상단 여백이 0이면 펼치는 애니메이션 중에
                  // 첫 줄이 잘려 보이는 것처럼 느껴진다.
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    item.a,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.ink, height: 1.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
