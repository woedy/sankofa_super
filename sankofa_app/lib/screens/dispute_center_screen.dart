import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/dispute_model.dart';
import 'package:sankofasave/screens/dispute_detail_screen.dart';
import 'package:sankofasave/screens/dispute_new_screen.dart';
import 'package:sankofasave/services/api_exception.dart';
import 'package:sankofasave/services/dispute_service.dart';
import 'package:sankofasave/ui/components/info_card.dart';
import 'package:sankofasave/ui/components/section_header.dart';

class DisputeCenterScreen extends StatefulWidget {
  const DisputeCenterScreen({super.key});

  @override
  State<DisputeCenterScreen> createState() => _DisputeCenterScreenState();
}

class _DisputeCenterScreenState extends State<DisputeCenterScreen> {
  final DisputeService _disputeService = DisputeService();
  final DateFormat _dateFormatter = DateFormat('MMM d • h:mm a');

  List<DisputeModel> _disputes = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes({bool force = false}) async {
    setState(() {
      if (_disputes.isEmpty || force) {
        _isLoading = !force;
      }
      _isRefreshing = force;
      _errorMessage = null;
    });

    try {
      final disputes = await _disputeService.listDisputes(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _disputes = disputes;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We had trouble loading your disputes. Please try again.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refresh() => _loadDisputes(force: true);

  Future<void> _startNewDispute() async {
    final result = await Navigator.of(context).push<DisputeModel?>(
      MaterialPageRoute(builder: (_) => const DisputeNewScreen()),
    );
    if (!mounted || result == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _disputes = [
        result,
        ..._disputes.where((item) => item.id != result.id),
      ];
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Your dispute was submitted. We\'ll keep you posted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openDispute(DisputeModel dispute) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DisputeDetailScreen(dispute: dispute),
      ),
    );
    if (shouldRefresh == true && mounted) {
      await _loadDisputes(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & disputes'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewDispute,
        icon: const Icon(Icons.add_comment),
        label: const Text('Report an issue'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.support_agent, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Need a hand?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadDisputes(force: true),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_disputes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            const SectionHeader(
              title: 'No disputes yet',
              subtitle: 'If anything looks off, send us a note and we\'ll follow up fast.',
            ),
            const SizedBox(height: 24),
            InfoCard(
              title: 'We\'re here to help',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap the button below to open a dispute. You\'ll see every update in this inbox.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _startNewDispute,
                    icon: const Icon(Icons.edit_square),
                    label: const Text('Start a dispute'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _disputes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: SectionHeader(
                title: 'Your disputes',
                subtitle: 'Track open cases and review resolved issues in one place.',
              ),
            );
          }
          final dispute = _disputes[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _DisputeCard(
              dispute: dispute,
              dateFormatter: _dateFormatter,
              onTap: () => _openDispute(dispute),
            ),
          );
        },
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({
    required this.dispute,
    required this.dateFormatter,
    required this.onTap,
  });

  final DisputeModel dispute;
  final DateFormat dateFormatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme);
    final severityColor = _severityColor(theme);
    final updatedLabel = dateFormatter.format(dispute.lastUpdated);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dispute.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                _Badge(label: dispute.status, color: statusColor, foreground: theme.colorScheme.onPrimary),
              ],
            ),
            if (dispute.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dispute.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  label: 'Severity: ${dispute.severity}',
                  color: severityColor,
                  foreground: severityColor.computeLuminance() > 0.4 ? theme.colorScheme.onPrimaryContainer : Colors.white,
                ),
                _Badge(
                  label: 'Priority: ${dispute.priority}',
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.16),
                  foreground: theme.colorScheme.tertiary,
                ),
                if (dispute.groupName != null)
                  _Badge(
                    label: dispute.groupName!,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foreground: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  'Updated $updatedLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme) {
    switch (dispute.status.toLowerCase()) {
      case 'resolved':
        return theme.colorScheme.secondary;
      case 'escalated':
        return theme.colorScheme.error;
      case 'in review':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primaryContainer;
    }
  }

  Color _severityColor(ThemeData theme) {
    switch (dispute.severity.toLowerCase()) {
      case 'critical':
        return theme.colorScheme.error;
      case 'high':
        return theme.colorScheme.error.withValues(alpha: 0.8);
      case 'medium':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.primaryContainer;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
