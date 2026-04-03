import 'package:flutter/material.dart';
import 'package:sosigi/app/router.dart';
import 'package:sosigi/app/theme/app_theme.dart';

class SosigiApp extends StatelessWidget {
  final Widget? homeOverride;

  const SosigiApp({
    super.key,
    this.homeOverride,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sosigi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: homeOverride,
      initialRoute: homeOverride == null ? AppRouter.splash : null,
      onGenerateRoute:
          homeOverride == null ? AppRouter.generateRoute : null,
    );
  }
}
