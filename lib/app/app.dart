import 'package:flutter/material.dart';
import 'package:sosigi/app/router.dart';
import 'package:sosigi/app/theme/app_theme.dart';
import 'package:sosigi/services/notification_service.dart';

class SosigiApp extends StatefulWidget {
  final Widget? homeOverride;

  const SosigiApp({
    super.key,
    this.homeOverride,
  });

  @override
  State<SosigiApp> createState() => _SosigiAppState();
}

class _SosigiAppState extends State<SosigiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.setAppForegroundState(
      _isForegroundState(WidgetsBinding.instance.lifecycleState),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    NotificationService.instance.setAppForegroundState(
      _isForegroundState(state),
    );
  }

  bool _isForegroundState(AppLifecycleState? state) {
    if (state == null) return true;
    return state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sosigi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: widget.homeOverride,
      initialRoute: widget.homeOverride == null ? AppRouter.splash : null,
      onGenerateRoute:
          widget.homeOverride == null ? AppRouter.generateRoute : null,
    );
  }
}
