import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sosigi/core/ads/ad_ids.dart';
import 'package:sosigi/services/app_logger.dart';

class BottomBannerAd extends StatefulWidget {
  const BottomBannerAd({super.key});

  @override
  State<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends State<BottomBannerAd> {
  BannerAd? _banner;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final width = (await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    )) ??
        AdSize.banner;

    _banner = BannerAd(
      adUnitId: AdIds.bottomBanner,
      size: width,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.error('BottomBannerAd', 'failed to load', error);
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _adLoaded = false;
          });
        },
      ),
    )..load();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null || !_adLoaded) return const SizedBox.shrink();

    return SizedBox(
      height: banner.size.height.toDouble(),
      width: double.infinity,
      child: AdWidget(ad: banner),
    );
  }
}
