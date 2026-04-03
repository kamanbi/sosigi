import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';
import 'package:sosigi/presentation/widgets/common/sosigi_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크를 열지 못했습니다. 잠시 후 다시 시도해 주세요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SosigiScaffold(
      bottomNavigationBar: const BottomBannerAd(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 30,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 4),
                Text('앱 정보 및 문의', style: AppTextStyles.pageTitle),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('소식이', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        '관심 키워드와 카테고리별 뉴스를 빠르게 확인하는 맞춤형 뉴스 앱입니다.',
                        style: AppTextStyles.sectionBody.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('문의 이메일'),
                        subtitle: const Text('kamanbi@nate.com'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          _open(
                            context,
                            'mailto:kamanbi@nate.com',
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('홈페이지'),
                        subtitle:
                            const Text('https://sosigi-news-app.netlify.app/'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          _open(
                            context,
                            'https://sosigi-news-app.netlify.app/',
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('개인정보처리방침'),
                        subtitle: const Text(
                          'https://sosigi-news-app.netlify.app/privacy.html',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          _open(
                            context,
                            'https://sosigi-news-app.netlify.app/privacy.html',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
