import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sankofasave/models/support_article_model.dart';

class SupportService {
  SupportService._internal();

  static final SupportService _instance = SupportService._internal();

  factory SupportService() => _instance;

  List<SupportArticleModel>? _cache;

  Future<List<SupportArticleModel>> fetchArticles() async {
    if (_cache != null) {
      return _cache!;
    }

    final String jsonStr = await rootBundle.loadString('assets/data/support_topics.json');
    _cache = SupportArticleModel.listFromJsonString(jsonStr);
    return _cache!;
  }

  Future<SupportArticleModel?> fetchArticleById(String id) async {
    final articles = await fetchArticles();
    try {
      return articles.firstWhere((article) => article.id == id);
    } catch (_) {
      return null;
    }
  }
}
