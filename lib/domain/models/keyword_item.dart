class KeywordItem {
  final String id;
  final String name;
  final bool notificationEnabled;

  const KeywordItem({
    required this.id,
    required this.name,
    required this.notificationEnabled,
  });

  KeywordItem copyWith({
    String? id,
    String? name,
    bool? notificationEnabled,
  }) {
    return KeywordItem(
      id: id ?? this.id,
      name: name ?? this.name,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notificationEnabled': notificationEnabled,
      };

  factory KeywordItem.fromJson(Map<String, dynamic> json) {
    return KeywordItem(
      id: json['id'] as String,
      name: json['name'] as String,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
    );
  }
}