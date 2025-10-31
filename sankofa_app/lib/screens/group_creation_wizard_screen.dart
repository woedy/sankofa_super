import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/group_draft_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/services/auth_service.dart';
import 'package:sankofasave/services/group_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/ui/components/ui.dart';
import 'package:sankofasave/utils/ghana_phone_formatter.dart';

class GroupCreationWizardScreen extends StatefulWidget {
  const GroupCreationWizardScreen({super.key});

  @override
  State<GroupCreationWizardScreen> createState() =>
      _GroupCreationWizardScreenState();
}

class _GroupCreationWizardScreenState
    extends State<GroupCreationWizardScreen> {
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();

  final GlobalKey<FormState> _blueprintFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _rulesFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberPhoneController = TextEditingController();

  GroupDraftModel? _draft;
  UserModel? _currentUser;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showDraftRestoredBanner = false;
  bool _isPickingContact = false;

  int _currentStep = 0;
  String _frequency = 'Weekly';
  DateTime? _startDate;
  final List<GroupInviteDraft> _invites = [];
  final AuthService _authService = AuthService();

  final List<String> _steps = const [
    'Blueprint',
    'Contribution rules',
    'Invite circle',
    'Review & confirm',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await _userService.getCurrentUser();
    final draft = await _groupService.getDraftGroup();

    if (!mounted) return;

    if (draft != null) {
      _nameController.text = draft.name ?? '';
      _purposeController.text = draft.purpose ?? '';
      if (draft.contributionAmount != null) {
        _amountController.text = _formatAmountInput(draft.contributionAmount!);
      }
      if (draft.startDate != null) {
        _startDate = draft.startDate;
        _startDateController.text = DateFormat('MMM d, yyyy').format(draft.startDate!);
      }
      if (draft.frequency != null) {
        _frequency = draft.frequency!;
      }
      _invites
        ..clear()
        ..addAll(draft.invites);
      _draft = draft;
      _showDraftRestoredBanner = true;
    }

    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  String _formatAmountInput(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  double? _parseAmount() {
    final raw = _amountController.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  bool get _hasDraftData =>
      _nameController.text.trim().isNotEmpty ||
      _purposeController.text.trim().isNotEmpty ||
      _amountController.text.trim().isNotEmpty ||
      _startDate != null ||
      _invites.isNotEmpty;

  Future<void> _persistDraft() async {
    final now = DateTime.now();
    final id = _draft?.id ?? 'draft_${now.millisecondsSinceEpoch}';
    final draft = GroupDraftModel(
      id: id,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      purpose: _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim(),
      contributionAmount: _parseAmount(),
      frequency: _frequency,
      startDate: _startDate,
      invites: List<GroupInviteDraft>.from(_invites),
      createdAt: _draft?.createdAt ?? now,
      updatedAt: now,
    );
    await _groupService.saveDraftGroup(draft);
    if (!mounted) return;
    setState(() {
      _draft = draft;
    });
  }

  Future<void> _resetDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard draft?'),
        content: const Text(
          'This will clear all the details you\'ve entered for this private group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _groupService.clearDraftGroup();
    if (!mounted) return;

    setState(() {
      _draft = null;
      _nameController.clear();
      _purposeController.clear();
      _amountController.clear();
      _startDateController.clear();
      _memberNameController.clear();
      _memberPhoneController.clear();
      _invites.clear();
      _startDate = null;
      _frequency = 'Weekly';
      _currentStep = 0;
      _showDraftRestoredBanner = false;
    });
  }

  @override
  void dispose() {
    if (_hasDraftData) {
      _persistDraft();
    } else {
      _groupService.clearDraftGroup();
    }
    _nameController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _startDateController.dispose();
    _memberNameController.dispose();
    _memberPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final initialDate = _startDate ?? DateTime.now().add(const Duration(days: 7));
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: initialDate,
    );
    if (selected == null) return;
    setState(() {
      _startDate = selected;
      _startDateController.text = DateFormat('MMM d, yyyy').format(selected);
    });
    await _persistDraft();
  }

  Future<void> _goToNextStep() async {
    if (_currentStep == 0) {
      final isValid = _blueprintFormKey.currentState?.validate() ?? false;
      if (!isValid) return;
      await _persistDraft();
      if (!mounted) return;
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      final isValid = _rulesFormKey.currentState?.validate() ?? false;
      if (!isValid) return;
      if (_startDate == null) {
        _showMessage('Select the first payout date to continue.');
        return;
      }
      await _persistDraft();
      if (!mounted) return;
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      if (_invites.length < 2) {
        _showMessage(
          'Add at least two invitees so the circle has enough members to rotate payouts.',
        );
        return;
      }
      final hasMissingPhone =
          _invites.any((invite) => invite.phoneNumber.trim().isEmpty || invite.name.trim().isEmpty);
      if (hasMissingPhone) {
        _showMessage('Make sure every invite has a name and phone number.');
        return;
      }
      await _persistDraft();
      if (!mounted) return;
      setState(() => _currentStep = 3);
      return;
    }

    await _handleSubmit();
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  Future<void> _handleSubmit() async {
    if (_isSaving) return;
    await _persistDraft();
    final draft = _draft;
    if (draft == null) {
      _showMessage('Something went wrong while loading your account.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final created = await _groupService.createGroupFromDraft(draft);
      if (!mounted) return;
      Navigator.of(context).pop<SusuGroupModel>(created);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('We couldn\'t finish setting up the group. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addManualInvite() {
    final name = _memberNameController.text.trim();
    final phoneInput = _memberPhoneController.text.trim();
    if (name.isEmpty || phoneInput.isEmpty) {
      _showMessage('Enter a name and phone number to add someone.');
      return;
    }

    final normalizedPhone = _authService.normalizePhone(phoneInput);
    _addInvite(
      GroupInviteDraft(
        name: name,
        phoneNumber: normalizedPhone,
        source: 'manual',
      ),
      onSuccess: () {
        _memberNameController.clear();
        _memberPhoneController.clear();
      },
    );
  }

  Future<void> _importFromContacts() async {
    if (_isPickingContact) return;
    setState(() => _isPickingContact = true);
    try {
      // Request permission
      if (!await FlutterContacts.requestPermission()) {
        _showMessage('Enable contact access to import invites from your address book.');
        return;
      }

      // Pick a contact
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) {
        return;
      }

      // Get the full contact with phones
      final fullContact = await FlutterContacts.getContact(contact.id);
      if (fullContact == null || fullContact.phones.isEmpty) {
        _showMessage('The selected contact does not have a phone number.');
        return;
      }

      // Get the first phone number
      final phoneNumber = fullContact.phones.first.number.trim();
      if (phoneNumber.isEmpty) {
        _showMessage('The selected contact does not have a phone number.');
        return;
      }

      final normalizedPhone = _authService.normalizePhone(phoneNumber);
      final name = fullContact.displayName.trim();

      _addInvite(
        GroupInviteDraft(
          name: name.isNotEmpty ? name : normalizedPhone,
          phoneNumber: normalizedPhone,
          source: 'contact',
        ),
      );
    } catch (error) {
      _showMessage('We couldn\'t open your contacts right now. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isPickingContact = false);
      }
    }
  }

  void _addInvite(GroupInviteDraft invite, {VoidCallback? onSuccess}) {
    final normalizedPhone = invite.phoneNumber.trim();
    if (_invites.any((existing) => existing.phoneNumber == normalizedPhone)) {
      _showMessage('That phone number is already on your invite list.');
      return;
    }
    setState(() {
      _invites.add(invite);
    });
    _persistDraft();
    onSuccess?.call();
  }

  void _removeInvite(GroupInviteDraft invite) {
    setState(() {
      _invites.removeWhere(
        (entry) =>
            entry.phoneNumber == invite.phoneNumber && entry.name.toLowerCase() == invite.name.toLowerCase(),
      );
    });
    _persistDraft();
  }

  void _reorderInvite(int oldIndex, int newIndex) {
    if (oldIndex == newIndex || oldIndex < 0 || newIndex < 0 || oldIndex >= _invites.length) {
      return;
    }

    final clampedIndex = newIndex.clamp(0, _invites.length - 1);
    final targetIndex = clampedIndex is int ? clampedIndex : clampedIndex.toInt();
    setState(() {
      final invite = _invites.removeAt(oldIndex);
      _invites.insert(targetIndex, invite);
    });
    _persistDraft();
  }

  String _formatPhoneForDisplay(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return '';
    }
    final normalized = _authService.normalizePhone(phoneNumber);
    if (normalized.startsWith('+233') && normalized.length >= 4) {
      final local = '0${normalized.substring(4)}';
      return GhanaPhoneNumberFormatter.formatForDisplay(local);
    }
    return GhanaPhoneNumberFormatter.formatForDisplay(normalized);
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_steps.length, (index) {
        final isActive = index == _currentStep;
        final isComplete = index < _currentStep;
        final background = isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surface;
        final borderColor = isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withValues(alpha: isComplete ? 0.3 : 0.14);
        final labelColor = isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: isComplete ? 0.7 : 0.5);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isComplete
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isComplete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                child: isComplete
                    ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
                    : Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Text(
                _steps[index],
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: labelColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBlueprintStep() {
    final theme = Theme.of(context);
    return Form(
      key: _blueprintFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s the vision for this circle?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Give your private Susu a memorable name and optional focus so members understand the purpose from day one.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Group name',
              hintText: 'e.g. East Legon Business Circle',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a group name to continue.';
              }
              if (value.trim().length < 3) {
                return 'The name should be at least 3 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _purposeController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Purpose (optional)',
              hintText: 'Share the story or focus guiding this circle',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRulesStep() {
    final theme = Theme.of(context);
    return Form(
      key: _rulesFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set the contribution rhythm',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Lock in how much everyone contributes, how often funds rotate, and when the first payout begins.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Monthly contribution (GH₵)',
              hintText: 'Enter amount per member',
            ),
            validator: (value) {
              final parsed = _parseAmount();
              if (parsed == null) {
                return 'Enter the contribution amount.';
              }
              if (parsed <= 0) {
                return 'Contribution must be greater than zero.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: const InputDecoration(labelText: 'Rotation cadence'),
            items: const [
              DropdownMenuItem(value: 'Weekly', child: Text('Weekly rotation')),
              DropdownMenuItem(value: 'Bi-weekly', child: Text('Bi-weekly rotation')),
              DropdownMenuItem(value: 'Monthly', child: Text('Monthly rotation')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _frequency = value);
              _persistDraft();
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _startDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'First payout date',
              hintText: 'Pick the kickoff date',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: _pickStartDate,
            validator: (value) {
              if (_startDate == null) {
                return 'Choose when payouts should begin.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvitesStep() {
    final theme = Theme.of(context);
    final ownerName = _currentUser?.name ?? 'You';
    final ownerPhone = _currentUser?.phone ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who\'s joining this circle?',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Add the trusted friends or family members you plan to invite. We\'ll automatically include you as the admin.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        InfoCard(
          title: 'Member roster',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInviteSummaryRow(
                name: ownerName,
                phone: ownerPhone,
                leadingIcon: Icons.star_rounded,
                badgeLabel: 'Admin',
              ),
              if (_invites.isNotEmpty) const Divider(height: 24),
              if (_invites.isEmpty)
                Text(
                  'No invites yet — add at least two friends to kick things off.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                )
              else
                for (var i = 0; i < _invites.length; i++)
                  _buildInviteSummaryRow(
                    name: _invites[i].name,
                    phone: _invites[i].phoneNumber,
                    source: _invites[i].source,
                    onRemove: () => _removeInvite(_invites[i]),
                    onMoveUp: i > 0 ? () => _reorderInvite(i, i - 1) : null,
                    onMoveDown: i < _invites.length - 1 ? () => _reorderInvite(i, i + 1) : null,
                  ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isPickingContact ? null : _importFromContacts,
          icon: _isPickingContact
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                  ),
                )
              : const Icon(Icons.perm_contact_cal_outlined),
          label: const Text('Add from contacts'),
        ),
        const SizedBox(height: 16),
        Text(
          'Add someone manually',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _memberNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full name',
            hintText: 'e.g. Ama Darko',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _memberPhoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            const GhanaPhoneNumberFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: 'e.g. 024 123 4567',
          ),
          onSubmitted: (_) => _addManualInvite(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _addManualInvite,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add to invites'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Need at least two invitees so the rotation can begin. You can always add more later.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final amount = _parseAmount();
    final currency = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');
    final ownerName = _currentUser?.name ?? 'You';
    final ownerPhone = _currentUser?.phone ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your circle details',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Take a final look before launching. You can tweak anything by jumping back to the earlier steps.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        InfoCard(
          title: 'Circle snapshot',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(label: 'Group name', value: _nameController.text.trim()),
              if (_purposeController.text.trim().isNotEmpty)
                InfoRow(
                  label: 'Purpose',
                  value: _purposeController.text.trim(),
                ),
              InfoRow(
                label: 'Contribution',
                value: amount != null ? currency.format(amount) : '—',
              ),
              InfoRow(label: 'Cadence', value: _frequency),
              InfoRow(
                label: 'First payout',
                value: _startDate != null
                    ? DateFormat('MMM d, yyyy').format(_startDate!)
                    : '—',
              ),
              InfoRow(
                label: 'Members',
                value: '${_invites.length + 1} people',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'Payout order',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemberLine(ownerName, ownerPhone, isAdmin: true),
              const Divider(height: 24),
              ..._invites.map((invite) => _buildMemberLine(invite.name, invite.phoneNumber)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberLine(String name, String phone, {bool isAdmin = false}) {
    final theme = Theme.of(context);
    final formattedPhone = _formatPhoneForDisplay(phone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Admin',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (formattedPhone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formattedPhone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSummaryRow({
    required String name,
    required String phone,
    IconData? leadingIcon,
    String? badgeLabel,
    VoidCallback? onRemove,
    String? source,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
  }) {
    final theme = Theme.of(context);
    final formattedPhone = _formatPhoneForDisplay(phone);
    final icon = leadingIcon ??
        (source == 'contact' ? Icons.import_contacts_outlined : Icons.phone_in_talk_outlined);
    String? sourceLabel;
    if (source == 'contact') {
      sourceLabel = 'From contacts';
    } else if (source == 'manual') {
      sourceLabel = 'Added manually';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (badgeLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (formattedPhone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formattedPhone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                if (sourceLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sourceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null || onMoveUp != null || onMoveDown != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMoveUp != null)
                  IconButton(
                    onPressed: onMoveUp,
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Move earlier in payout order',
                    visualDensity: VisualDensity.compact,
                  ),
                if (onMoveDown != null)
                  IconButton(
                    onPressed: onMoveDown,
                    icon: Icon(
                      Icons.arrow_downward_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Move later in payout order',
                    visualDensity: VisualDensity.compact,
                  ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    tooltip: 'Remove invite',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDraftBanner() {
    final theme = Theme.of(context);
    return Dismissible(
      key: const ValueKey('draft-restored'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _showDraftRestoredBanner = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'We restored your saved draft so you can pick up where you left off.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() => _showDraftRestoredBanner = false);
              },
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildBlueprintStep();
      case 1:
        return _buildRulesStep();
      case 2:
        return _buildInvitesStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationBar() {
    final theme = Theme.of(context);
    final isLastStep = _currentStep == _steps.length - 1;
    final primaryLabel = isLastStep ? 'Create group' : 'Save & continue';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              SizedBox(
                width: 120,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _goToPreviousStep,
                  child: const Text('Back'),
                ),
              )
            else
              const SizedBox(width: 120),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isSaving ? null : _goToNextStep,
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Private Group'),
        centerTitle: true,
        actions: [
          if (_hasDraftData)
            TextButton(
              onPressed: _isSaving ? null : _resetDraft,
              child: const Text('Reset'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showDraftRestoredBanner) _buildDraftBanner(),
                      if (_showDraftRestoredBanner) const SizedBox(height: 16),
                      _buildStepIndicator(),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: SingleChildScrollView(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: _buildStepBody(),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading ? null : _buildNavigationBar(),
    );
  }
}
