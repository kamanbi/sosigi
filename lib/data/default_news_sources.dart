import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/domain/models/news_source.dart';

const List<NewsSource> defaultNewsSources = [
  // Google 뉴스 검색 RSS
  NewsSource(
    id: 'google_top',
    provider: 'Google 종합',
    label: '종합',
    url: 'https://news.google.com/rss?hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'google_politics',
    provider: 'Google 정치',
    label: '정치',
    url:
        'https://news.google.com/rss/search?q=%EC%A0%95%EC%B9%98&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.politics,
    enabled: true,
  ),
  NewsSource(
    id: 'google_economy',
    provider: 'Google 경제',
    label: '경제',
    url:
        'https://news.google.com/rss/search?q=%EA%B2%BD%EC%A0%9C&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'google_society',
    provider: 'Google 사회',
    label: '사회',
    url:
        'https://news.google.com/rss/search?q=%EC%82%AC%ED%9A%8C&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.society,
    enabled: true,
  ),
  NewsSource(
    id: 'google_world',
    provider: 'Google 국제',
    label: '국제',
    url:
        'https://news.google.com/rss/search?q=%EA%B5%AD%EC%A0%9C&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.international,
    enabled: true,
  ),
  NewsSource(
    id: 'google_it',
    provider: 'Google IT',
    label: 'IT',
    url:
        'https://news.google.com/rss/search?q=IT+OR+%EA%B8%B0%EC%88%A0+OR+%EB%B0%98%EB%8F%84%EC%B2%B4&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.it,
    enabled: true,
  ),
  NewsSource(
    id: 'google_sports',
    provider: 'Google 스포츠',
    label: '스포츠',
    url:
        'https://news.google.com/rss/search?q=%EC%8A%A4%ED%8F%AC%EC%B8%A0&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.sports,
    enabled: true,
  ),
  NewsSource(
    id: 'google_entertainment',
    provider: 'Google 연예',
    label: '연예',
    url:
        'https://news.google.com/rss/search?q=%EC%97%B0%EC%98%88+OR+%EB%AC%B8%ED%99%94&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.entertainment,
    enabled: true,
  ),

  // 연합뉴스 카테고리 RSS
  NewsSource(
    id: 'yna_top',
    provider: '연합 종합',
    label: '종합',
    url: 'https://www.yna.co.kr/rss/news.xml',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'yna_politics',
    provider: '연합 정치',
    label: '정치',
    url: 'https://www.yna.co.kr/rss/politics.xml',
    category: HomeCategory.politics,
    enabled: true,
  ),
  NewsSource(
    id: 'yna_economy',
    provider: '연합 경제',
    label: '경제',
    url: 'https://www.yna.co.kr/rss/economy.xml',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'yna_society',
    provider: '연합 사회',
    label: '사회',
    url: 'https://www.yna.co.kr/rss/society.xml',
    category: HomeCategory.society,
    enabled: true,
  ),
  NewsSource(
    id: 'yna_world',
    provider: '연합 국제',
    label: '국제',
    url: 'https://www.yna.co.kr/rss/international.xml',
    category: HomeCategory.international,
    enabled: true,
  ),
  NewsSource(
    id: 'yna_it',
    provider: '연합 IT',
    label: 'IT',
    url: 'https://www.yna.co.kr/rss/industry.xml',
    category: HomeCategory.it,
    enabled: true,
  ),
  NewsSource(
    id: 'yna_sports',
    provider: '연합 스포츠',
    label: '스포츠',
    url: 'https://www.yna.co.kr/rss/sports.xml',
    category: HomeCategory.sports,
    enabled: true,
  ),
  NewsSource(
    id: 'yna_entertainment',
    provider: '연합 연예',
    label: '연예',
    url: 'https://www.yna.co.kr/rss/culture.xml',
    category: HomeCategory.entertainment,
    enabled: true,
  ),

  // 매일경제 RSS
  NewsSource(
    id: 'mk_top',
    provider: '매일경제 종합',
    label: '종합',
    url: 'https://www.mk.co.kr/rss/40300001/',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'mk_economy',
    provider: '매일경제 경제',
    label: '경제',
    url: 'https://www.mk.co.kr/rss/30100041/',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'mk_business',
    provider: '매일경제 기업',
    label: '기업',
    url: 'https://www.mk.co.kr/rss/50100032/',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'mk_stock',
    provider: '매일경제 증권',
    label: '증권',
    url: 'https://www.mk.co.kr/rss/50200011/',
    category: HomeCategory.economy,
    enabled: true,
  ),

  // 뉴시스 RSS
  NewsSource(
    id: 'newsis_economy',
    provider: '뉴시스 경제',
    label: '경제',
    url: 'https://www.newsis.com/RSS/economy.xml',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'newsis_finance',
    provider: '뉴시스 금융',
    label: '금융',
    url: 'https://www.newsis.com/RSS/bank.xml',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'newsis_industry',
    provider: '뉴시스 산업',
    label: '산업',
    url: 'https://www.newsis.com/RSS/industry.xml',
    category: HomeCategory.economy,
    enabled: true,
  ),

  // MBN RSS
  NewsSource(
    id: 'mbn_top',
    provider: 'MBN 종합',
    label: '종합',
    url: 'https://www.mbn.co.kr/rss/',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'mbn_economy',
    provider: 'MBN 경제',
    label: '경제',
    url: 'https://www.mbn.co.kr/rss/economy/',
    category: HomeCategory.economy,
    enabled: true,
  ),

  // 파이낸셜뉴스 RSS
  NewsSource(
    id: 'fnnews_top',
    provider: '파이낸셜뉴스 종합',
    label: '종합',
    url: 'https://www.fnnews.com/rss/r20/fn_realnews_all.xml',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'fnnews_economy',
    provider: '파이낸셜뉴스 경제',
    label: '경제',
    url: 'https://www.fnnews.com/rss/r20/fn_realnews_economy.xml',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'fnnews_stock',
    provider: '파이낸셜뉴스 증권',
    label: '증권',
    url: 'https://www.fnnews.com/rss/r20/fn_realnews_stock.xml',
    category: HomeCategory.economy,
    enabled: true,
  ),

  // 개별 언론사
  NewsSource(
    id: 'kbs',
    provider: 'KBS',
    label: 'KBS',
    url:
        'https://news.google.com/rss/search?q=site:news.kbs.co.kr&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'mbc',
    provider: 'MBC',
    label: 'MBC',
    url:
        'https://news.google.com/rss/search?q=site:imnews.imbc.com&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'sbs',
    provider: 'SBS',
    label: 'SBS',
    url: 'https://news.sbs.co.kr/news/newsflashRssFeed.do?plink=RSSREADER',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'ytn',
    provider: 'YTN',
    label: 'YTN',
    url:
        'https://news.google.com/rss/search?q=site:ytn.co.kr&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'jtbc',
    provider: 'JTBC',
    label: 'JTBC',
    url: 'https://fs.jtbc.co.kr/RSS/newsflash.xml',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'chosun',
    provider: '조선일보',
    label: '조선일보',
    url: 'https://www.chosun.com/arc/outboundfeeds/rss/?outputType=xml',
    category: HomeCategory.all,
    enabled: false,
  ),
  NewsSource(
    id: 'joongang',
    provider: '중앙일보',
    label: '중앙일보',
    url:
        'https://news.google.com/rss/search?q=site:joongang.co.kr&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: false,
  ),
  NewsSource(
    id: 'hani',
    provider: '한겨레',
    label: '한겨레',
    url: 'https://www.hani.co.kr/rss',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'khan',
    provider: '경향신문',
    label: '경향신문',
    url: 'https://www.khan.co.kr/rss/rssdata/total_news.xml',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'hankyung',
    provider: '한국경제',
    label: '한국경제',
    url: 'https://www.hankyung.com/feed/all-news',
    category: HomeCategory.all,
    enabled: true,
  ),
];

List<String> _feedUrlsByPrefix(String prefix) {
  return defaultNewsSources
      .where((source) => source.id.startsWith(prefix))
      .map((source) => source.url)
      .toList(growable: false);
}

List<String> get googleFeedUrls => _feedUrlsByPrefix('google_');
List<String> get ynaFeedUrls => _feedUrlsByPrefix('yna_');
List<String> get mkFeedUrls => _feedUrlsByPrefix('mk_');
List<String> get newsisFeedUrls => _feedUrlsByPrefix('newsis_');
List<String> get mbnFeedUrls => _feedUrlsByPrefix('mbn_');
List<String> get fnnewsFeedUrls => _feedUrlsByPrefix('fnnews_');

NewsSource? _buildMergedSource({
  required String prefix,
  required String mergedId,
  required String provider,
}) {
  final categorySources = defaultNewsSources.where(
    (source) => source.id.startsWith(prefix),
  );

  if (categorySources.isEmpty) {
    return null;
  }

  return categorySources.first.copyWith(
    id: mergedId,
    provider: provider,
    label: '종합',
    category: HomeCategory.all,
    enabled: categorySources.any((source) => source.enabled),
  );
}

List<NewsSource> get runtimeDefaultNewsSources {
  final mergedGoogleSource = _buildMergedSource(
    prefix: 'google_',
    mergedId: 'google',
    provider: '구글 종합',
  );
  final mergedYnaSource = _buildMergedSource(
    prefix: 'yna_',
    mergedId: 'yna',
    provider: '연합 종합',
  );
  final mergedMkSource = _buildMergedSource(
    prefix: 'mk_',
    mergedId: 'mk',
    provider: '매일경제',
  );
  final mergedNewsisSource = _buildMergedSource(
    prefix: 'newsis_',
    mergedId: 'newsis',
    provider: '뉴시스',
  );
  final mergedMbnSource = _buildMergedSource(
    prefix: 'mbn_',
    mergedId: 'mbn',
    provider: 'MBN',
  );
  final mergedFnnewsSource = _buildMergedSource(
    prefix: 'fnnews_',
    mergedId: 'fnnews',
    provider: '파이낸셜뉴스',
  );

  final otherSources = defaultNewsSources.where((source) {
    return !source.id.startsWith('google_') &&
        !source.id.startsWith('yna_') &&
        !source.id.startsWith('mk_') &&
        !source.id.startsWith('newsis_') &&
        !source.id.startsWith('mbn_') &&
        !source.id.startsWith('fnnews_');
  }).toList();

  return [
    if (mergedGoogleSource != null) mergedGoogleSource,
    if (mergedYnaSource != null) mergedYnaSource,
    if (mergedMkSource != null) mergedMkSource,
    if (mergedNewsisSource != null) mergedNewsisSource,
    if (mergedMbnSource != null) mergedMbnSource,
    if (mergedFnnewsSource != null) mergedFnnewsSource,
    ...otherSources,
  ];
}
