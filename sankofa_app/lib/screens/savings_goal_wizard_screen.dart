import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/savings_goal_draft_model.dart';
import 'package:sankofasave/services/savings_service.dart';
import 'package:sankofasave/ui/components/ui.dart';

class SavingsGoalWizardScreen extends StatefulWidget {
  const SavingsGoalWizardScreen({super.key});

  @override
  State<SavingsGoalWizardScreen> createState() => _SavingsGoalWizardScreenState();
}

class _SavingsGoalWizardScreenState extends State<SavingsGoalWizardScreen> {
  final SavingsService _savingsService = SavingsService();

  final GlobalKey<FormState> _basicsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _targetFormKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _monthlyContributionController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.##');

  SavingsGoalDraftModel? _draft;
  String? _selectedCategory;
  DateTime? _selectedDeadline;
  bool _autoDeposit = false;

  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentStep = 0;

  static const List<_WizardStep> _steps = [
    _WizardStep(
      title: 'Goal basics',
      subtitle: 'Give your savings a clear name and focus area.',
      icon: Icons.lightbulb_outline,
    ),
    _WizardStep(
      title: 'Target & timeline',
      subtitle: 'Set the amount you need and when you want to achieve it.',
      icon: Icons.flag_outlined,
    ),
    _WizardStep(
      title: 'Plan & reminders',
      subtitle: 'Decide how you will stay consistent toward the goal.',
      icon: Icons.event_available_outlined,
    ),
    _WizardStep(
      title: 'Review & confirm',
      subtitle: 'Double-check the plan before creating your goal.',
      icon: Icons.check_circle_outline,
    ),
  ];

  static final List<_GoalCategory> _categories = [
    const _GoalCategory('Education', 'Fees, tuition, and school supplies'),
    const _GoalCategory('Business', 'Inventory, expansion, or equipment'),
    const _GoalCategory('Emergency', 'Build a 3-month rainy day cushion'),
    const _GoalCategory('Travel', 'Trips, flights, or visas'),
    const _GoalCategory('Housing', 'Rent advance or home upgrade'),
    const _GoalCategory('Celebration', 'Wedding, anniversary, or family event'),
  ];

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _monthlyContributionController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final existingDraft = await _savingsService.getDraftGoal();
    final now = DateTime.now();
    final draft = existingDraft ??
        SavingsGoalDraftModel(
          id: 'goal_draft_${now.millisecondsSinceEpoch}',
          createdAt: now,
          updatedAt: now,
        );

    setState(() {
      _draft = draft;
      _titleController.text = draft.title ?? '';
      _targetAmountController.text = draft.targetAmount != null
          ? _currencyFormatter.format(draft.targetAmount)
          : '';
      _monthlyContributionController.text = draft.monthlyContribution != null
          ? _currencyFormatter.format(draft.monthlyContribution)
          : '';
      _motivationController.text = draft.motivation ?? '';
      _selectedCategory = draft.category;
      _selectedDeadline = draft.deadline;
      _autoDeposit = draft.autoDeposit;
      _isLoading = false;
    });
  }

  void _updateDraft({
    Object? title = SavingsGoalDraftModel.noChange,
    Object? category = SavingsGoalDraftModel.noChange,
    Object? targetAmount = SavingsGoalDraftModel.noChange,
    Object? monthlyContribution = SavingsGoalDraftModel.noChange,
    Object? deadline = SavingsGoalDraftModel.noChange,
    bool? autoDeposit,
    Object? motivation = SavingsGoalDraftModel.noChange,
  }) {
    final current = _draft;
    if (current == null) return;
    final updated = current.copyWith(
      title: title,
      category: category,
      targetAmount: targetAmount,
      monthlyContribution: monthlyContribution,
      deadline: deadline,
      autoDeposit: autoDeposit,
      motivation: motivation,
      updatedAt: DateTime.now(),
    );
    setState(() {
      _draft = updated;
      _selectedCategory = updated.category;
      _selectedDeadline = updated.deadline;
      _autoDeposit = updated.autoDeposit;
    });
    _savingsService.saveDraftGoal(updated);
  }

  bool get _canContinue {
    if (_currentStep == 0) {
      final form = _basicsFormKey.currentState;
      return form != null && form.validate() && _selectedCategory != null;
    }
    if (_currentStep == 1) {
      final form = _targetFormKey.currentState;
      return form != null && form.validate() && _selectedDeadline != null;
    }
    if (_currentStep == 2) {
      return true;
    }
    return !_isSubmitting;
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      final form = _basicsFormKey.currentState;
      if (form == null || !form.validate() || _selectedCategory == null) {
        return;
      }
    } else if (_currentStep == 1) {
      final form = _targetFormKey.currentState;
      if (form == null || !form.validate() || _selectedDeadline == null) {
        return;
      }
    }

    if (_currentStep >= _steps.length - 1) {
      await _submit();
      return;
    }

    setState(() {
      _currentStep += 1;
    });
  }

  void _previousStep() {
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _currentStep -= 1;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final current = _draft;
    if (current == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final createdGoal = await _savingsService.createGoalFromDraft(current);
      if (!mounted) return;
      Navigator.of(context).pop(createdGoal);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create goal: ${error.toString()}')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _formatCurrency(num value) => 'GH₵ ${NumberFormat('#,##0.00').format(value)}';

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _selectedDeadline ?? now.add(const Duration(days: 90));
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      _updateDraft(deadline: selected);
    }
  }

  double? _parseAmount(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicsStep();
      case 1:
        return _buildTargetStep();
      case 2:
        return _buildPlanStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New savings goal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _WizardProgress(
                    steps: _steps,
                    currentStep: _currentStep,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey(_currentStep),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.08),
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
                              onPressed: _isSubmitting ? null : _previousStep,
                              child: const Text('Back'),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _canContinue ? _nextStep : null,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _currentStep == _steps.length - 1
                                        ? 'Create goal'
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

  Widget _buildBasicsStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tell us about this goal',
          subtitle:
              'Choosing a focus helps us personalise reminders and the stories you will see in Savings.',
        ),
        const SizedBox(height: 20),
        Form(
          key: _basicsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal name',
                  hintText: 'e.g. Junior\'s school fees',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Give the goal a memorable name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name should be at least 3 characters';
                  }
                  return null;
                },
                onChanged: (value) => _updateDraft(title: value.trim()),
              ),
              const SizedBox(height: 24),
              Text(
                'What type of goal is this?',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ActionChipRow(
                padding: EdgeInsets.zero,
                items: [
                  for (final category in _categories)
                    ActionChipItem(
                      label: category.label,
                      icon: Icons.label_outline,
                      isSelected: _selectedCategory == category.label,
                    ),
                ],
                onSelected: (index, item) => _updateDraft(category: _categories[index].label),
              ),
              if (_selectedCategory == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select a category to keep things organised.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                _selectedCategory != null
                    ? _categories
                        .firstWhere((category) => category.label == _selectedCategory)
                        .description
                    : 'Categories help us recommend the right nudges and insights.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'How much and by when?',
          subtitle: 'We’ll use this to track progress and celebrate milestones along the way.',
        ),
        const SizedBox(height: 20),
        Form(
          key: _targetFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Target amount (GH₵)',
                  hintText: 'e.g. 5000',
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  if (amount == null) {
                    return 'Enter how much you want to save';
                  }
                  if (amount < 100) {
                    return 'Target must be at least GH₵100';
                  }
                  return null;
                },
                onChanged: (value) {
                  final amount = _parseAmount(value);
                  _updateDraft(targetAmount: amount);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _monthlyContributionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monthly contribution goal (optional)',
                  hintText: 'e.g. 500',
                ),
                onChanged: (value) {
                  final amount = _parseAmount(value);
                  _updateDraft(monthlyContribution: amount);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Deadline',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ListTile(
                onTap: _pickDeadline,
                tileColor: theme.colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  _selectedDeadline != null
                      ? DateFormat.yMMMMd().format(_selectedDeadline!)
                      : 'Select deadline',
                ),
                subtitle: Text(
                  _selectedDeadline != null
                      ? 'We\'ll keep you on track with reminders.'
                      : 'Pick a target date to help us pace your plan.',
                ),
                trailing: const Icon(Icons.calendar_month),
              ),
              if (_selectedDeadline == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Choose when you want to hit this goal.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanStep() {
    final theme = Theme.of(context);
    final monthlyContribution = _draft?.monthlyContribution;
    final targetAmount = _draft?.targetAmount;
    final monthsRemaining = _selectedDeadline != null
        ? (_selectedDeadline!.difference(DateTime.now()).inDays / 30).ceil()
        : null;

    double? suggestedMonthly;
    if (targetAmount != null && monthsRemaining != null && monthsRemaining > 0) {
      suggestedMonthly = (targetAmount / monthsRemaining).clamp(0, double.infinity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Keep the momentum',
          subtitle: 'A simple habit makes it easier to stay consistent each month.',
        ),
        const SizedBox(height: 20),
        SwitchListTile.adaptive(
          value: _autoDeposit,
          onChanged: (value) => _updateDraft(autoDeposit: value),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          title: const Text('Auto-debit from wallet'),
          subtitle: Text(
            'We\'ll prepare a standing order so you only approve the debit once. You can pause this anytime.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (suggestedMonthly != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested rhythm',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contributing about ${_formatCurrency(suggestedMonthly)} each month will get you there on time.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (monthlyContribution == null ||
                    (monthlyContribution - suggestedMonthly).abs() > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilledButton.tonal(
                      onPressed: () {
                        _monthlyContributionController.text =
                            suggestedMonthly!.toStringAsFixed(0);
                        _updateDraft(monthlyContribution: suggestedMonthly);
                      },
                      child: const Text('Use this amount'),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _motivationController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Why is this goal important?',
            hintText: 'A short note keeps you inspired when the journey gets tough.',
          ),
          onChanged: (value) => _updateDraft(motivation: value.trim().isEmpty ? null : value.trim()),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final draft = _draft;
    final theme = Theme.of(context);
    if (draft == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Almost there',
          subtitle: 'Take a final look. You can always edit details later from the goal page.',
        ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'Goal summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(label: 'Name', value: draft.title ?? '-'),
              InfoRow(label: 'Category', value: draft.category ?? '-'),
              InfoRow(
                label: 'Target amount',
                value: draft.targetAmount != null
                    ? _formatCurrency(draft.targetAmount!)
                    : '-',
              ),
              InfoRow(
                label: 'Deadline',
                value: draft.deadline != null
                    ? DateFormat.yMMMMd().format(draft.deadline!)
                    : '-',
              ),
              InfoRow(
                label: 'Monthly goal',
                value: draft.monthlyContribution != null
                    ? _formatCurrency(draft.monthlyContribution!)
                    : 'Not set',
              ),
              InfoRow(
                label: 'Auto-debit',
                value: draft.autoDeposit ? 'Enabled' : 'Not now',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (draft.motivation != null && draft.motivation!.isNotEmpty)
          InfoCard(
            title: 'Motivation note',
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '“${draft.motivation}”',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        InfoCard(
          title: 'What happens next?',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: 'Track progress',
                value: 'We’ll highlight milestones and remind you when boosts are due.',
              ),
              InfoRow(
                label: 'Boost anytime',
                value: 'Make instant top-ups from the goal page or wallet quick actions.',
              ),
              InfoRow(
                label: 'Edit details',
                value: 'Adjust target or timeline later if your plans evolve.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WizardProgress extends StatelessWidget {
  const _WizardProgress({
    required this.steps,
    required this.currentStep,
  });

  final List<_WizardStep> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: _StepIndicator(
                    isActive: i <= currentStep,
                    isCurrent: i == currentStep,
                    label: steps[i].title,
                    icon: steps[i].icon,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            steps[currentStep].title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            steps[currentStep].subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.isActive,
    required this.isCurrent,
    required this.label,
    required this.icon,
  });

  final bool isActive;
  final bool isCurrent;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.secondary
        : theme.colorScheme.outline.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isCurrent ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: isCurrent ? 2 : 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          AnimatedOpacity(
            opacity: isCurrent ? 1 : 0.6,
            duration: const Duration(milliseconds: 250),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardStep {
  const _WizardStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _GoalCategory {
  const _GoalCategory(this.label, this.description);

  final String label;
  final String description;
}
