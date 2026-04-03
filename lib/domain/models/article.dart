import 'package:sosigi/core/enums/home_category.dart';

class Article {
  final String id;
  final String sourceId;
  final String title;
  final String sourceName;
  final String link;
  final String summary;
  final DateTime? publishedAt;
  final DateTime savedAt;
  final HomeCategory category;
  final List<String> matchedKeywords;
  final bool isKeywordMatched;

  const Article({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.sourceName,
    required this.link,
    required this.summary,
    required this.publishedAt,
    required this.savedAt,
    required this.category,
    required this.matchedKeywords,
    required this.isKeywordMatched,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'title': title,
        'sourceName': sourceName,
        'link': link,
        'summary': summary,
        'publishedAt': publishedAt?.toIso8601String(),
        'savedAt': savedAt.toIso8601String(),
        'category': category.name,
        'matchedKeywords': matchedKeywords,
        'isKeywordMatched': isKeywordMatched,
      };

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      sourceId:
          (json['sourceId'] as String?) ??
          (json['sourceName'] as String? ?? ''),
      title: json['title'] as String,
      sourceName: json['sourceName'] as String,
      link: json['link'] as String,
      summary: json['summary'] as String? ?? '',
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.tryParse(json['publishedAt'] as String),
      savedAt: DateTime.parse(json['savedAt'] as String),
      category: HomeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => HomeCategory.uncategorized,
      ),
      matchedKeywords:
          (json['matchedKeywords'] as List<dynamic>? ?? []).cast<String>(),
      isKeywordMatched: json['isKeywordMatched'] as bool? ?? false,
    );
  }
}
