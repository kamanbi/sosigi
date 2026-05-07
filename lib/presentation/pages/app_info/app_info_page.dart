import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/presentation/widgets/common/bottom_banner_ad.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';
import 'package:sosigi/presentation/widgets/common/sosigi_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({super.key});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  static const EdgeInsets _pagePadding = EdgeInsets.fromLTRB(16, 4, 16, 16);
  static const EdgeInsets _headerPadding = EdgeInsets.fromLTRB(14, 10, 14, 8);

  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  Future<void> _open(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크를 열지 못했습니다. 잠시 후 다시 시도해 주세요.'),
        ),
      );
    }
  }

  String _buildVersionLabel(AsyncSnapshot<PackageInfo> snapshot) {
    if (!snapshot.hasData) {
      return '버전 정보를 불러오는 중...';
    }

    final packageInfo = snapshot.data!;
    return '앱 버전 ${packageInfo.version}+${packageInfo.buildNumber}';
  }

  @override
  Widget build(BuildContext context) {
    return SosigiScaffold(
      bottomNavigationBar: const BottomBannerAd(),
      body: Column(
        children: [
          Padding(
            padding: _headerPadding,
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
            child: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                return ListView(
                  padding: _pagePadding,
                  children: [
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('소식이', style: AppTextStyles.pageTitle),
                          const SizedBox(height: 8),
                          Text(
                            '관심 키워드와 카테고리별 뉴스를 빠르게 확인하는 실시간 뉴스 앱입니다.',
                            style:
                                AppTextStyles.sectionBody.copyWith(fontSize: 14),
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
                            onTap: () => _open('mailto:kamanbi@nate.com'),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('홈페이지'),
                            subtitle: const Text(
                              'https://sosigi-news-app.netlify.app/',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _open(
                              'https://sosigi-news-app.netlify.app/',
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('개인정보처리방침'),
                            subtitle: const Text(
                              'https://sosigi-news-app.netlify.app/privacy.html',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _open(
                              'https://sosigi-news-app.netlify.app/privacy.html',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _buildVersionLabel(snapshot),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
