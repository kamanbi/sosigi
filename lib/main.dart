// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sosigi/background/background_sync_entrypoint.dart';
import 'package:sosigi/app/app.dart';
import 'package:sosigi/core/ads/exit_interstitial_ad_service.dart';
import 'package:sosigi/services/background_sync_scheduler.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/local_store_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await _initializeSupabase();
  await LocalStoreService.initialize();
  await _initializeStartupServices();

  runApp(
    const ProviderScope(
      child: SosigiApp(),
    ),
  );
}

Future<void> _initializeSupabase() async {
  try {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (url.isEmpty || key.isEmpty) {
      AppLogger.info('main', 'Supabase env not configured, skipping');
      return;
    }
    await Supabase.initialize(url: url, anonKey: key);
    AppLogger.info('main', 'Supabase initialized');
  } catch (e, st) {
    AppLogger.error('main', 'Supabase initialize failed', e, st);
  }
}

Future<void> _initializeStartupServices() async {
  try {
    await MobileAds.instance.initialize();
    AppLogger.info('main', 'MobileAds initialized');
  } catch (e, st) {
    AppLogger.error('main', 'MobileAds initialize failed', e, st);
  }

  try {
    await ExitInterstitialAdService.instance.load();
    AppLogger.info('main', 'ExitInterstitialAdService loaded');
  } catch (e, st) {
    AppLogger.error('main', 'ExitInterstitialAdService load failed', e, st);
  }

  try {
    final settings = await LocalStoreService().loadSettings();
    await BackgroundSyncScheduler.instance.schedule(settings);
    AppLogger.info('main', 'BackgroundSyncScheduler configured');
  } catch (e, st) {
    AppLogger.error('main', 'BackgroundSyncScheduler configure failed', e, st);
  }
}
