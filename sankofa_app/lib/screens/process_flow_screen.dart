import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sankofasave/models/process_flow_model.dart';
import 'package:sankofasave/services/analytics_service.dart';

class ProcessFlowScreen extends StatefulWidget {
  const ProcessFlowScreen({super.key, required this.flow});

  final ProcessFlowModel flow;

  @override
  State<ProcessFlowScreen> createState() => _ProcessFlowScreenState();
}

class _ProcessFlowScreenState extends State<ProcessFlowScreen> {
  late final AnalyticsService _analytics;

  @override
  void initState() {
    super.initState();
    _analytics = AnalyticsService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics.logEvent('process_flow_open', properties: {
        'flow_id': widget.flow.id,
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    return Scaffold(
      appBar: AppBar(
        title: Text(flow.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(flow),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildStepCards(flow),
                    const SizedBox(height: 24),
                    _buildCompletion(flow),
                    const SizedBox(height: 28),
                    _buildActions(flow),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ProcessFlowModel flow) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flow.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      flow.subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Hero(
                tag: 'process-hero-${flow.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    flow.heroAsset,
                    height: 132,
                    width: 132,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoChip(Icons.layers_outlined, '${flow.steps.length} guided steps'),
              _buildInfoChip(Icons.timer_outlined, flow.expectation),
              if (flow.secondaryActionLabel != null)
                _buildInfoChip(Icons.share_outlined, flow.secondaryActionLabel!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCards(ProcessFlowModel flow) {
    final theme = Theme.of(context);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Process walkthrough',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...List.generate(flow.steps.length, (index) {
            final step = flow.steps[index];
            final isLast = index == flow.steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          child: Icon(step.icon, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.badge ?? 'Step ${index + 1}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                step.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    if (step.helper != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                step.helper!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      );
  }

  Widget _buildCompletion(ProcessFlowModel flow) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.tertiary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  flow.completionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            flow.completionDescription,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ProcessFlowModel flow) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next actions',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (flow.secondaryActionLabel != null)
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${flow.secondaryActionLabel} • Demo only'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _analytics.logEvent('process_flow_secondary_action', properties: {
                'flow_id': flow.id,
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              flow.secondaryActionLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (flow.secondaryActionLabel != null) const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            _analytics.logEvent('process_flow_primary_action', properties: {
              'flow_id': flow.id,
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${flow.completionTitle} • Demo complete'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  flow.primaryActionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}