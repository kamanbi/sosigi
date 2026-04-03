import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sosigi/core/ads/ad_ids.dart';
import 'package:sosigi/services/app_logger.dart';

class ExitInterstitialAdService {
  ExitInterstitialAdService._();

  static final ExitInterstitialAdService instance =
  ExitInterstitialAdService._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoading || _interstitialAd != null) return;

    _isLoading = true;

    await InterstitialAd.load(
      adUnitId: AdIds.exitInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          AppLogger.error('ExitInterstitialAdService', 'failed to load', error);
          _interstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  Future<void> showIfReady() async {
    final ad = _interstitialAd;

    if (ad == null) {
      await load();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        load();
      },
    );

    ad.show();
    _interstitialAd = null;
  }

  Future<void> disposeAd() async {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}