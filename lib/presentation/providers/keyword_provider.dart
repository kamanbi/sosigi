import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/domain/models/keyword_item.dart';
import 'package:sosigi/presentation/providers/app_settings_provider.dart';
import 'package:sosigi/services/local_store_service.dart';

final keywordProvider =
    StateNotifierProvider<KeywordNotifier, List<KeywordItem>>((ref) {
  return KeywordNotifier(ref.read(localStoreProvider));
});

class KeywordNotifier extends StateNotifier<List<KeywordItem>> {
  KeywordNotifier(this._store) : super(const []);

  final LocalStoreService _store;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    state = await _store.loadKeywords();
    _loaded = true;
  }

  Future<void> addKeyword(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;

    final exists = state.any(
      (keyword) => keyword.name.toLowerCase() == value.toLowerCase(),
    );
    if (exists) return;

    final next = [
      ...state,
      KeywordItem(
        id: value.toLowerCase(),
        name: value,
        notificationEnabled: true,
      ),
    ];

    state = next;
    await _store.saveKeywords(next);
  }

  Future<void> removeKeyword(String id) async {
    final next = state.where((keyword) => keyword.id != id).toList();
    state = next;
    await _store.saveKeywords(next);
  }

  Future<void> setNotificationEnabled(String id, bool enabled) async {
    final next = state
        .map(
          (keyword) => keyword.id == id
              ? keyword.copyWith(notificationEnabled: enabled)
              : keyword,
        )
        .toList();

    state = next;
    await _store.saveKeywords(next);
  }

  Future<void> setNotificationDeliveryTime(
    String id,
    KeywordNotificationTime deliveryTime,
  ) async {
    final next = state
        .map(
          (keyword) => keyword.id == id
              ? keyword.copyWith(
                  notificationDeliveryTime: deliveryTime,
                  clearLastNotifiedAt: true,
                )
              : keyword,
        )
        .toList();

    state = next;
    await _store.saveKeywords(next);
  }
}
