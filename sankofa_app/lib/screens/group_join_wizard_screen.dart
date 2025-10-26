import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/notification_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/services/group_service.dart';
import 'package:sankofasave/services/notification_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/ui/components/info_card.dart';
import 'package:sankofasave/ui/components/ui.dart';

class GroupJoinWizardScreen extends StatefulWidget {
  const GroupJoinWizardScreen({super.key, this.initialGroupId});

  final String? initialGroupId;

  @override
  State<GroupJoinWizardScreen> createState() => _GroupJoinWizardScreenState();
}

class _GroupJoinWizardScreenState extends State<GroupJoinWizardScreen> {
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _introductionController = TextEditingController();

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  final List<_JoinWizardStep> _steps = const [
    _JoinWizardStep(
      title: 'Choose a circle',
      subtitle: 'Compare public groups curated for trust and transparency.',
      icon: Icons.groups_outlined,
    ),
    _JoinWizardStep(
      title: 'Plan your seat',
      subtitle: 'Lock in reminders and auto-drafts that match your rhythm.',
      icon: Icons.event_available_outlined,
    ),
    _JoinWizardStep(
      title: 'Review & submit',
      subtitle: 'Confirm details before you take a spot in the circle.',
      icon: Icons.check_circle_outline,
    ),
  ];

  List<SusuGroupModel> _availableGroups = const [];
  SusuGroupModel? _selectedGroup;
  UserModel? _user;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _autoSave = true;
  bool _remindersEnabled = true;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _introductionController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final user = await _userService.getCurrentUser();
    final groups = await _groupService.getGroups();

    final filtered = groups
        .where(
          (group) =>
              group.isPublic &&
              (user == null || !group.memberIds.contains(user.id)) &&
              group.memberNames.length < group.targetMemberCount,
        )
        .toList()
      ..sort(
        (a, b) => a.nextPayoutDate.compareTo(b.nextPayoutDate),
      );

    SusuGroupModel? preselected;
    if (widget.initialGroupId != null) {
      try {
        preselected =
            filtered.firstWhere((group) => group.id == widget.initialGroupId);
      } catch (_) {
        preselected = null;
      }
    }
    preselected ??= filtered.isNotEmpty ? filtered.first : null;

    if (!mounted) return;
    setState(() {
      _user = user;
      _availableGroups = filtered;
      _selectedGroup = preselected;
      _isLoading = false;
    });
  }

  bool get _canContinue {
    if (_currentStep == 0) {
      return _selectedGroup != null;
    }
    if (_currentStep == 1) {
      return _selectedGroup != null;
    }
    return !_isSubmitting && _selectedGroup != null;
  }

  void _goToPrevious() {
    if (_currentStep == 0 || _isSubmitting) return;
    setState(() => _currentStep -= 1);
  }

  Future<void> _goToNext() async {
    if (!_canContinue) return;
    if (_currentStep == _steps.length - 1) {
      await _completeJoin();
      return;
    }
    setState(() => _currentStep += 1);
  }

  Future<void> _completeJoin() async {
    final group = _selectedGroup;
    final user = _user;
    if (group == null || user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final updatedGroup = await _groupService.joinPublicGroup(
        groupId: group.id,
        introduction: _introductionController.text.trim().isEmpty
            ? null
            : _introductionController.text.trim(),
        autoSave: _autoSave,
        remindersEnabled: _remindersEnabled,
      );

      final now = DateTime.now();
      final seatNumber = updatedGroup.memberNames.length;
      final reminderCopy = _remindersEnabled ? 'Smart reminders on.' : 'Reminders off.';
      final autoSaveCopy = _autoSave ? 'Auto-contributions enabled.' : 'Auto-contributions off.';

      await _notificationService.addNotification(
        NotificationModel(
          id: 'notif_join_${now.millisecondsSinceEpoch}',
          userId: user.id,
          title: 'Joined ${updatedGroup.name}',
          message: 'Seat #$seatNumber secured. $autoSaveCopy $reminderCopy',
          type: 'group',
          isRead: false,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(updatedGroup);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not join group: ${error.toString()}'),
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  int _availableSeats(SusuGroupModel group) {
    final seats = group.targetMemberCount - group.memberNames.length;
    return seats < 0 ? 0 : seats;
  }

  String _formatCurrency(num value) => 'GH₵ ${_currencyFormatter.format(value)}';

  Widget _buildStepContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentStep) {
      case 0:
        return _buildSelectGroupStep();
      case 1:
        return _buildPlanStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectGroupStep() {
    if (_availableGroups.isEmpty) {
      return InfoCard(
        title: 'No public circles available right now',
        child: Text(
          'Keep an eye out—new public Susu groups appear here once the platform schedules fresh cohorts.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a public Susu group',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'We highlight platform-curated circles with transparent rules, open seats, and healthy repayment history.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72), height: 1.5),
        ),
        const SizedBox(height: 20),
        ..._availableGroups.map((group) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildGroupOption(group),
            )),
      ],
    );
  }

  Widget _buildGroupOption(SusuGroupModel group) {
    final theme = Theme.of(context);
    final selected = _selectedGroup?.id == group.id;
    final seats = _availableSeats(group);
    final chips = <Widget>[
      _buildMetaChip(Icons.paid_outlined, _formatCurrency(group.contributionAmount)),
      if (group.frequency != null)
        _buildMetaChip(Icons.schedule, group.frequency!),
      _buildMetaChip(Icons.event_available_outlined, 'Next payout ${DateFormat('MMM d').format(group.nextPayoutDate)}'),
      _buildMetaChip(Icons.chair_alt_outlined, '$seats seats open'),
    ];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGroup = group);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.16),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientIconBadge(
                  icon: selected ? Icons.task_alt : Icons.groups,
                  colors: selected
                      ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                      : [theme.colorScheme.secondary, theme.colorScheme.tertiary],
                  diameter: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (group.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          group.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                height: 1.45,
                              ),
                        ),
                      ],
                      if (group.location != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                group.location!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips,
            ),
            if (group.requiresApproval) ...[
              const SizedBox(height: 14),
              _buildMetaChip(
                Icons.verified_user_outlined,
                'Admin will review your application before confirming.',
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanStep() {
    final group = _selectedGroup;
    if (group == null) {
      return InfoCard(
        title: 'Pick a group first',
        child: Text(
          'Choose a public circle to unlock contribution planning and review.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72)),
        ),
      );
    }

    final theme = Theme.of(context);
    final seatPosition = group.memberNames.length + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lock in your contribution rhythm',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Toggle the guardrails that keep your contributions on track. You can always adjust these later in settings.',
          style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'Your upcoming seat',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: 'Seat position',
                value: '#$seatPosition of ${group.targetMemberCount}',
              ),
              InfoRow(
                label: 'Contribution amount',
                value: _formatCurrency(group.contributionAmount),
              ),
              InfoRow(
                label: 'Next payout window',
                value: DateFormat('MMM d, yyyy').format(group.nextPayoutDate),
              ),
              if (group.frequency != null)
                InfoRow(
                  label: 'Contribution cadence',
                  value: group.frequency!,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile.adaptive(
          value: _autoSave,
          onChanged: (value) => setState(() => _autoSave = value),
          title: const Text('Enable auto-contributions'),
          subtitle: Text(
            _autoSave
                ? 'We will auto-draft before each cycle so you never miss your ₵${group.contributionAmount.toStringAsFixed(0)}.'
                : 'Prefer manual payments? Keep auto-draft off and we will only remind you.',
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _remindersEnabled,
          onChanged: (value) => setState(() => _remindersEnabled = value),
          title: const Text('Send smart reminders'),
          subtitle: Text(
            _remindersEnabled
                ? 'Get nudges 24 hours before each contribution and when your payout window opens.'
                : 'Turn this off if you prefer to check the app on your own schedule.',
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _introductionController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            labelText: 'Share a short introduction (optional)',
            hintText: 'Explain your savings goal or how you plan to contribute to the group.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final group = _selectedGroup;
    if (group == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final seatPosition = group.memberNames.length + 1;
    final intro = _introductionController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Double-check before joining',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Confirm the essentials so group admins know what to expect when you hop in.',
          style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'Membership summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(label: 'Group', value: group.name),
              InfoRow(label: 'Seat position', value: '#$seatPosition of ${group.targetMemberCount}'),
              InfoRow(label: 'Contribution amount', value: _formatCurrency(group.contributionAmount)),
              InfoRow(
                label: 'Auto-contributions',
                value: _autoSave ? 'Enabled' : 'Off – you will pay manually',
              ),
              InfoRow(
                label: 'Smart reminders',
                value: _remindersEnabled ? 'On – nudges before each cycle' : 'Off – no push reminders',
              ),
            ],
          ),
        ),
        if (group.requiresApproval) ...[
          const SizedBox(height: 20),
          InfoCard(
            title: 'Admin review required',
            child: Text(
              'Group admins will review your request before activating your seat. You will receive a notification once approved.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
            ),
          ),
        ],
        if (intro.isNotEmpty) ...[
          const SizedBox(height: 20),
          InfoCard(
            title: 'Your introduction',
            child: Text(
              intro,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {bool dense = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 14 : 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a public group'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _JoinWizardProgress(steps: _steps, currentStep: _currentStep),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: SingleChildScrollView(
                  key: ValueKey(_currentStep * (_selectedGroup?.hashCode ?? 1)),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: _buildStepContent(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _goToPrevious,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canContinue ? _goToNext : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _currentStep == _steps.length - 1
                                  ? 'Join group'
                                  : 'Continue',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinWizardStep {
  const _JoinWizardStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _JoinWizardProgress extends StatelessWidget {
  const _JoinWizardProgress({
    required this.steps,
    required this.currentStep,
  });

  final List<_JoinWizardStep> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == currentStep;
          final isComplete = index < currentStep;
          final step = steps[index];
          final background = isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface;
          final borderColor = isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: isComplete ? 0.28 : 0.16);
          final iconColor = isComplete
              ? theme.colorScheme.onPrimary
              : isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isComplete
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    isComplete ? Icons.check : step.icon,
                    size: isComplete ? 18 : 16,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: isComplete ? 0.7 : 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 200,
                      child: Text(
                        step.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
