import 'dart:convert';

class SupportArticleModel {
  SupportArticleModel({
    required this.id,
    required this.category,
    required this.titleMap,
    required this.summaryMap,
    required this.sections,
    required this.tags,
  });

  factory SupportArticleModel.fromJson(Map<String, dynamic> json) {
    return SupportArticleModel(
      id: json['id'] as String,
      category: json['category'] as String,
      titleMap: Map<String, String>.from(json['title'] as Map),
      summaryMap: Map<String, String>.from(json['summary'] as Map),
      sections: (json['sections'] as List<dynamic>)
          .map((section) => SupportArticleSection.fromJson(section as Map<String, dynamic>))
          .toList(),
      tags: List<String>.from(json['tags'] as List<dynamic>),
    );
  }

  final String id;
  final String category;
  final Map<String, String> titleMap;
  final Map<String, String> summaryMap;
  final List<SupportArticleSection> sections;
  final List<String> tags;

  String title([String locale = 'en']) => titleMap[locale] ?? titleMap['en'] ?? '';

  String summary([String locale = 'en']) => summaryMap[locale] ?? summaryMap['en'] ?? '';

  List<SupportArticleSection> localizedSections([String locale = 'en']) {
    return sections
        .map((section) => section.localize(locale))
        .toList();
  }

  static List<SupportArticleModel> listFromJsonString(String jsonStr) {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! List<dynamic>) {
      return const [];
    }
    return decoded
        .map((entry) => SupportArticleModel.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}

class SupportArticleSection {
  const SupportArticleSection({
    required this.headingMap,
    required this.bodyMap,
  });

  factory SupportArticleSection.fromJson(Map<String, dynamic> json) {
    return SupportArticleSection(
      headingMap: json['heading'] != null
          ? Map<String, String>.from(json['heading'] as Map)
          : const <String, String>{},
      bodyMap: json['body'] != null
          ? (json['body'] as Map).map<String, List<String>>(
              (key, value) => MapEntry(key as String, List<String>.from(value as List<dynamic>)),
            )
          : const <String, List<String>>{},
    );
  }

  final Map<String, String> headingMap;
  final Map<String, List<String>> bodyMap;

  String heading([String locale = 'en']) => headingMap[locale] ?? headingMap['en'] ?? '';

  List<String> paragraphs([String locale = 'en']) =>
      bodyMap[locale] ?? bodyMap['en'] ?? const <String>[];

  SupportArticleSection localize(String locale) {
    return SupportArticleSection(
      headingMap: {locale: heading(locale)},
      bodyMap: {locale: paragraphs(locale)},
    );
  }
}
