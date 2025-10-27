import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sankofasave/models/notification_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:sankofasave/services/api_exception.dart';
import 'package:sankofasave/services/notification_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/services/wallet_service.dart';
import 'package:sankofasave/ui/components/ui.dart';
import 'package:sankofasave/screens/transaction_receipt_modal.dart';

enum WithdrawalSubmissionStatus { success, pending, failed }

class WithdrawalFlowScreen extends StatefulWidget {
  const WithdrawalFlowScreen({super.key});

  @override
  State<WithdrawalFlowScreen> createState() => _WithdrawalFlowScreenState();
}

class _WithdrawalFlowScreenState extends State<WithdrawalFlowScreen> {
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final WalletService _walletService = WalletService();

  final GlobalKey<FormState> _amountFormKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  UserModel? _user;

  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _simulateIssue = false;

  final Map<String, bool> _complianceChecks = {};
  String? _selectedDestinationId;
  String? _reviewReference;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  final List<double> _quickAmounts = const [100, 250, 500, 1000];

  final List<_ComplianceItem> _complianceItems = const [
    _ComplianceItem(
      id: 'verified_id',
      title: 'Valid ID on file',
      subtitle: 'My Ghana Card or passport has been verified with Sankofa.',
    ),
    _ComplianceItem(
      id: 'matching_account',
      title: 'Account matches my name',
      subtitle: 'The receiving wallet or bank account is registered to me.',
    ),
    _ComplianceItem(
      id: 'confirm_purpose',
      title: 'Purpose recorded',
      subtitle: 'I can explain why I am cashing out this amount if asked.',
    ),
  ];

  final List<_WithdrawalDestination> _destinations = const [
    _WithdrawalDestination(
      id: 'momo',
      name: 'MTN MoMo wallet',
      subtitle: 'Instant transfers to your registered mobile number.',
      icon: Icons.phone_android,
      instructions: 'Ensure your MTN SIM is active to approve the STK prompt.',
      channelLabel: 'MTN MoMo',
      type: 'wallet',
      feeRate: 0.009,
      minFee: 1.50,
      counterpartyTemplate: '+233 24 123 4567',
    ),
    _WithdrawalDestination(
      id: 'vodafone',
      name: 'Vodafone Cash wallet',
      subtitle: 'Reliable cash-out with predictable settlement times.',
      icon: Icons.wifi_calling_3,
      instructions: 'Vodafone may request a confirmation code on your device.',
      channelLabel: 'Vodafone Cash',
      type: 'wallet',
      feeRate: 0.008,
      minFee: 1.20,
      counterpartyTemplate: '+233 20 987 6543',
    ),
    _WithdrawalDestination(
      id: 'bank',
      name: 'GTBank account',
      subtitle: 'Send to your linked GTBank savings account.',
      icon: Icons.account_balance,
      instructions: 'Large transfers trigger manual AML review (up to 1 business day).',
      channelLabel: 'GTBank',
      type: 'bank',
      feeRate: 0.004,
      minFee: 3.00,
      requiresReview: true,
      counterpartyTemplate: 'GTBank • 1234567890',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final item in _complianceItems) {
      _complianceChecks[item.id] = false;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await _userService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  double? get _enteredAmount {
    final raw = _amountController.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  _WithdrawalDestination? get _selectedDestination {
    if (_selectedDestinationId == null) return null;
    return _destinations.firstWhere(
      (destination) => destination.id == _selectedDestinationId,
      orElse: () => _destinations.first,
    );
  }

  bool get _allComplianceChecked {
    if (_complianceChecks.isEmpty) return false;
    return _complianceChecks.values.every((isChecked) => isChecked);
  }

  double get _calculatedFee {
    final amount = _enteredAmount;
    final destination = _selectedDestination;
    if (amount == null || destination == null) {
      return 0;
    }
    final percentageFee = amount * destination.feeRate;
    return math.max(destination.minFee, percentageFee);
  }

  double get _estimatedPayout {
    final amount = _enteredAmount ?? 0;
    final fee = _calculatedFee;
    final payout = amount - fee;
    return payout <= 0 ? 0 : payout;
  }

  WithdrawalSubmissionStatus get _predictedStatus {
    if (_simulateIssue) {
      return WithdrawalSubmissionStatus.failed;
    }
    final destination = _selectedDestination;
    final amount = _enteredAmount ?? 0;
    if (destination == null) {
      return WithdrawalSubmissionStatus.pending;
    }
    if (destination.requiresReview || amount > 1500) {
      return WithdrawalSubmissionStatus.pending;
    }
    return WithdrawalSubmissionStatus.success;
  }

  bool get _canAdvance {
    if (_currentStep == 0) {
      final amount = _enteredAmount;
      if (amount == null) return false;
      if (amount < 50) return false;
      if (amount > 20000) return false;
      final balance = _user?.walletBalance ?? 0;
      if (amount > balance) return false;
      return true;
    }
    if (_currentStep == 1) {
      return _allComplianceChecked;
    }
    if (_currentStep == 2) {
      return _selectedDestination != null;
    }
    return true;
  }

  String _formatCurrency(num value) => 'GH₵ ${_currencyFormatter.format(value)}';

  bool _isQuickAmountSelected(double value) {
    final amount = _enteredAmount;
    if (amount == null) return false;
    return (amount - value).abs() < 0.01;
  }

  void _handleQuickAmountTap(double value) {
    FocusScope.of(context).unfocus();
    setState(() {
      _amountController.text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    });
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) return;
    setState(() {
      _currentStep -= 1;
    });
  }

  Future<void> _goToNextStep() async {
    if (_currentStep == 0) {
      final form = _amountFormKey.currentState;
      if (form == null || !form.validate()) {
        return;
      }
    }

    if (_currentStep == 1 && !_allComplianceChecked) {
      return;
    }

    if (_currentStep == 2 && _selectedDestination == null) {
      return;
    }

    setState(() {
      _currentStep += 1;
    });
  }

  String _generateReference() {
    final now = DateTime.now();
    return 'WDR-${now.millisecondsSinceEpoch}';
  }

  String _resolveCounterparty(_WithdrawalDestination destination) {
    if (destination.type == 'wallet') {
      return _user?.phone ?? destination.counterpartyTemplate ?? '';
    }
    return destination.counterpartyTemplate ?? '';
  }

  Future<void> _submitWithdrawal() async {
    if (_isSubmitting) return;

    final amount = _enteredAmount;
    final destination = _selectedDestination;
    final user = _user;
    if (amount == null || destination == null || user == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final status = _predictedStatus;
    final reference = _reviewReference ?? _generateReference();
    final fee = _calculatedFee;
    final note = _noteController.text.trim();

    final statusCode = switch (status) {
      WithdrawalSubmissionStatus.success => 'success',
      WithdrawalSubmissionStatus.pending => 'pending',
      WithdrawalSubmissionStatus.failed => 'failed',
    };

    final descriptionBuffer = StringBuffer('Withdrawal to ${destination.name}');
    if (note.isNotEmpty) {
      descriptionBuffer.write(' • $note');
    }
    if (status == WithdrawalSubmissionStatus.pending) {
      descriptionBuffer.write(' (pending review)');
    }
    if (status == WithdrawalSubmissionStatus.failed) {
      descriptionBuffer.write(' (failed)');
    }

    try {
      final result = await _walletService.withdraw(
        amount: amount,
        status: statusCode,
        channel: destination.channelLabel,
        reference: reference,
        fee: fee > 0 ? fee : null,
        description: descriptionBuffer.toString(),
        counterparty: _resolveCounterparty(destination),
        destination: destination.name,
        note: note.isNotEmpty ? note : null,
      );

      final transaction = result.transaction;
      final resolvedStatus = switch (transaction.status) {
        'success' => WithdrawalSubmissionStatus.success,
        'failed' => WithdrawalSubmissionStatus.failed,
        _ => WithdrawalSubmissionStatus.pending,
      };

      final updatedBalance = result.walletBalance;
      final recordedFee = transaction.fee ?? fee;

      await _userService.updateWalletBalance(
        updatedBalance,
        walletUpdatedAt: result.walletUpdatedAt,
      );

      final notificationTitle = switch (resolvedStatus) {
        WithdrawalSubmissionStatus.success => 'Withdrawal submitted',
        WithdrawalSubmissionStatus.pending => 'Withdrawal pending review',
        WithdrawalSubmissionStatus.failed => 'Withdrawal could not complete',
      };

      final notificationMessage = switch (resolvedStatus) {
        WithdrawalSubmissionStatus.success =>
            '${_formatCurrency(transaction.amount)} will hit ${destination.name} shortly.',
        WithdrawalSubmissionStatus.pending =>
            'We are reviewing your ${_formatCurrency(transaction.amount)} withdrawal to ${destination.name}.',
        WithdrawalSubmissionStatus.failed =>
            'Your ${_formatCurrency(transaction.amount)} withdrawal to ${destination.name} needs additional information.',
      };

      await _notificationService.addNotification(
        NotificationModel(
          id: 'notif_${now.millisecondsSinceEpoch}',
          userId: user.id,
          title: notificationTitle,
          message: notificationMessage,
          type: 'wallet',
          isRead: false,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (!mounted) return;

      setState(() {
        _reviewReference = transaction.reference ?? reference;
        _isSubmitting = false;
        _user = user.copyWith(
          walletBalance: updatedBalance,
          walletUpdatedAt: result.walletUpdatedAt,
          updatedAt: DateTime.now(),
        );
      });

      final shouldShowReceipt = await _showOutcomeSheet(
        status: resolvedStatus,
        amount: transaction.amount,
        fee: recordedFee,
        reference: transaction.reference ?? reference,
        destination: destination,
        updatedBalance: updatedBalance,
      );

      if (!mounted) return;
      if (shouldShowReceipt) {
        await showTransactionReceiptModal(context, transaction);
        if (!mounted) return;
      }
      Navigator.of(context).pop(resolvedStatus);
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : 'Unable to submit withdrawal. Please try again.';
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _showOutcomeSheet({
    required WithdrawalSubmissionStatus status,
    required double amount,
    required double fee,
    required String reference,
    required _WithdrawalDestination destination,
    double? updatedBalance,
  }) async {
    final theme = Theme.of(context);
    final color = _statusColor(status, theme);
    final icon = switch (status) {
      WithdrawalSubmissionStatus.success => Icons.check_circle,
      WithdrawalSubmissionStatus.pending => Icons.hourglass_top,
      WithdrawalSubmissionStatus.failed => Icons.error_outline,
    };
    final title = switch (status) {
      WithdrawalSubmissionStatus.success => 'Withdrawal in motion',
      WithdrawalSubmissionStatus.pending => 'We\'re reviewing your request',
      WithdrawalSubmissionStatus.failed => 'Withdrawal flagged',
    };
    final message = switch (status) {
      WithdrawalSubmissionStatus.success =>
          'Expect a confirmation once the funds land in your ${destination.name}. Download or share the receipt for your records.',
      WithdrawalSubmissionStatus.pending =>
          'Compliance needs a quick look at this cash-out. We\'ll notify you once it clears. Save the receipt to track the review.',
      WithdrawalSubmissionStatus.failed =>
          'Support will reach out shortly. You can try again after updating your compliance details. Keep this receipt in case you follow up.',
    };

    final expectedPayout = status == WithdrawalSubmissionStatus.failed ? 0 : _estimatedPayout;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ModalScaffold(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 24),
              InfoCard(
                title: 'Summary',
                child: Column(
                  children: [
                    InfoRow(label: 'Reference', value: reference),
                    InfoRow(label: 'Destination', value: destination.name),
                    InfoRow(label: 'Requested', value: _formatCurrency(amount)),
                    InfoRow(label: 'Fees', value: _formatCurrency(fee)),
                    InfoRow(label: 'Expected payout', value: _formatCurrency(expectedPayout)),
                    if (updatedBalance != null)
                      InfoRow(label: 'New wallet balance', value: _formatCurrency(updatedBalance)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.receipt_long),
                onPressed: () => Navigator.of(context).pop(true),
                label: const Text('View receipt'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Done for now'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  Color _statusColor(WithdrawalSubmissionStatus status, ThemeData theme) => switch (status) {
        WithdrawalSubmissionStatus.success => theme.colorScheme.secondary,
        WithdrawalSubmissionStatus.pending => theme.colorScheme.tertiary,
        WithdrawalSubmissionStatus.failed => theme.colorScheme.error,
      };

  String _statusLabel(WithdrawalSubmissionStatus status) => switch (status) {
        WithdrawalSubmissionStatus.success => 'Instant',
        WithdrawalSubmissionStatus.pending => 'Manual review',
        WithdrawalSubmissionStatus.failed => 'Needs attention',
      };

  Widget _buildStatusChip(WithdrawalSubmissionStatus status) {
    final theme = Theme.of(context);
    final color = _statusColor(status, theme);
    final label = _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Withdraw funds'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: _buildStepIndicator(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: Padding(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: _buildStepBody(),
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['Amount', 'Compliance', 'Destination', 'Review'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            steps.length,
            (index) => Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStepCircle(index: index),
                      if (index != steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index < _currentStep
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: index == _currentStep
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: index == _currentStep ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle({required int index}) {
    final isActive = index == _currentStep;
    final isComplete = index < _currentStep;
    final theme = Theme.of(context);
    final color = isComplete || isActive ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isComplete
            ? theme.colorScheme.primary
            : isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: isComplete
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive ? theme.colorScheme.primary : color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildAmountStep();
      case 1:
        return _buildComplianceStep();
      case 2:
        return _buildDestinationStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAmountStep() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much would you like to cash out?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'You can withdraw up to your available wallet balance. We\'ll calculate estimated fees before you confirm.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          if (_user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wallet balance', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(_user!.walletBalance),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Form(
            key: _amountFormKey,
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(
                labelText: 'Withdrawal amount',
                prefixText: 'GH₵ ',
                helperText: 'Minimum ₵50.00 • Maximum ₵20,000',
              ),
              validator: (value) {
                final amount = _enteredAmount;
                if (amount == null) {
                  return 'Enter a valid amount';
                }
                if (amount < 50) {
                  return 'Amount must be at least ₵50';
                }
                if (amount > 20000) {
                  return 'Contact support for withdrawals above ₵20,000';
                }
                final balance = _user?.walletBalance ?? 0;
                if (amount > balance) {
                  return 'Amount exceeds your available balance';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick amounts', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _quickAmounts
                .map(
                  (amount) => ChoiceChip(
                    label: Text(_formatCurrency(amount)),
                    selected: _isQuickAmountSelected(amount),
                    onSelected: (_) => _handleQuickAmountTap(amount),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceStep() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance checklist',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Cash-outs are regulated. Confirm these quick checks so we keep your withdrawals flowing smoothly.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          InfoCard(
            title: 'Before we release funds',
            child: Column(
              children: [
                for (final item in _complianceItems)
                  CheckboxListTile(
                    value: _complianceChecks[item.id] ?? false,
                    onChanged: (value) => setState(() {
                      _complianceChecks[item.id] = value ?? false;
                    }),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                const Divider(height: 32),
                SwitchListTile.adaptive(
                  value: _simulateIssue,
                  onChanged: (value) => setState(() => _simulateIssue = value),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Simulate a hold',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Flip this on to trigger a mock failure scenario for demos and QA.',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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

  Widget _buildDestinationStep() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where should we send the cash?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a linked wallet or bank account. Larger transfers may require manual review.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          Column(
            children: _destinations.map(_buildDestinationTile).toList(),
          ),
          const SizedBox(height: 24),
          if (_enteredAmount != null)
            InfoCard(
              title: 'Estimated settlement',
              child: Column(
                children: [
                  InfoRow(label: 'Amount requested', value: _formatCurrency(_enteredAmount!)),
                  InfoRow(label: 'Estimated fees', value: _formatCurrency(_calculatedFee)),
                  InfoRow(label: 'Expected payout', value: _formatCurrency(_estimatedPayout)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationTile(_WithdrawalDestination destination) {
    final isSelected = _selectedDestinationId == destination.id;
    final theme = Theme.of(context);
    final borderColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedDestinationId = destination.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(destination.icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            destination.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Radio<String>(
                          value: destination.id,
                          groupValue: _selectedDestinationId,
                          onChanged: (_) => setState(() => _selectedDestinationId = destination.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      destination.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildDestinationBadge('${(destination.feeRate * 100).toStringAsFixed(1)}% fee'),
                        _buildDestinationBadge(destination.instructions),
                        if (destination.requiresReview)
                          _buildDestinationBadge('Manual review for high amounts'),
                        if (isSelected && _enteredAmount != null)
                          _buildDestinationBadge('Est. fee ${_formatCurrency(_calculatedFee)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final status = _predictedStatus;
    final destination = _selectedDestination;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review and submit',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Double-check the details below. We\'ll send you a notification as soon as the status changes.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor(status, theme).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusChip(status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    switch (status) {
                      WithdrawalSubmissionStatus.success =>
                          'Looks good! This payout should clear instantly once we submit it.',
                      WithdrawalSubmissionStatus.pending =>
                          'Heads up: we\'ll queue this for manual checks before releasing the funds.',
                      WithdrawalSubmissionStatus.failed =>
                          'Demo mode triggered a failure so you can showcase the escalated path.',
                    },
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          InfoCard(
            title: 'Cash-out summary',
            child: Column(
              children: [
                InfoRow(label: 'Amount requested', value: _formatCurrency(_enteredAmount ?? 0)),
                InfoRow(label: 'Fees', value: _formatCurrency(_calculatedFee)),
                InfoRow(label: 'You\'ll receive', value: _formatCurrency(_estimatedPayout)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (destination != null)
            InfoCard(
              title: 'Destination',
              child: Column(
                children: [
                  InfoRow(label: 'Channel', value: destination.channelLabel),
                  InfoRow(label: 'Account', value: _resolveCounterparty(destination)),
                  InfoRow(label: 'Instructions', value: destination.instructions),
                ],
              ),
            ),
          const SizedBox(height: 20),
          InfoCard(
            title: 'Compliance trail',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _complianceItems
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add a note (optional)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share context for this withdrawal e.g. float for market day',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 3;
    const primaryLabels = ['Continue', 'Continue', 'Review request', 'Submit request'];
    final primaryLabel = primaryLabels[_currentStep];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _goToPreviousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: FilledButton(
              onPressed: !_canAdvance || _isSubmitting
                  ? null
                  : () async {
                      if (isLastStep) {
                        await _submitWithdrawal();
                      } else {
                        await _goToNextStep();
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class _WithdrawalDestination {
  const _WithdrawalDestination({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.instructions,
    required this.channelLabel,
    required this.type,
    this.feeRate = 0,
    this.minFee = 0,
    this.requiresReview = false,
    this.counterpartyTemplate,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final String instructions;
  final String channelLabel;
  final String type;
  final double feeRate;
  final double minFee;
  final bool requiresReview;
  final String? counterpartyTemplate;
}

class _ComplianceItem {
  const _ComplianceItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}
