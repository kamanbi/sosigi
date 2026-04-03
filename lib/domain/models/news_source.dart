import 'package:sosigi/core/enums/home_category.dart';

class NewsSource {
  final String id;
  final String provider;
  final String label;
  final String url;
  final HomeCategory category;
  final bool enabled;

  const NewsSource({
    required this.id,
    required this.provider,
    required this.label,
    required this.url,
    required this.category,
    required this.enabled,
  });

  NewsSource copyWith({
    String? id,
    String? provider,
    String? label,
    String? url,
    HomeCategory? category,
    bool? enabled,
  }) {
    return NewsSource(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      label: label ?? this.label,
      url: url ?? this.url,
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'label': label,
        'url': url,
        'category': category.name,
        'enabled': enabled,
      };

  factory NewsSource.fromJson(Map<String, dynamic> json) {
    return NewsSource(
      id: json['id'] as String,
      provider: json['provider'] as String,
      label: json['label'] as String,
      url: json['url'] as String,
      category: HomeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => HomeCategory.uncategorized,
      ),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}