import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/dispute_attachment_model.dart';
import 'package:sankofasave/models/dispute_message_model.dart';
import 'package:sankofasave/models/dispute_model.dart';
import 'package:sankofasave/services/api_exception.dart';
import 'package:sankofasave/services/dispute_service.dart';
import 'package:sankofasave/ui/components/info_card.dart';

class DisputeDetailScreen extends StatefulWidget {
  const DisputeDetailScreen({super.key, required this.dispute});

  final DisputeModel dispute;

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final DisputeService _disputeService = DisputeService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMM d, yyyy • h:mm a');

  late DisputeModel _dispute;
  bool _loading = false;
  bool _sending = false;
  bool _hasMutated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dispute = widget.dispute;
    _fetchDispute(force: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDispute({bool force = false}) async {
    if (_loading && !force) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final latest = await _disputeService.fetchDispute(_dispute.id, forceRefresh: force);
      if (!mounted) return;
      if (latest != null) {
        setState(() {
          _dispute = latest;
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to refresh this dispute right now.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final updated = await _disputeService.postMessage(
        disputeId: _dispute.id,
        message: message,
        channel: 'Mobile App',
      );
      if (!mounted) return;
      setState(() {
        _dispute = updated;
        _hasMutated = true;
        _messageController.clear();
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('We couldn\'t send that update. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _handlePop() {
    Navigator.of(context).pop(_hasMutated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        _handlePop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_dispute.caseNumber.isNotEmpty ? _dispute.caseNumber : 'Dispute detail'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handlePop,
          ),
          actions: [
            IconButton(
              onPressed: () => _fetchDispute(force: true),
              tooltip: 'Refresh',
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchDispute(force: true),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  children: [
                    _buildSummaryCard(theme),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(theme),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ..._buildTimeline(theme),
                    if (_dispute.attachments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Attachments',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ..._dispute.attachments.map((attachment) => _AttachmentTile(attachment: attachment)),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Share an update…',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(56, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final assigned = _dispute.assignedToName ?? 'Support team';
    final severityColor = _severityColor(theme);
    final statusColor = _statusColor(theme);
    final deadline = _dispute.slaDue != null ? _dateFormatter.format(_dispute.slaDue!) : 'Not set';

    return InfoCard(
      title: _dispute.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: _dispute.status, color: statusColor, foreground: theme.colorScheme.onPrimary),
              _Chip(label: 'Severity: ${_dispute.severity}', color: severityColor, foreground: Colors.white),
              _Chip(
                label: 'Priority: ${_dispute.priority}',
                color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
                foreground: theme.colorScheme.tertiary,
              ),
              if (_dispute.slaStatus.isNotEmpty)
                _Chip(
                  label: 'SLA: ${_dispute.slaStatus}',
                  color: theme.colorScheme.surfaceVariant,
                  foreground: theme.colorScheme.onSurface,
                ),
            ],
          ),
          const SizedBox(height: 16),
          InfoRow(label: 'Opened on', value: _dateFormatter.format(_dispute.openedAt)),
          InfoRow(label: 'Last updated', value: _dateFormatter.format(_dispute.lastUpdated)),
          InfoRow(label: 'Assigned to', value: assigned),
          InfoRow(label: 'Response deadline', value: deadline),
          InfoRow(label: 'Channel', value: _dispute.channel),
          InfoRow(label: 'Category', value: _dispute.category),
          if (_dispute.groupName != null)
            InfoRow(label: 'Related group', value: _dispute.groupName!),
          if (_dispute.resolutionNotes != null && _dispute.resolutionNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Resolution notes',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(_dispute.resolutionNotes!),
          ],
          if (_dispute.relatedArticleTitle != null) ...[
            const SizedBox(height: 12),
            Text(
              'Suggested help',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(_dispute.relatedArticleTitle!),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: () => _fetchDispute(force: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(ThemeData theme) {
    final messages = _dispute.messages;
    if (messages.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'No messages yet',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Send a note below and our support team will follow up soon.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    return [
      for (final message in messages)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _MessageBubble(message: message, formatter: _dateFormatter),
        ),
    ];
  }

  Color _severityColor(ThemeData theme) {
    switch (_dispute.severity.toLowerCase()) {
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

  Color _statusColor(ThemeData theme) {
    switch (_dispute.status.toLowerCase()) {
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
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.formatter});

  final DisputeMessageModel message;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMember = message.isMember;
    final alignment = isMember ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMember
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant.withValues(alpha: 0.6);
    final textColor = isMember ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final subtitleColor = isMember
        ? theme.colorScheme.onPrimary.withOpacity(0.9)
        : theme.colorScheme.onSurface.withOpacity(0.7);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMember ? 20 : 6),
              bottomRight: Radius.circular(isMember ? 6 : 20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.authorName?.isNotEmpty == true
                      ? message.authorName!
                      : (isMember ? 'You' : 'Support'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  formatter.format(message.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.foreground});

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

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final DisputeAttachmentModel attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${attachment.formattedSize} • ${attachment.formattedUploadedAt()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
