import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosigi/core/ads/exit_interstitial_ad_service.dart';

class ArticleOpenAdCounterService {
  ArticleOpenAdCounterService._();

  static final ArticleOpenAdCounterService instance =
  ArticleOpenAdCounterService._();

  static const String _countKey = 'article_open_count';
  static const int _threshold = 20;

  Future<void> recordOpenAndMaybeShowInterstitial() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_countKey) ?? 0;
    final next = current + 1;

    if (next >= _threshold) {
      await prefs.setInt(_countKey, 0);
      await ExitInterstitialAdService.instance.showIfReady();
      await ExitInterstitialAdService.instance.load();
      return;
    }

    await prefs.setInt(_countKey, next);
  }

  Future<int> getCurrentCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, 0);
  }
}