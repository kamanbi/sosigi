import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/domain/models/news_source.dart';

const List<NewsSource> defaultNewsSources = [
  // ── 카테고리별 연합뉴스 RSS (Google 키워드 검색 → 공식 카테고리 피드로 교체) ──
  NewsSource(
    id: 'google_top',
    provider: '연합뉴스 종합',
    label: '종합',
    url: 'https://www.yna.co.kr/rss/news.xml',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'google_politics',
    provider: '연합뉴스 정치',
    label: '정치',
    url: 'https://www.yna.co.kr/rss/politics.xml',
    category: HomeCategory.politics,
    enabled: true,
  ),
  NewsSource(
    id: 'google_economy',
    provider: '연합뉴스 경제',
    label: '경제',
    url: 'https://www.yna.co.kr/rss/economy.xml',
    category: HomeCategory.economy,
    enabled: true,
  ),
  NewsSource(
    id: 'google_society',
    provider: '연합뉴스 사회',
    label: '사회',
    url: 'https://www.yna.co.kr/rss/society.xml',
    category: HomeCategory.society,
    enabled: true,
  ),
  NewsSource(
    id: 'google_world',
    provider: '연합뉴스 국제',
    label: '국제',
    url: 'https://www.yna.co.kr/rss/international.xml',
    category: HomeCategory.international,
    enabled: true,
  ),
  NewsSource(
    id: 'google_it',
    provider: 'IT뉴스',
    label: 'IT',
    url:
        'https://news.google.com/rss/search?q=site:zdnet.co.kr+OR+site:aitimes.com+OR+site:inews24.com&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.it,
    enabled: true,
  ),
  NewsSource(
    id: 'google_sports',
    provider: '연합뉴스 스포츠',
    label: '스포츠',
    url: 'https://www.yna.co.kr/rss/sports.xml',
    category: HomeCategory.sports,
    enabled: true,
  ),
  NewsSource(
    id: 'google_entertainment',
    provider: '연합뉴스 연예',
    label: '연예',
    url: 'https://www.yna.co.kr/rss/culture.xml',
    category: HomeCategory.entertainment,
    enabled: true,
  ),

  // ── 방송/신문사 ──
  NewsSource(
    id: 'kbs',
    provider: 'KBS',
    label: 'KBS',
    url: 'https://news.google.com/rss/search?q=site:news.kbs.co.kr&hl=ko&gl=KR&ceid=KR:ko',
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

List<String> get googleFeedUrls {
  return defaultNewsSources
      .where((source) => source.id.startsWith('google_'))
      .map((source) => source.url)
      .toList(growable: false);
}

List<NewsSource> get runtimeDefaultNewsSources {
  final googleSources =
      defaultNewsSources.where((source) => source.id.startsWith('google_'));

  final mergedGoogle = googleSources.isEmpty
      ? null
      : googleSources.first.copyWith(
          id: 'google',
          provider: '연합뉴스 종합',
          label: '종합',
          category: HomeCategory.all,
          enabled: googleSources.any((source) => source.enabled),
        );

  final otherSources = defaultNewsSources
      .where((source) => !source.id.startsWith('google_'))
      .toList();

  if (mergedGoogle == null) {
    return otherSources;
  }

  return [mergedGoogle, ...otherSources];
}
