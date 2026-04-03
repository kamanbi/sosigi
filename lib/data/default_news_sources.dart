import 'package:sosigi/core/enums/home_category.dart';
import 'package:sosigi/domain/models/news_source.dart';

const List<NewsSource> defaultNewsSources = [
  NewsSource(
    id: 'google_top',
    provider: 'Google 종합',
    label: '구글뉴스 종합',
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
        'https://news.google.com/rss/search?q=AI%20OR%20IT%20OR%20%EB%B0%98%EB%8F%84%EC%B2%B4&hl=ko&gl=KR&ceid=KR:ko',
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
        'https://news.google.com/rss/search?q=%EC%97%B0%EC%98%88&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.entertainment,
    enabled: true,
  ),

  NewsSource(
    id: 'yonhap',
    provider: '연합뉴스',
    label: '연합뉴스',
    url:
        'https://www.yonhapnewstv.co.kr/browse/feed/',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'kbs',
    provider: 'KBS',
    label: 'KBS',
    url:
        'https://news.google.com/rss/search?q=KBS&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'mbc',
    provider: 'MBC',
    label: 'MBC',
    url:
        'https://news.google.com/rss/search?q=MBC%20%EB%89%B4%EC%8A%A4&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'sbs',
    provider: 'SBS',
    label: 'SBS',
    url:
        'https://news.sbs.co.kr/news/newsflashRssFeed.do?plink=RSSREADER',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'ytn',
    provider: 'YTN',
    label: 'YTN',
    url:
        'https://news.google.com/rss/search?q=YTN&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'jtbc',
    provider: 'JTBC',
    label: 'JTBC',
    url:
        'https://news.google.com/rss/search?q=JTBC&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'chosun',
    provider: '조선일보',
    label: '조선일보',
    url:
        'https://news.google.com/rss/search?q=%EC%A1%B0%EC%84%A0%EC%9D%BC%EB%B3%B4&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: false,
  ),
  NewsSource(
    id: 'joongang',
    provider: '중앙일보',
    label: '중앙일보',
    url:
        'https://news.google.com/rss/search?q=%EC%A4%91%EC%95%99%EC%9D%BC%EB%B3%B4&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: false,
  ),
  NewsSource(
    id: 'hani',
    provider: '한겨레',
    label: '한겨레',
    url:
        'https://www.hani.co.kr/rss',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'khan',
    provider: '경향신문',
    label: '경향신문',
    url:
        'https://news.google.com/rss/search?q=%EA%B2%BD%ED%96%A5%EC%8B%A0%EB%AC%B8&hl=ko&gl=KR&ceid=KR:ko',
    category: HomeCategory.all,
    enabled: true,
  ),
  NewsSource(
    id: 'hankyung',
    provider: '한국경제',
    label: '한국경제',
    url:
        'https://www.hankyung.com/feed/all-news',
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
          provider: 'Google 종합',
          label: 'Google 종합',
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
