import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/group_invite_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/screens/group_creation_wizard_screen.dart';
import 'package:sankofasave/screens/group_detail_screen.dart';
import 'package:sankofasave/screens/group_join_wizard_screen.dart';
import 'package:sankofasave/services/group_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/utils/user_avatar_resolver.dart';
import 'package:sankofasave/widgets/user_avatar.dart';
import 'package:sankofasave/ui/components/ui.dart';
import 'package:sankofasave/data/process_flows.dart';
import 'package:sankofasave/screens/process_flow_screen.dart';
import 'package:sankofasave/models/process_flow_model.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();
  List<SusuGroupModel> _groups = [];
  List<SusuGroupModel> _filteredGroups = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0;
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });
    final user = await _userService.getCurrentUser();
    final groups = await _groupService.getGroups(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _groups = groups;
      _currentUser = user;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _openProcess(ProcessFlowModel flow) {
    Navigator.of(context).push(
      RouteTransitions.slideUp(ProcessFlowScreen(flow: flow)),
    );
  }

  Future<void> _openCreationWizard() async {
    final createdGroup = await Navigator.of(context).push<SusuGroupModel>(
      RouteTransitions.slideUp(const GroupCreationWizardScreen()),
    );
    if (createdGroup == null) return;

    await _loadGroups();
    if (!mounted) return;
    final confirmedCount = createdGroup.memberNames.length;
    final pendingCount = createdGroup.targetMemberCount - confirmedCount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${createdGroup.name} is live – $confirmedCount confirmed, $pendingCount invites sent.',
        ),
      ),
    );
  }

  Future<void> _openJoinWizard({SusuGroupModel? preselected}) async {
    final joinedGroup = await Navigator.of(context).push<SusuGroupModel>(
      RouteTransitions.slideUp(
        GroupJoinWizardScreen(initialGroupId: preselected?.id),
      ),
    );
    if (joinedGroup == null) return;

    await _loadGroups();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome to ${joinedGroup.name}!'),
      ),
    );
  }

  void _onFilterSelected(int index, ActionChipItem item) {
    setState(() {
      _selectedFilter = index;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    final filterIndex = _selectedFilter;
    final filtered = _groups.where((group) {
      final matchesQuery = query.isEmpty || group.name.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (filterIndex == 0) {
        return true;
      }

      final progress = group.cycleNumber / group.totalCycles;
      switch (filterIndex) {
        case 1:
          return progress < 0.34;
        case 2:
          return progress >= 0.34 && progress < 0.67;
        case 3:
          return progress >= 0.67;
        default:
          return true;
      }
    }).toList();

    setState(() {
      _filteredGroups = filtered;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Susu Groups'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: _buildContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'groups_fab',
        onPressed: _openCreationWizard,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.lock_outline, color: Colors.white),
        label: const Text('Create Private Group', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 120),
        children: const [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      children: [
        _buildGroupGuideCard(),
        const SizedBox(height: 16),
        _buildSearchField(),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 20),
        if (_filteredGroups.isEmpty)
          _buildEmptyState()
        else
          ..._filteredGroups
              .map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGroupCard(group),
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildGroupGuideCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find the right Susu circle',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Browse open public groups to join or launch a private invite-only circle built around your trusted members.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: FilledButton.icon(
                  onPressed: () => _openJoinWizard(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Join a public group'),
                ),
              ),
              SizedBox(
                width: 220,
                child: OutlinedButton.icon(
                  onPressed: _openCreationWizard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.lock_person_outlined),
                  label: const Text('Create a private circle'),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextButton.icon(
                  onPressed: () => _openProcess(ProcessFlows.joinGroup),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                    foregroundColor: theme.colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('How public groups work'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
        hintText: 'Search groups by name',
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.secondary),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      ActionChipItem(label: 'All cycles', icon: Icons.all_inclusive, isSelected: _selectedFilter == 0),
      ActionChipItem(label: 'Newly started', icon: Icons.bolt, isSelected: _selectedFilter == 1),
      ActionChipItem(label: 'Mid-cycle', icon: Icons.timeline, isSelected: _selectedFilter == 2),
      ActionChipItem(label: 'Wrapping up', icon: Icons.flag_circle, isSelected: _selectedFilter == 3),
    ];
    return ActionChipRow(
      items: filters,
      onSelected: _onFilterSelected,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No groups match your filters yet',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting the search or cycle filters, or jump straight into creating a private circle tailored to your needs.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openJoinWizard,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Browse public groups'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openCreationWizard,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Start a private group'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(SusuGroupModel group) {
    final theme = Theme.of(context);
    final contribution = 'GH₵ ${NumberFormat('#,##0.00').format(group.contributionAmount)}';
    final payoutDate = DateFormat('MMM dd').format(group.nextPayoutDate);
    final progress = group.cycleNumber / group.totalCycles;
    final userId = _currentUser?.id;
    final isMember = userId != null && group.memberIds.contains(userId);
    final seatsOpen = _availableSeats(group);
    final status = progress < 0.34
        ? 'Newly started'
        : progress < 0.67
            ? 'Mid-cycle'
            : 'Wrapping up';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailScreen(groupId: group.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withValues(alpha: 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientIconBadge(
                  icon: Icons.groups,
                  colors: [theme.colorScheme.secondary, theme.colorScheme.tertiary],
                  diameter: 56,
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
                      const SizedBox(height: 4),
                      Text(
                        _buildMemberSummary(group),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (group.isPublic && group.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          group.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                height: 1.45,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'Wrapping up'
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : status == 'Mid-cycle'
                            ? theme.colorScheme.secondary.withValues(alpha: 0.12)
                            : theme.colorScheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: status == 'Wrapping up'
                          ? theme.colorScheme.primary
                          : status == 'Mid-cycle'
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMetric(
                    label: 'Contribution',
                    value: contribution,
                    icon: Icons.paid,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetric(
                    label: 'Next Payout',
                    value: payoutDate,
                    icon: Icons.event,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            if (group.frequency != null || group.location != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (group.frequency != null)
                    _buildDetailChip(
                      Icons.schedule,
                      group.frequency!,
                      theme.colorScheme.secondary,
                    ),
                  if (group.location != null)
                    _buildDetailChip(
                      Icons.location_on_outlined,
                      group.location!,
                      theme.colorScheme.tertiary,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ProgressSummaryBar(
              progress: progress,
              label: 'Cycle ${group.cycleNumber}/${group.totalCycles}',
              secondaryLabel: '${(progress * 100).toStringAsFixed(0)}% complete',
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            _buildMemberRow(group),
            if (group.invites.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInviteIndicators(group),
            ],
            if (group.isPublic) ...[
              const SizedBox(height: 16),
              _buildPublicJoinFooter(group, seatsOpen, isMember),
            ],
          ],
        ),
      ),
    );
  }

  String _buildMemberSummary(SusuGroupModel group) {
    final active = group.memberNames.length;
    final ready = group.invites
        .where((invite) => invite.status == GroupInviteStatus.accepted)
        .length;
    final pending = group.invites
        .where((invite) => invite.status == GroupInviteStatus.pending)
        .length;

    final parts = <String>['$active active'];
    if (ready > 0) {
      parts.add('$ready ready to join');
    }
    if (pending > 0) {
      parts.add('$pending pending');
    }
    if (group.isPublic) {
      final openSeats = _availableSeats(group);
      if (openSeats > 0) {
        parts.add('$openSeats open seats');
      }
    }
    return parts.join(' • ');
  }

  int _availableSeats(SusuGroupModel group) {
    final seats = group.targetMemberCount - group.memberNames.length;
    return seats < 0 ? 0 : seats;
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicJoinFooter(
    SusuGroupModel group,
    int seatsOpen,
    bool isMember,
  ) {
    final theme = Theme.of(context);
    final copy = group.requiresApproval
        ? 'Admins review each application before confirming a new seat.'
        : 'Secure your seat instantly and we will activate reminders for the next cycle.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
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
                  seatsOpen > 0
                      ? '$seatsOpen ${seatsOpen == 1 ? 'seat' : 'seats'} open for newcomers'
                      : 'Currently full – check back soon',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            copy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          if (!isMember && seatsOpen > 0) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => _openJoinWizard(preselected: group),
              child: const Text('Join this group'),
            ),
          ],
          if (isMember) ...[
            const SizedBox(height: 12),
            Text(
              'You already belong to this circle – explore the detail view for the latest activity.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberRow(SusuGroupModel group) {
    final memberCount = group.memberNames.length;
    final showExtra = memberCount > 3;
    final displayCount = showExtra ? 3 : memberCount;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          ...List.generate(displayCount, (index) {
            final memberName = group.memberNames[index];
            final asset = UserAvatarResolver.resolve(memberName);
            return Padding(
              padding: EdgeInsets.only(right: index == displayCount - 1 ? 0 : 12),
              child: UserAvatar(
                initials: memberName.substring(0, 1).toUpperCase(),
                imagePath: asset,
                size: 40,
              ),
            );
          }),
          if (showExtra)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+${memberCount - 3} more',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInviteIndicators(SusuGroupModel group) {
    final theme = Theme.of(context);
    final pendingCount = group.invites
        .where((invite) => invite.status == GroupInviteStatus.pending)
        .length;
    final kycPending = group.invites
        .where((invite) =>
            invite.status != GroupInviteStatus.declined && !invite.kycCompleted)
        .length;
    final accepted = group.invites
        .where((invite) => invite.status == GroupInviteStatus.accepted)
        .length;
    final blockers = (group.targetMemberCount -
            (group.memberNames.length + accepted))
        .clamp(0, group.targetMemberCount);

    final chips = <Widget>[];
    if (pendingCount > 0) {
      chips.add(
        _GroupInsightChip(
          icon: Icons.hourglass_bottom,
          label:
              '$pendingCount invite${pendingCount == 1 ? '' : 's'} pending',
          foreground: theme.colorScheme.tertiary,
          background: theme.colorScheme.tertiary.withValues(alpha: 0.12),
        ),
      );
    }
    if (kycPending > 0) {
      chips.add(
        _GroupInsightChip(
          icon: Icons.verified_outlined,
          label:
              '$kycPending KYC ${kycPending == 1 ? 'check' : 'checks'} outstanding',
          foreground: theme.colorScheme.primary,
          background: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      );
    }
    chips.add(
      _GroupInsightChip(
        icon: blockers > 0 ? Icons.warning_rounded : Icons.rocket_launch,
        label: blockers > 0
            ? '$blockers slot${blockers == 1 ? '' : 's'} blocking kickoff'
            : 'Cycle ready to launch',
        foreground: blockers > 0
            ? theme.colorScheme.error
            : theme.colorScheme.secondary,
        background: blockers > 0
            ? theme.colorScheme.error.withValues(alpha: 0.12)
            : theme.colorScheme.secondary.withValues(alpha: 0.12),
      ),
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips,
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    bool alignEnd = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _GroupInsightChip extends StatelessWidget {
  const _GroupInsightChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
