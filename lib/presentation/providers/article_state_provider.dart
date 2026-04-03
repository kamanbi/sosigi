import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosigi/presentation/providers/app_settings_provider.dart';
import 'package:sosigi/services/local_store_service.dart';

class ArticleUserState {
  final Set<String> readIds;
  final Set<String> bookmarkedIds;

  const ArticleUserState({
    required this.readIds,
    required this.bookmarkedIds,
  });

  factory ArticleUserState.initial() {
    return const ArticleUserState(
      readIds: <String>{},
      bookmarkedIds: <String>{},
    );
  }

  ArticleUserState copyWith({
    Set<String>? readIds,
    Set<String>? bookmarkedIds,
  }) {
    return ArticleUserState(
      readIds: readIds ?? this.readIds,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
    );
  }
}

final articleStateProvider =
    StateNotifierProvider<ArticleStateNotifier, ArticleUserState>((ref) {
  return ArticleStateNotifier(ref.read(localStoreProvider));
});

class ArticleStateNotifier extends StateNotifier<ArticleUserState> {
  ArticleStateNotifier(this._store) : super(ArticleUserState.initial());

  final LocalStoreService _store;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final readIds = await _store.loadReadArticleIds();
    final bookmarkedIds = await _store.loadBookmarkedArticleIds();

    state = state.copyWith(
      readIds: readIds,
      bookmarkedIds: bookmarkedIds,
    );
    _loaded = true;
  }

  Future<void> markRead(String articleId) async {
    if (state.readIds.contains(articleId)) return;
    final next = <String>{...state.readIds, articleId};
    state = state.copyWith(readIds: next);
    await _store.saveReadArticleIds(next);
  }

  Future<void> toggleBookmark(String articleId) async {
    final next = <String>{...state.bookmarkedIds};
    if (next.contains(articleId)) {
      next.remove(articleId);
    } else {
      next.add(articleId);
    }
    state = state.copyWith(bookmarkedIds: next);
    await _store.saveBookmarkedArticleIds(next);
  }
}