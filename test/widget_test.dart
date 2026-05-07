import 'package:flutter_test/flutter_test.dart';
import 'package:sosigi/data/default_news_sources.dart';
import 'package:sosigi/domain/models/app_settings.dart';

void main() {
  test('SyncIntervalOption migrates legacy values and keeps 4 hour default',
      () {
    expect(SyncIntervalOption.fromStoredValue(0).minutes, 30);
    expect(SyncIntervalOption.fromStoredValue(1).minutes, 30);
    expect(SyncIntervalOption.fromStoredValue(2).minutes, 60);

    expect(SyncIntervalOption.fromStoredValue('5').minutes, 30);
    expect(SyncIntervalOption.fromStoredValue('15').minutes, 30);
    expect(SyncIntervalOption.fromStoredValue('30').minutes, 30);
    expect(SyncIntervalOption.fromStoredValue('60').minutes, 60);
    expect(SyncIntervalOption.fromStoredValue('90').minutes, 90);
    expect(SyncIntervalOption.fromStoredValue('1440').minutes, 1440);
    expect(SyncIntervalOption.fromStoredValue('min5').minutes, 30);

    expect(AppSettings.initial().syncInterval.minutes, 240);
  });

  test('SyncIntervalOption normalizes wheel edge cases safely', () {
    expect(
      SyncIntervalOption.fromWheelValues(hour: 0, minute: 0).minutes,
      30,
    );
    expect(
      SyncIntervalOption.fromWheelValues(hour: 24, minute: 30).minutes,
      1440,
    );
    expect(
      SyncIntervalOption.fromWheelValues(hour: 1, minute: 30).label,
      '1시간 30분',
    );
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

  test('Notification quiet hours default to 18:00~07:00', () {
    final quietHours = AppSettings.initial().notificationQuietHours;

    expect(quietHours.start.storageValue, '18:00');
    expect(quietHours.end.storageValue, '07:00');
  });

  test('Notification quiet hours handle overnight range correctly', () {
    const quietHours = NotificationQuietHours(
      start: NotificationQuietTime(hour: 18, minute: 0),
      end: NotificationQuietTime(hour: 7, minute: 0),
    );

    expect(quietHours.contains(DateTime(2026, 4, 6, 18, 0)), isTrue);
    expect(quietHours.contains(DateTime(2026, 4, 6, 23, 59)), isTrue);
    expect(quietHours.contains(DateTime(2026, 4, 6, 6, 59)), isTrue);
    expect(quietHours.contains(DateTime(2026, 4, 6, 7, 0)), isFalse);
    expect(quietHours.contains(DateTime(2026, 4, 6, 12, 0)), isFalse);
  });

  test('Google and YNA sources are merged into runtime sources', () {
    final runtimeSources = runtimeDefaultNewsSources;
    final googleSources =
        runtimeSources.where((source) => source.id == 'google').toList();
    final ynaSources =
        runtimeSources.where((source) => source.id == 'yna').toList();
    final mkSources =
        runtimeSources.where((source) => source.id == 'mk').toList();
    final newsisSources =
        runtimeSources.where((source) => source.id == 'newsis').toList();
    final mbnSources =
        runtimeSources.where((source) => source.id == 'mbn').toList();
    final fnnewsSources =
        runtimeSources.where((source) => source.id == 'fnnews').toList();

    expect(googleSources.length, 1);
    expect(ynaSources.length, 1);
    expect(mkSources.length, 1);
    expect(newsisSources.length, 1);
    expect(mbnSources.length, 1);
    expect(fnnewsSources.length, 1);
    expect(googleFeedUrls.length, 8);
    expect(ynaFeedUrls.length, 8);
    expect(mkFeedUrls.length, 4);
    expect(newsisFeedUrls.length, 3);
    expect(mbnFeedUrls.length, 2);
    expect(fnnewsFeedUrls.length, 3);
    expect(
      runtimeSources.where((source) => source.id.startsWith('google_')),
      isEmpty,
    );
    expect(
      runtimeSources.where((source) => source.id.startsWith('yna_')),
      isEmpty,
    );
    expect(
      runtimeSources.where((source) => source.id.startsWith('mk_')),
      isEmpty,
    );
    expect(
      runtimeSources.where((source) => source.id.startsWith('newsis_')),
      isEmpty,
    );
    expect(
      runtimeSources.where((source) => source.id.startsWith('mbn_')),
      isEmpty,
    );
    expect(
      runtimeSources.where((source) => source.id.startsWith('fnnews_')),
      isEmpty,
    );
  });

  test('Merged source feeds and key publishers use expected RSS feeds', () {
    final sourceById = {
      for (final source in runtimeDefaultNewsSources) source.id: source,
    };

    expect(
      sourceById['google']?.url,
      'https://news.google.com/rss?hl=ko&gl=KR&ceid=KR:ko',
    );
    expect(
      sourceById['yna']?.url,
      'https://www.yna.co.kr/rss/news.xml',
    );
    expect(
      sourceById['sbs']?.url,
      'https://news.sbs.co.kr/news/newsflashRssFeed.do?plink=RSSREADER',
    );
    expect(
      sourceById['jtbc']?.url,
      'https://fs.jtbc.co.kr/RSS/newsflash.xml',
    );
    expect(
      sourceById['hani']?.url,
      'https://www.hani.co.kr/rss',
    );
    expect(
      sourceById['hankyung']?.url,
      'https://www.hankyung.com/feed/all-news',
    );
    expect(
      sourceById['fnnews']?.url,
      'https://www.fnnews.com/rss/r20/fn_realnews_all.xml',
    );
    expect(
      sourceById['mk']?.url,
      'https://www.mk.co.kr/rss/40300001/',
    );
    expect(
      sourceById['newsis']?.url,
      'https://www.newsis.com/RSS/economy.xml',
    );
    expect(
      sourceById['mbn']?.url,
      'https://www.mbn.co.kr/rss/',
    );
  });
}
