import 'package:flutter_test/flutter_test.dart';
import 'package:sosigi/data/default_news_sources.dart';
import 'package:sosigi/domain/models/app_settings.dart';

void main() {
  test('SyncIntervalOption migrates legacy values and keeps 1 hour default', () {
    expect(SyncIntervalOption.fromStoredValue(0), SyncIntervalOption.min15);
    expect(SyncIntervalOption.fromStoredValue(1), SyncIntervalOption.min30);
    expect(SyncIntervalOption.fromStoredValue(2), SyncIntervalOption.hour1);

    expect(SyncIntervalOption.fromStoredValue('5'), SyncIntervalOption.min15);
    expect(SyncIntervalOption.fromStoredValue('15'), SyncIntervalOption.min15);
    expect(SyncIntervalOption.fromStoredValue('30'), SyncIntervalOption.min30);
    expect(SyncIntervalOption.fromStoredValue('60'), SyncIntervalOption.hour1);
    expect(SyncIntervalOption.fromStoredValue('min5'), SyncIntervalOption.min15);

    expect(AppSettings.initial().syncInterval, SyncIntervalOption.hour1);
  });

  test('RetentionOption migrates legacy values and defaults cleanly', () {
    expect(RetentionOption.fromStoredValue(0), RetentionOption.hour72);
    expect(RetentionOption.fromStoredValue(1), RetentionOption.hour96);
    expect(RetentionOption.fromStoredValue(2), RetentionOption.hour120);

    expect(RetentionOption.fromStoredValue('72'), RetentionOption.hour72);
    expect(RetentionOption.fromStoredValue('96'), RetentionOption.hour96);
    expect(RetentionOption.fromStoredValue('120'), RetentionOption.hour120);

    expect(AppSettings.initial().retentionOption, RetentionOption.hour120);
  });

  test('Google sources are merged into a single runtime source', () {
    final runtimeSources = runtimeDefaultNewsSources;
    final googleSources =
        runtimeSources.where((source) => source.id == 'google').toList();

    expect(googleSources.length, 1);
    expect(googleFeedUrls.length, 8);
    expect(
      runtimeSources.where((source) => source.id.startsWith('google_')),
      isEmpty,
    );
  });

  test('Key publishers use direct RSS feeds in defaults', () {
    final sourceById = {
      for (final source in runtimeDefaultNewsSources) source.id: source,
    };

    expect(
      sourceById['yonhap']?.url,
      'https://www.yonhapnewstv.co.kr/browse/feed/',
    );
    expect(
      sourceById['sbs']?.url,
      'https://news.sbs.co.kr/news/newsflashRssFeed.do?plink=RSSREADER',
    );
    expect(
      sourceById['hani']?.url,
      'https://www.hani.co.kr/rss',
    );
    expect(
      sourceById['hankyung']?.url,
      'https://www.hankyung.com/feed/all-news',
    );
  });
}
