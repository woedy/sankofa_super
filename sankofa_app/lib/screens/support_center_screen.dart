import 'package:flutter/material.dart';
import 'package:sankofasave/models/support_article_model.dart';
import 'package:sankofasave/screens/dispute_center_screen.dart';
import 'package:sankofasave/screens/support_article_detail_screen.dart';
import 'package:sankofasave/services/support_service.dart';
import 'package:sankofasave/ui/components/info_card.dart';
import 'package:sankofasave/ui/components/section_header.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final SupportService _supportService = SupportService();
  late Future<List<SupportArticleModel>> _articlesFuture;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategory;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _articlesFuture = _supportService.fetchArticles();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category == _selectedCategory ? null : category;
    });
  }

  void _openDisputes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DisputeCenterScreen()),
    );
  }

  List<SupportArticleModel> _filterArticles(
    List<SupportArticleModel> articles,
    String locale,
  ) {
    return articles.where((article) {
      final matchesCategory =
          _selectedCategory == null || article.category == _selectedCategory;
      final title = article.title(locale).toLowerCase();
      final summary = article.summary(locale).toLowerCase();
      final matchesQuery = _query.isEmpty ||
          title.contains(_query) ||
          summary.contains(_query) ||
          article.tags.any((tag) => tag.toLowerCase().contains(_query));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support center'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SupportArticleModel>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.support_agent, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'We had trouble loading help topics.',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh or try again shortly.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? const <SupportArticleModel>[];
          final filtered = _filterArticles(data, localeCode);
          final categories = data.map((article) => article.category).toSet().toList()
            ..sort();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _articlesFuture = _supportService.fetchArticles();
              });
              await _articlesFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search help topics',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 16),
                InfoCard(
                  title: 'Need extra help?',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat with our support desk, open a new dispute, or review ongoing cases from one place.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _openDisputes,
                            icon: const Icon(Icons.forum_outlined),
                            label: const Text('Open a dispute'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openDisputes,
                            icon: const Icon(Icons.list_alt),
                            label: const Text('Track existing cases'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (categories.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final bool isSelected = _selectedCategory == null;
                          return ChoiceChip(
                            label: const Text('All'),
                            selected: isSelected,
                            onSelected: (_) => _selectCategory(null),
                          );
                        }
                        final category = categories[index - 1];
                        final bool isSelected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => _selectCategory(category),
                        );
                      },
                    ),
                  ),
                if (categories.isNotEmpty) const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Common questions',
                  subtitle: 'Answers curated from our Ghanaian susu community.',
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.live_help, size: 40, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'No topics match your search yet.',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try another keyword or explore a different category.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ...filtered.map((article) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InfoCard(
                        title: article.title(localeCode),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.summary(localeCode),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(article.category),
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                                ),
                                ...article.tags.map(
                                  (tag) => Chip(
                                    label: Text('#$tag'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _openArticle(article),
                                child: const Text('Read more'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openArticle(SupportArticleModel article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SupportArticleDetailScreen(article: article),
      ),
    );
  }
}
