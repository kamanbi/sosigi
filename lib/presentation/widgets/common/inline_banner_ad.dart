import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sosigi/core/ads/ad_ids.dart';
import 'package:sosigi/services/app_logger.dart';

class InlineBannerAd extends StatefulWidget {
  const InlineBannerAd({super.key});

  @override
  State<InlineBannerAd> createState() => _InlineBannerAdState();
}

class _InlineBannerAdState extends State<InlineBannerAd> {
  BannerAd? _banner;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();

    _banner = BannerAd(
      adUnitId: AdIds.inlineBanner,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.error('InlineBannerAd', 'failed to load', error);
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _adLoaded = false;
          });
        },
      ),
    )..load();
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
