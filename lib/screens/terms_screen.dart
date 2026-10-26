import 'package:flutter/material.dart';
import '../services/app_links.dart';
import '../theme.dart';

/// 이용약관 (앱 내 화면)
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    (
      title: '제1조 (목적)',
      body: '이 약관은 작명별(이하 "서비스")의 이용 조건과 절차, '
          '서비스 제공자와 이용자의 권리·의무를 정하는 것을 목적으로 합니다.',
    ),
    (
      title: '제2조 (용어의 정의)',
      body: '① "서비스"란 사주와 전통 성명학을 바탕으로 아기 이름을 추천·분석하고, '
          '연도별 인기 이름 랭킹과 보관함 기능을 제공하는 모바일 애플리케이션을 말합니다.\n'
          '② "이용자"란 서비스를 설치하고 이용하는 사람을 말합니다.',
    ),
    (
      title: '제3조 (서비스의 내용)',
      body: '서비스는 다음 기능을 무료로 제공합니다.\n'
          '· 이름 짓기: 한자 이름 및 순우리말 이름 후보 추천\n'
          '· 이름 분석: 수리·사주 보완·발음·음양·사용성 5차원 점수 분석\n'
          '· 가족 궁합: 구성원 사주를 바탕으로 한 가족 궁합 분석\n'
          '· 랭킹: 연도별 남녀 아기 이름 TOP 20\n'
          '· 보관함: 마음에 드는 이름 저장 및 다시 보기',
    ),
    (
      title: '제4조 (정보의 처리)',
      body: '이용자가 입력한 이름·생년월일시 등 정보와 보관함 내용은 이용자의 기기 안에서만 '
          '처리·저장되며, 서비스 제공자의 서버로 전송되지 않습니다. '
          '광고 제공을 위한 Google AdMob의 자동 수집(광고 ID 등)에 대해서는 '
          '개인정보처리방침에서 확인할 수 있습니다.',
    ),
    (
      title: '제5조 (이용자의 의무)',
      body: '이용자는 서비스를 이용하면서 다음 행위를 해서는 안 됩니다.\n'
          '· 서비스를 역설계하거나 비정상적인 방법으로 접근하는 행위\n'
          '· 타인의 권리를 침해하거나 법령에 위반되는 용도로 서비스를 이용하는 행위\n'
          '· 서비스의 정상적인 운영을 방해하는 행위',
    ),
    (
      title: '제6조 (광고)',
      body: '서비스는 모든 기능을 무료로 제공하기 위해 화면 하단에 배너 광고를 표시합니다. '
          '광고를 통해 표시되는 제3자의 상품·서비스에 대해서는 해당 광고주가 책임을 집니다.',
    ),
    (
      title: '제7조 (분석 결과의 성격)',
      body: '서비스가 제공하는 이름 점수·사주 분석·가족 궁합 결과는 전통 성명학과 '
          '간이 만세력에 따른 참고용 계산 결과입니다. 학파별 해석 차이와 간이 계산의 한계가 있을 수 있으므로, '
          '중요한 결정 전에는 전문가 상담을 권장합니다. 분석 결과만을 이유로 발생한 손해에 대해 '
          '서비스 제공자는 책임을 지지 않습니다.',
    ),
    (
      title: '제8조 (지식재산권)',
      body: '서비스의 화면·문구·디자인 등 콘텐츠에 대한 권리는 서비스 제공자에게 있습니다. '
          '이용자는 서비스를 이용하는 범위 안에서만 콘텐츠를 이용할 수 있습니다.',
    ),
    (
      title: '제9조 (서비스의 변경 및 중단)',
      body: '서비스 제공자는 서비스 개선을 위해 기능을 추가·변경할 수 있으며, '
          '기기나 운영체제 환경에 따라 일부 기능이 제한될 수 있습니다. '
          '부득이한 사유로 서비스를 중단하는 경우 사전에 앱 내 공지로 안내합니다.',
    ),
    (
      title: '제10조 (약관의 변경 및 문의)',
      body: '이 약관은 필요에 따라 변경될 수 있으며, 변경된 약관은 앱 내 고지 후 적용됩니다. '
          '서비스에 대한 문의는 아래 연락처로 보내주세요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이용약관')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          ..._sections.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink)),
                      const SizedBox(height: 8),
                      Text(s.body,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.ink,
                              height: 1.6)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          const Text(
            '문의: ${AppLinks.contactEmail}\n본 약관은 앱 배포일부터 적용됩니다.',
            style: TextStyle(fontSize: 12, color: AppTheme.sub, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
