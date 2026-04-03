import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/data/default_news_sources.dart';
import 'package:sosigi/domain/models/news_source.dart';
import 'package:sosigi/presentation/providers/app_settings_provider.dart';
import 'package:sosigi/services/app_logger.dart';
import 'package:sosigi/services/local_store_service.dart';

final newsSourceProvider =
    StateNotifierProvider<NewsSourceNotifier, List<NewsSource>>((ref) {
  return NewsSourceNotifier(ref.read(localStoreProvider));
});

class NewsSourceNotifier extends StateNotifier<List<NewsSource>> {
  NewsSourceNotifier(this._store) : super(const []);

  final LocalStoreService _store;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    try {
      final loaded = await _store.loadSources();

      if (loaded.isEmpty) {
        state = runtimeDefaultNewsSources;
        await _store.saveSources(runtimeDefaultNewsSources);
        AppLogger.info(
          'NewsSourceNotifier',
          'initialized with defaults: ${runtimeDefaultNewsSources.length}',
        );
        _loaded = true;
        return;
      }

      final enabledById = <String, bool>{
        for (final source in loaded) source.id: source.enabled,
      };

      final legacyGoogleEnabled = loaded.any(
        (source) => source.id.startsWith('google_') && source.enabled,
      );
      final googleEnabled = enabledById['google'] ?? legacyGoogleEnabled;

      final merged = runtimeDefaultNewsSources.map((source) {
        if (source.id == 'google') {
          return source.copyWith(
            enabled: googleEnabled,
          );
        }

        return source.copyWith(
          enabled: enabledById[source.id] ?? source.enabled,
        );
      }).toList();

      state = merged;
      await _store.saveSources(merged);

      AppLogger.info(
        'NewsSourceNotifier',
        'loaded=${loaded.length}, merged=${merged.length}',
      );
    } catch (e, st) {
      AppLogger.error('NewsSourceNotifier', 'load failed', e, st);
      state = runtimeDefaultNewsSources;
    } finally {
      _loaded = true;
    }
  }

  Future<void> toggleSource(String id) async {
    final next = state
        .map(
          (source) => source.id == id
              ? source.copyWith(enabled: !source.enabled)
              : source,
        )
        .toList();

    state = next;
    await _store.saveSources(next);
    AppLogger.info('NewsSourceNotifier', 'toggled source: $id');
  }

  Future<void> enableAll() async {
    final next = state.map((source) => source.copyWith(enabled: true)).toList();
    state = next;
    await _store.saveSources(next);
    AppLogger.info('NewsSourceNotifier', 'all sources enabled: ${next.length}');
  }
}
