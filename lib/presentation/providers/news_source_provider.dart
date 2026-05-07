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
        _loaded = true;
        return;
      }

      final enabledById = <String, bool>{
        for (final source in loaded) source.id: source.enabled,
      };

      final mergedEnabledById = <String, bool>{
        'google': _resolveMergedEnabled(
          mergedId: 'google',
          prefix: 'google_',
          enabledById: enabledById,
          loaded: loaded,
        ),
        'yna': _resolveMergedEnabled(
          mergedId: 'yna',
          prefix: 'yna_',
          enabledById: enabledById,
          loaded: loaded,
          fallbackEnabled: enabledById['google'],
        ),
        'mk': _resolveMergedEnabled(
          mergedId: 'mk',
          prefix: 'mk_',
          enabledById: enabledById,
          loaded: loaded,
        ),
        'newsis': _resolveMergedEnabled(
          mergedId: 'newsis',
          prefix: 'newsis_',
          enabledById: enabledById,
          loaded: loaded,
        ),
        'mbn': _resolveMergedEnabled(
          mergedId: 'mbn',
          prefix: 'mbn_',
          enabledById: enabledById,
          loaded: loaded,
        ),
        'fnnews': _resolveMergedEnabled(
          mergedId: 'fnnews',
          prefix: 'fnnews_',
          enabledById: enabledById,
          loaded: loaded,
        ),
      };

      final merged = runtimeDefaultNewsSources.map((source) {
        if (mergedEnabledById.containsKey(source.id)) {
          return source.copyWith(enabled: mergedEnabledById[source.id]!);
        }

        return source.copyWith(
          enabled: enabledById[source.id] ?? source.enabled,
        );
      }).toList();

      state = merged;
      await _store.saveSources(merged);
    } catch (e, st) {
      AppLogger.error('NewsSourceNotifier', 'load failed', e, st);
      state = runtimeDefaultNewsSources;
    } finally {
      _loaded = true;
    }
  }

  bool _resolveMergedEnabled({
    required String mergedId,
    required String prefix,
    required Map<String, bool> enabledById,
    required List<NewsSource> loaded,
    bool? fallbackEnabled,
  }) {
    final mergedEnabled = enabledById[mergedId];
    if (mergedEnabled != null) {
      return mergedEnabled;
    }

    final categoryEnabled = loaded.any(
      (source) => source.id.startsWith(prefix) && source.enabled,
    );

    if (categoryEnabled) {
      return true;
    }

    return fallbackEnabled ?? false;
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
  }

  Future<void> enableAll() async {
    final next = state.map((source) => source.copyWith(enabled: true)).toList();
    state = next;
    await _store.saveSources(next);
  }
}
