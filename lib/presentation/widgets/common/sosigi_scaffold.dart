import 'package:flutter/material.dart';
import 'package:sosigi/app/theme/app_colors.dart';

class SosigiScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;

  const SosigiScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final adjustedBottomBar = bottomNavigationBar == null
        ? null
        : SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: bottomNavigationBar!,
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
      bottomNavigationBar: adjustedBottomBar,
    );
  }
}