import 'package:flutter/material.dart';
import 'package:sosigi/presentation/pages/app_info/app_info_page.dart';
import 'package:sosigi/presentation/pages/diagnostics/diagnostics_page.dart';
import 'package:sosigi/presentation/pages/home/home_page.dart';
import 'package:sosigi/presentation/pages/keyword_manage/keyword_manage_page.dart';
import 'package:sosigi/presentation/pages/news_sources/news_sources_page.dart';
import 'package:sosigi/presentation/pages/settings/settings_page.dart';
import 'package:sosigi/presentation/pages/splash/splash_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String keywords = '/keywords';
  static const String settings = '/settings';
  static const String info = '/info';
  static const String newsSources = '/news-sources';
  static const String diagnostics = '/diagnostics';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final String? name = routeSettings.name;

    if (name == splash) {
      return MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const SplashPage(),
      );
    }
    if (name == home) {
      return MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const HomePage(),
      );
    }
    if (name == keywords) {
      return MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const KeywordManagePage(),
      );
    }
    if (name == settings) {
      return MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const SettingsPage(),
      );
    }
    if (name == info) {
      return MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const AppInfoPage(),
      );
    }
    if (name == newsSources) {
      return MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const NewsSourcesPage(),
      );
    }
    if (name == diagnostics) {
      return MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const DiagnosticsPage(),
      );
    }

    return MaterialPageRoute<dynamic>(
      builder: (BuildContext context) => Scaffold(
        body: Center(
          child: Text('Page not found: $name'),
        ),
      ),
    );
  }
}