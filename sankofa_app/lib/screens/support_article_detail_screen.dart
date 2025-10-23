import 'package:flutter/material.dart';
import 'package:sankofasave/models/support_article_model.dart';
import 'package:sankofasave/ui/components/info_card.dart';

class SupportArticleDetailScreen extends StatelessWidget {
  const SupportArticleDetailScreen({required this.article, super.key});

  final SupportArticleModel article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    final sections = article.sections;

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title(localeCode)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.category,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.summary(localeCode),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: article.tags
                  .map((tag) => Chip(
                        label: Text('#$tag'),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ...sections.map((section) {
              final heading = section.heading(localeCode);
              final paragraphs = section.paragraphs(localeCode);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: InfoCard(
                  title: heading.isEmpty ? 'Guidance' : heading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...paragraphs.map(
                        (paragraph) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            paragraph,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      if (paragraphs.isEmpty)
                        Text(
                          'We\'re preparing more guidance for this topic.',
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Need more help?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Reach out through in-app chat or email hello@sankofa.save and our support team will follow up.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
