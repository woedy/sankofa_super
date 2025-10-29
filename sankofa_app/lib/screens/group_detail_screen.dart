import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/group_invite_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/transaction_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/services/group_service.dart';
import 'package:sankofasave/services/transaction_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/ui/components/ui.dart';
import 'package:sankofasave/utils/route_transitions.dart';
import 'package:sankofasave/utils/user_avatar_resolver.dart';
import 'package:sankofasave/widgets/user_avatar.dart';
import 'package:sankofasave/screens/contribution_receipt_screen.dart';
import 'package:sankofasave/screens/group_join_wizard_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupService _groupService = GroupService();
  final TransactionService _transactionService = TransactionService();
  final UserService _userService = UserService();
  final GlobalKey<FormState> _contributionFormKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  List<TransactionModel> _contributionHistory = [];
  final Set<String> _remindingInviteIds = <String>{};
  final Set<String> _promotingInviteIds = <String>{};
  bool _isSubmittingContribution = false;
  SusuGroupModel? _group;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _loadGroup();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final user = await _userService.getCurrentUser();
    final group = await _groupService.getGroupById(widget.groupId);
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _group = group;
      if (group != null) {
        _amountController.text = group.contributionAmount.toStringAsFixed(2);
      }
    });
    if (group != null) {
      await _loadContributionHistory(group);
    }
  }

  Future<void> _loadContributionHistory(SusuGroupModel group) async {
    final transactions = await _transactionService.getTransactions();
    final contributions = transactions
        .where(
          (transaction) =>
              transaction.type == 'contribution' &&
              transaction.description.contains(group.name),
        )
        .toList();
    if (!mounted) return;
    setState(() {
      _contributionHistory = contributions;
    });
  }

  bool get _isCurrentUserMember {
    final userId = _currentUser?.id;
    final group = _group;
    if (group == null || userId == null) return false;
    return group.memberIds.contains(userId);
  }

  int get _availablePublicSeats {
    final group = _group;
    if (group == null) return 0;
    final seats = group.targetMemberCount - group.memberNames.length;
    return seats < 0 ? 0 : seats;
  }

  Future<void> _launchJoinWizard() async {
    final group = _group;
    if (group == null) return;
    final updatedGroup = await Navigator.of(context).push<SusuGroupModel>(
      RouteTransitions.slideUp(
        GroupJoinWizardScreen(initialGroupId: group.id),
      ),
    );
    if (updatedGroup == null) return;

    if (!mounted) return;
    setState(() {
      _group = updatedGroup;
    });
    await _loadContributionHistory(updatedGroup);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome to ${updatedGroup.name}!')),
    );
  }

  Future<void> _sendInviteReminder(GroupInviteModel invite) async {
    if (_group == null) return;
    setState(() {
      _remindingInviteIds.add(invite.id);
    });

    try {
      final updatedGroup =
          await _groupService.logInviteReminder(_group!.id, invite.id);
      if (!mounted) return;
      setState(() {
        _group = updatedGroup ?? _group;
        _remindingInviteIds.remove(invite.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder queued for ${invite.name}.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _remindingInviteIds.remove(invite.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: const Text('Failed to send reminder. Please try again.'),
        ),
      );
    }
  }

  Future<void> _promoteInviteToMember(GroupInviteModel invite) async {
    if (_group == null) return;
    setState(() {
      _promotingInviteIds.add(invite.id);
    });

    try {
      final updatedGroup =
          await _groupService.convertInviteToMember(
        groupId: _group!.id,
        inviteId: invite.id,
      );
      if (!mounted) return;
      setState(() {
        _group = updatedGroup ?? _group;
        _promotingInviteIds.remove(invite.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${invite.name} has been added to the roster.'),
        ),
      );
      if (_group != null) {
        await _loadContributionHistory(_group!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _promotingInviteIds.remove(invite.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: const Text('Unable to confirm invite. Try again later.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_group!.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildHeroHeader(context),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_group!.isPublic) ...[
                      _buildPublicOverviewCard(context),
                      const SizedBox(height: 16),
                      _buildJoinCallout(context),
                      const SizedBox(height: 20),
                    ],
                    _buildProgressSection(context),
                    const SizedBox(height: 20),
                    _buildTimelineSection(context),
                    const SizedBox(height: 20),
                    _buildMemberRoster(context),
                    if (_group!.invites.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildInviteProgress(context),
                    ],
                    const SizedBox(height: 20),
                    _buildContributionHistory(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _isSubmittingContribution ? null : () => _handleContributionButtonPressed(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isSubmittingContribution
                    ? 'Processing...'
                    : _isCurrentUserMember
                        ? 'Contribute Now'
                        : 'Join to contribute',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final totalPool = _group!.contributionAmount * _group!.targetMemberCount;
    final confirmed = _group!.memberNames.length;
    final accepted = _group!.invites
        .where((invite) => invite.status == GroupInviteStatus.accepted)
        .length;
    final readyCount = confirmed + accepted;
    final remainingSlots =
        (_group!.targetMemberCount - readyCount).clamp(0, _group!.targetMemberCount);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pool',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatCurrency(totalPool),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  context,
                  label: 'Cycle Progress',
                  value: '${_group!.cycleNumber}/${_group!.totalCycles}',
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _buildHeroStat(
                  context,
                  label: 'Next Payout',
                  value: DateFormat('MMM dd').format(_group!.nextPayoutDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroChip(
                theme,
                icon: Icons.groups_2,
                label: '$readyCount/${_group!.targetMemberCount} seats ready',
              ),
              if (remainingSlots > 0)
                _buildHeroChip(
                  theme,
                  icon: Icons.timelapse,
                  label: '$remainingSlots acceptance${remainingSlots == 1 ? '' : 's'} outstanding',
                ),
              if (_group!.isPublic)
                _buildHeroChip(
                  theme,
                  icon: Icons.public,
                  label: 'Public circle',
                ),
              if (_group!.requiresApproval)
                _buildHeroChip(
                  theme,
                  icon: Icons.verified_user_outlined,
                  label: 'Admin reviewed',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicOverviewCard(BuildContext context) {
    final group = _group!;
    return InfoCard(
      title: 'Group overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.description != null) ...[
            Text(
              group.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75), height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          InfoRow(
            label: 'Contribution cadence',
            value: group.frequency ?? 'Rotational schedule',
          ),
          InfoRow(
            label: 'Seats available',
            value: '${_availablePublicSeats} of ${group.targetMemberCount}',
          ),
          if (group.location != null)
            InfoRow(
              label: 'Community location',
              value: group.location!,
            ),
          InfoRow(
            label: 'Access type',
            value: group.requiresApproval ? 'Admin approval required' : 'Instant join',
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCallout(BuildContext context) {
    if (!_group!.isPublic) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final seats = _availablePublicSeats;
    final isMember = _isCurrentUserMember;
    final copy = isMember
        ? 'You already hold a seat in this circle. Keep contributing consistently to stay in good standing.'
        : seats > 0
            ? (_group!.requiresApproval
                ? 'Submit your request below and the admins will review it before confirming your spot.'
                : 'Secure your seat now to start contributing in the upcoming cycle.')
            : 'All seats are filled for now. Check back soon or explore other circles on the Groups tab.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_add_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMember
                      ? 'You\'re in!'
                      : seats > 0
                          ? '$seats ${seats == 1 ? 'seat' : 'seats'} open for newcomers'
                          : 'Circle is currently full',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            copy,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          if (!isMember) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: seats > 0 ? _launchJoinWizard : null,
              child: Text(seats > 0 ? 'Join this group' : 'Seats unavailable'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _group!.cycleNumber / _group!.totalCycles;
    final percentage = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return InfoCard(
      title: 'Progress Snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cycle ${_group!.cycleNumber} of ${_group!.totalCycles}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payout order: ${_group!.payoutOrder}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percentage%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ProgressSummaryBar(
            progress: progress,
            label: 'Contribution round in progress',
            secondaryLabel:
                'Next payout on ${DateFormat('MMM dd, yyyy').format(_group!.nextPayoutDate)}',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    final stages = _mapProgressStages();
    return InfoCard(
      title: 'Group Timeline',
      child: Column(
        children: [
          for (var i = 0; i < stages.length; i++)
            _buildTimelineItem(context, stages[i], isLast: i == stages.length - 1),
        ],
      ),
    );
  }

  List<_TimelineStage> _mapProgressStages() {
    final now = DateTime.now();
    final payoutCountdown = _group!.nextPayoutDate.difference(now).inDays;
    final memberCount = _group!.memberNames.length;
    final hasConfirmedMembers = memberCount > 0;
    final nextRecipientIndex = hasConfirmedMembers
        ? (_group!.cycleNumber - 1).clamp(0, memberCount - 1)
        : null;
    final nextRecipientName = hasConfirmedMembers
        ? _group!.memberNames[nextRecipientIndex!]
        : 'Awaiting roster confirmation';
    final isFinalCycle = hasConfirmedMembers &&
        _group!.cycleNumber >= _group!.totalCycles;

    return [
      _TimelineStage(
        title: 'Circle launched',
        subtitle: DateFormat('MMM dd, yyyy').format(_group!.createdAt),
        status: _TimelineStatus.complete,
      ),
      _TimelineStage(
        title: hasConfirmedMembers
            ? 'Cycle ${_group!.cycleNumber} contributions'
            : 'Roster building in progress',
        subtitle: hasConfirmedMembers
            ? 'Members send GH₵ ${_group!.contributionAmount.toStringAsFixed(2)} weekly.'
            : 'Admin approvals pending before the first contribution round.',
        status:
            hasConfirmedMembers ? _TimelineStatus.active : _TimelineStatus.upcoming,
      ),
      _TimelineStage(
        title: 'Next payout · $nextRecipientName',
        subtitle: hasConfirmedMembers
            ? (payoutCountdown >= 0
                ? '$payoutCountdown days remaining'
                : 'Payout processed recently')
            : 'Once members are confirmed, payouts will be scheduled.',
        status: hasConfirmedMembers
            ? (isFinalCycle ? _TimelineStatus.complete : _TimelineStatus.upcoming)
            : _TimelineStatus.upcoming,
      ),
      _TimelineStage(
        title: isFinalCycle ? 'Wrap-up & celebration' : 'Prep for cycle ${_group!.cycleNumber + 1}',
        subtitle: isFinalCycle
            ? 'Finalize savings recap and plan next Susu goals.'
            : 'Rotate positions and brief members ahead of the next round.',
        status: _TimelineStatus.upcoming,
      ),
    ];
  }

  Widget _buildTimelineItem(
    BuildContext context,
    _TimelineStage stage, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final color = switch (stage.status) {
      _TimelineStatus.complete => theme.colorScheme.secondary,
      _TimelineStatus.active => theme.colorScheme.primary,
      _TimelineStatus.upcoming => theme.colorScheme.outline.withValues(alpha: 0.45),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stage.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberRoster(BuildContext context) {
    final theme = Theme.of(context);
    final members = _group!.memberNames;

    if (members.isEmpty) {
      return InfoCard(
        title: 'Member Roster',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text(
            'No confirmed members yet. Approvals will appear here once invites are accepted.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    final currentTurnIndex = (_group!.cycleNumber - 1).clamp(0, members.length - 1);

    return InfoCard(
      title: 'Member Roster',
      child: Column(
        children: [
          for (var index = 0; index < members.length; index++) ...[
            _buildMemberRosterRow(
              context,
              memberName: members[index],
              memberIndex: index,
              currentTurnIndex: currentTurnIndex,
              isLast: index == members.length - 1,
            ),
            if (index != members.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteProgress(BuildContext context) {
    final theme = Theme.of(context);
    final invites = _group!.invites;
    final pendingCount = invites
        .where((invite) => invite.status == GroupInviteStatus.pending)
        .length;
    final acceptedCount = invites
        .where((invite) => invite.status == GroupInviteStatus.accepted)
        .length;
    final declinedCount = invites
        .where((invite) => invite.status == GroupInviteStatus.declined)
        .length;
    final kycCleared = invites.where((invite) => invite.kycCompleted).length;
    final readyCount = _group!.memberNames.length + acceptedCount;
    final blockers = (_group!.targetMemberCount - readyCount)
        .clamp(0, _group!.targetMemberCount);

    return InfoCard(
      title: 'Invite Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInviteSummaryChip(
                theme,
                icon: Icons.rule_folder,
                label: '$kycCleared/${invites.length} KYC cleared',
                foreground: theme.colorScheme.primary,
                background: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
              if (pendingCount > 0)
                _buildInviteSummaryChip(
                  theme,
                  icon: Icons.hourglass_bottom,
                  label:
                      '$pendingCount awaiting acceptance',
                  foreground: theme.colorScheme.tertiary,
                  background:
                      theme.colorScheme.tertiary.withValues(alpha: 0.12),
                ),
              if (declinedCount > 0)
                _buildInviteSummaryChip(
                  theme,
                  icon: Icons.sentiment_dissatisfied,
                  label:
                      '$declinedCount declined',
                  foreground: theme.colorScheme.error,
                  background: theme.colorScheme.error.withValues(alpha: 0.12),
                ),
              _buildInviteSummaryChip(
                theme,
                icon: blockers > 0
                    ? Icons.warning_amber_outlined
                    : Icons.rocket_launch,
                label: blockers > 0
                    ? '$blockers acceptance${blockers == 1 ? '' : 's'} blocking kickoff'
                    : 'Launch-ready roster',
                foreground: blockers > 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.secondary,
                background: blockers > 0
                    ? theme.colorScheme.error.withValues(alpha: 0.12)
                    : theme.colorScheme.secondary.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < invites.length; i++) ...[
            _buildInviteTile(invites[i]),
            if (i != invites.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberRosterRow(
    BuildContext context, {
    required String memberName,
    required int memberIndex,
    required int currentTurnIndex,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final asset = UserAvatarResolver.resolve(memberName);
    final isCompleted = memberIndex < currentTurnIndex;
    final isNext = memberIndex == currentTurnIndex;
    final stageColor = isCompleted
        ? theme.colorScheme.secondary
        : isNext
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final stageIcon = isCompleted
        ? Icons.check_circle_rounded
        : isNext
            ? Icons.schedule_rounded
            : Icons.calendar_today_rounded;
    final stageLabel = isCompleted
        ? 'Payout completed in cycle ${memberIndex + 1}'
        : isNext
            ? 'Collects on ${DateFormat('MMM dd').format(_group!.nextPayoutDate)}'
            : 'Queued for cycle ${memberIndex + 1}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.06),
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTurnCard(theme, turn: memberIndex + 1, isCompleted: isCompleted, isNext: isNext),
          const SizedBox(width: 16),
          UserAvatar(
            initials: memberName.substring(0, 1).toUpperCase(),
            imagePath: asset,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(height: 8),
                  _buildNextPayoutBadge(theme),
                ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(stageIcon, size: 18, color: stageColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stageLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: stageColor,
                          fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSummaryChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTile(GroupInviteModel invite) {
    final theme = Theme.of(context);
    final asset = UserAvatarResolver.resolve(invite.name);
    final isPending = invite.status == GroupInviteStatus.pending;
    final isAccepted = invite.status == GroupInviteStatus.accepted;
    final isDeclined = invite.status == GroupInviteStatus.declined;
    final reminderLoading = _remindingInviteIds.contains(invite.id);
    final promoteLoading = _promotingInviteIds.contains(invite.id);

    Color statusColor;
    switch (invite.status) {
      case GroupInviteStatus.accepted:
        statusColor = theme.colorScheme.secondary;
        break;
      case GroupInviteStatus.declined:
        statusColor = theme.colorScheme.error;
        break;
      case GroupInviteStatus.pending:
      default:
        statusColor = theme.colorScheme.tertiary;
    }

    final chips = <Widget>[
      _buildInviteStatusChip(
        theme,
        icon: isDeclined
            ? Icons.cancel_outlined
            : isAccepted
                ? Icons.check_circle
                : Icons.hourglass_empty,
        label: invite.status.displayLabel,
        foreground: statusColor,
        background: statusColor.withValues(alpha: 0.14),
      ),
      _buildInviteStatusChip(
        theme,
        icon: invite.kycCompleted
            ? Icons.verified_outlined
            : Icons.assignment_late_outlined,
        label: invite.kycCompleted ? 'KYC verified' : 'KYC pending',
        foreground: invite.kycCompleted
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.8),
        background: invite.kycCompleted
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      _buildInviteStatusChip(
        theme,
        icon: Icons.mark_email_read_outlined,
        label: 'Sent ${DateFormat('MMM dd').format(invite.sentAt)}',
        foreground: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        background: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
      ),
    ];

    if (invite.lastRemindedAt != null) {
      chips.add(
        _buildInviteStatusChip(
          theme,
          icon: Icons.campaign_outlined,
          label:
              'Reminded ${DateFormat('MMM dd').format(invite.lastRemindedAt!)}',
          foreground: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          background:
              theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
        ),
      );
    }

    if (invite.respondedAt != null && !isPending) {
      chips.add(
        _buildInviteStatusChip(
          theme,
          icon: Icons.event_available_outlined,
          label:
              'Responded ${DateFormat('MMM dd').format(invite.respondedAt!)}',
          foreground: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          background:
              theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
        ),
      );
    }

    final actions = <Widget>[];
    if (!isDeclined) {
      actions.add(
        TextButton.icon(
          onPressed: reminderLoading ? null : () => _sendInviteReminder(invite),
          icon: reminderLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
              : const Icon(Icons.sms_outlined),
          label: Text(reminderLoading ? 'Sending...' : 'Send reminder'),
        ),
      );
    }

    if (isAccepted) {
      actions.add(
        OutlinedButton.icon(
          onPressed:
              promoteLoading ? null : () => _promoteInviteToMember(invite),
          icon: promoteLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.secondary,
                    ),
                  ),
                )
              : const Icon(Icons.person_add_alt_1),
          label: Text(promoteLoading ? 'Adding...' : 'Confirm join'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                initials: invite.name.substring(0, 1).toUpperCase(),
                imagePath: asset,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invite.phoneNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips,
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteStatusChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnCard(
    ThemeData theme, {
    required int turn,
    required bool isCompleted,
    required bool isNext,
  }) {
    final gradient = isCompleted || isNext
        ? LinearGradient(
            colors: isNext
                ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]
                : [
                    theme.colorScheme.secondary,
                    theme.colorScheme.primary,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final backgroundColor = gradient == null
        ? theme.colorScheme.surfaceVariant.withValues(alpha: 0.6)
        : null;

    final textColor = gradient == null
        ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
        : Colors.white;

    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: gradient == null
            ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Turn',
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$turn',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPayoutBadge(ThemeData theme) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary,
              theme.colorScheme.primary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Next payout',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _buildContributionHistory(BuildContext context) {
    if (_contributionHistory.isEmpty) {
      return InfoCard(
        title: 'Contribution History',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No contributions recorded yet. Your next payment will appear here instantly.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ),
      );
    }

    return InfoCard(
      title: 'Contribution History',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _contributionHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildContributionTile(_contributionHistory[index]),
      ),
    );
  }

  Widget _buildContributionTile(TransactionModel transaction) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCurrency(transaction.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  transaction.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transaction.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM dd, yyyy · hh:mm a').format(transaction.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showContributionSheet() async {
    final user = await _userService.getCurrentUser();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        Widget buildHeroChip(String label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            );

        final contributionHint = _formatCurrency(_group!.contributionAmount);
        final cycleLabel = 'Cycle ${_group!.cycleNumber} of ${_group!.totalCycles}';
        final payoutLabel =
            'Next payout ${DateFormat('MMM dd').format(_group!.nextPayoutDate)}';
        final walletBalanceText =
            user != null ? _formatCurrency(user.walletBalance) : 'GH₵ --';
        final parsedAmount = double.tryParse(_amountController.text.trim());
        final projectedBalance = user != null && parsedAmount != null
            ? (user.walletBalance - parsedAmount).clamp(0, double.infinity).toDouble()
            : null;
        final outlineBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.35),
          ),
        );

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ModalScaffold(
            child: Form(
              key: _contributionFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 16, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
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
                                    'Contribute to ${_group!.name}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Align your turn-in with the circle and keep the momentum going.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.white,
                              splashRadius: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            buildHeroChip(cycleLabel),
                            buildHeroChip(payoutLabel),
                            buildHeroChip('Suggested $contributionHint'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Contribution details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Amount (GH₵)',
                            hintText: contributionHint,
                            prefixIcon: const Icon(Icons.payments_rounded),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.35),
                            border: outlineBorder,
                            enabledBorder: outlineBorder,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            helperText: 'Edit the amount if you need to top up or adjust.',
                          ),
                          validator: (value) {
                            final normalized = value?.trim() ?? '';
                            if (normalized.isEmpty) {
                              return 'Enter an amount';
                            }
                            final amount = double.tryParse(normalized);
                            if (amount == null || amount <= 0) {
                              return 'Amount must be greater than zero';
                            }
                            final balance = user?.walletBalance ?? 0;
                            if (amount > balance) {
                              return 'Insufficient wallet balance (GH₵ ${balance.toStringAsFixed(2)})';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 42,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 22,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wallet balance',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      walletBalanceText,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: projectedBalance != null
                                          ? Padding(
                                              key: ValueKey(projectedBalance.toStringAsFixed(2)),
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Projected after send · ${_formatCurrency(projectedBalance)}',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_contributionFormKey.currentState!.validate()) {
                                return;
                              }
                              final amount = double.parse(_amountController.text.trim());
                              Navigator.pop(context);
                              await _handleContribution(amount, user);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Confirm Contribution'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleContributionButtonPressed() async {
    if (_isSubmittingContribution) {
      return;
    }

    if (_isCurrentUserMember) {
      await _showContributionSheet();
      return;
    }

    final group = _group;
    if (group == null || !mounted) {
      return;
    }

    if (group.isPublic && _availablePublicSeats > 0) {
      await _launchJoinWizard();
      return;
    }

    final copy = group.isPublic
        ? 'All seats are currently filled. You\'ll be able to contribute once your spot opens up.'
        : 'Only members can contribute to this susu group. Ask the admin to add you before sending funds.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copy)),
    );
  }

  Future<void> _handleContribution(double amount, UserModel? user) async {
    setState(() => _isSubmittingContribution = true);
    final now = DateTime.now();

    try {
      double? remainingBalance;
      if (user != null) {
        final newBalance = (user.walletBalance - amount).clamp(0, double.infinity).toDouble();
        await _userService.updateWalletBalance(newBalance);
        remainingBalance = newBalance;
      }

      final transaction = TransactionModel(
        id: 'txn_${now.millisecondsSinceEpoch}',
        userId: user?.id ?? 'user_001',
        amount: amount,
        type: 'contribution',
        status: 'success',
        description: 'Contribution to ${_group!.name}',
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await _transactionService.addTransaction(transaction);

      final updatedGroup = _group!.copyWith(updatedAt: now);
      await _groupService.updateGroup(updatedGroup);

      setState(() {
        _group = updatedGroup;
      });

      await _loadContributionHistory(updatedGroup);

      if (!mounted) return;
      Navigator.of(context).push(
        RouteTransitions.slideUp(
          ContributionReceiptScreen(
            transaction: transaction,
            group: updatedGroup,
            remainingBalance: remainingBalance ?? user?.walletBalance ?? 0,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to record contribution. Please try again. ($error)'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSubmittingContribution = false);
    }
  }

  String _formatCurrency(double amount) =>
      'GH₵ ${NumberFormat('#,##0.00').format(amount)}';
}

enum _TimelineStatus { complete, active, upcoming }

class _TimelineStage {
  _TimelineStage({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final _TimelineStatus status;
}
