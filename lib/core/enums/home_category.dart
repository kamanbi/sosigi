enum HomeCategory {
  all,
  politics,
  economy,
  society,
  international,
  it,
  sports,
  entertainment,
  keyword,
  uncategorized,
}

extension HomeCategoryX on HomeCategory {
  String get label {
    switch (this) {
      case HomeCategory.all:
        return '전체';
      case HomeCategory.politics:
        return '정치';
      case HomeCategory.economy:
        return '경제';
      case HomeCategory.society:
        return '사회';
      case HomeCategory.international:
        return '국제';
      case HomeCategory.it:
        return 'IT';
      case HomeCategory.sports:
        return '스포츠';
      case HomeCategory.entertainment:
        return '연예';
      case HomeCategory.keyword:
        return '키워드';
      case HomeCategory.uncategorized:
        return '미분류';
    }
  }
}