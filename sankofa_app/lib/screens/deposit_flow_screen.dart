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

class DepositFlowScreen extends StatefulWidget {
  const DepositFlowScreen({super.key});

  @override
  State<DepositFlowScreen> createState() => _DepositFlowScreenState();
}

class _DepositFlowScreenState extends State<DepositFlowScreen> {
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final WalletService _walletService = WalletService();

  final GlobalKey<FormState> _amountFormKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  UserModel? _user;

  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedChannelId;
  String? _reviewReference;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  final List<_DepositChannel> _channels = const [
    _DepositChannel(
      id: 'mtn',
      name: 'MTN MoMo',
      description: 'Instant STK push on your registered MTN number.',
      timeline: 'Instant confirmation',
      icon: Icons.phone_android,
      feeRate: 0.007,
      minFee: 1.20,
    ),
    _DepositChannel(
      id: 'vodafone',
      name: 'Vodafone Cash',
      description: 'Great for larger deposits with predictable fees.',
      timeline: '≈1 minute approval',
      icon: Icons.wifi_calling_3,
      feeRate: 0.006,
      minFee: 1.00,
    ),
    _DepositChannel(
      id: 'airteltigo',
      name: 'AirtelTigo Money',
      description: 'Solid everyday option with flat float checks.',
      timeline: 'Instant for ≤₵1,000',
      icon: Icons.sim_card_outlined,
      feeRate: 0.008,
      minFee: 0.80,
    ),
  ];

  final List<double> _quickAmounts = const [200, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
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

  _DepositChannel? get _selectedChannel {
    if (_selectedChannelId == null) return null;
    for (final channel in _channels) {
      if (channel.id == _selectedChannelId) {
        return channel;
      }
    }
    return null;
  }

  double get _calculatedFee {
    final amount = _enteredAmount;
    final channel = _selectedChannel;
    if (amount == null || channel == null) {
      return 0;
    }
    final percentageFee = amount * channel.feeRate;
    final totalFee = percentageFee + channel.flatFee;
    return math.max(channel.minFee, totalFee);
  }

  double get _totalDebit {
    final amount = _enteredAmount ?? 0;
    return amount + _calculatedFee;
  }

  bool get _canAdvance {
    if (_currentStep == 0) {
      final amount = _enteredAmount;
      if (amount == null) return false;
      return amount >= 20 && amount <= 20000;
    }
    if (_currentStep == 1) {
      return _selectedChannel != null;
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
      _amountController.text = value.toStringAsFixed(0);
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

    if (_currentStep == 1 && _selectedChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a channel to continue.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (_currentStep == 1 && _reviewReference == null) {
      _reviewReference = _generateReference();
    }

    setState(() {
      _currentStep += 1;
    });
  }

  String _generateReference() {
    final now = DateTime.now();
    return 'DEP-${now.millisecondsSinceEpoch}';
  }

  Future<void> _submitDeposit() async {
    if (_isSubmitting) return;
    final amount = _enteredAmount;
    final channel = _selectedChannel;
    final user = _user;
    if (amount == null || channel == null || user == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final reference = _reviewReference ?? _generateReference();
    final fee = _calculatedFee;

    try {
      final result = await _walletService.deposit(
        amount: amount,
        channel: channel.name,
        reference: reference,
        fee: fee > 0 ? fee : null,
        description: 'Wallet deposit via ${channel.name}',
        counterparty: user.phone,
      );

      final transaction = result.transaction;
      final newBalance = result.walletBalance;
      final recordedFee = transaction.fee ?? fee;

      await _userService.updateWalletBalance(
        newBalance,
        walletUpdatedAt: result.walletUpdatedAt,
      );

      await _notificationService.addNotification(
        NotificationModel(
          id: 'notif_${now.millisecondsSinceEpoch}',
          userId: user.id,
          title: 'Deposit confirmed',
          message: '${_formatCurrency(transaction.amount)} added to your wallet via ${channel.name}.',
          type: 'wallet',
          isRead: false,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (!mounted) return;

      setState(() {
        _user = user.copyWith(
          walletBalance: newBalance,
          walletUpdatedAt: result.walletUpdatedAt,
          updatedAt: DateTime.now(),
        );
        _reviewReference = transaction.reference ?? reference;
        _isSubmitting = false;
      });

      final shouldShowReceipt = await _showSuccessSheet(
        amount: transaction.amount,
        fee: recordedFee,
        newBalance: newBalance,
        reference: transaction.reference ?? reference,
      );
      if (shouldShowReceipt && mounted) {
        await showTransactionReceiptModal(context, transaction);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : 'Unable to complete deposit. Please try again.';
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

  Future<bool> _showSuccessSheet({
    required double amount,
    required double fee,
    required double newBalance,
    required String reference,
  }) async {
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
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 36, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Deposit submitted',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Your wallet was credited instantly. Preview the receipt now or keep it handy for later.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 24),
              InfoCard(
                title: 'Summary',
                child: Column(
                  children: [
                    InfoRow(label: 'Reference', value: reference),
                    InfoRow(label: 'Channel', value: _selectedChannel?.name ?? '-'),
                    InfoRow(label: 'Wallet credit', value: _formatCurrency(amount)),
                    InfoRow(label: 'Fees', value: _formatCurrency(fee)),
                    InfoRow(label: 'New balance', value: _formatCurrency(newBalance)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Deposit funds'),
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
    const steps = ['Amount', 'Channel', 'Review'];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildStepCircle(index: i),
                    if (i != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: i < _currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[i],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: i == _currentStep
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: i == _currentStep ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
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
        return _buildChannelStep();
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildAmountStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much would you like to add?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the amount you want to see reflected in your Sankofa wallet. We\'ll show estimated fees before you confirm.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          if (_user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current wallet balance', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(_user!.walletBalance),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                labelText: 'Deposit amount',
                prefixText: 'GH₵ ',
                helperText: 'Minimum ₵20.00 per deposit',
              ),
              validator: (value) {
                final amount = _enteredAmount;
                if (amount == null) {
                  return 'Enter a valid amount';
                }
                if (amount < 20) {
                  return 'Amount must be at least ₵20';
                }
                if (amount > 20000) {
                  return 'Contact support for deposits above ₵20,000';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick amounts', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
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

  Widget _buildChannelStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your deposit channel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'We support the major Ghanaian mobile money networks. Fees may vary slightly based on network rules.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          Column(
            children: _channels.map(_buildChannelTile).toList(),
          ),
          const SizedBox(height: 24),
          if (_enteredAmount != null)
            InfoCard(
              title: 'Estimated costs',
              child: Column(
                children: [
                  InfoRow(label: 'Wallet credit', value: _formatCurrency(_enteredAmount!)),
                  InfoRow(label: 'Estimated fees', value: _formatCurrency(_calculatedFee)),
                  InfoRow(label: 'Total debited', value: _formatCurrency(_totalDebit)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(_DepositChannel channel) {
    final isSelected = _selectedChannelId == channel.id;
    final theme = Theme.of(context);
    final borderColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedChannelId = channel.id),
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
                child: Icon(channel.icon, color: theme.colorScheme.primary),
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
                            channel.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Radio<String>(
                          value: channel.id,
                          groupValue: _selectedChannelId,
                          onChanged: (_) => setState(() => _selectedChannelId = channel.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      channel.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildChannelBadge('${(channel.feeRate * 100).toStringAsFixed(1)}% fee'),
                        _buildChannelBadge(channel.timeline),
                        if (_selectedChannelId == channel.id && _enteredAmount != null)
                          _buildChannelBadge('Est. fee ${_formatCurrency(_calculatedFee)}'),
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

  Widget _buildChannelBadge(String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final amount = _enteredAmount ?? 0;
    final fee = _calculatedFee;
    final newBalance = (_user?.walletBalance ?? 0) + amount;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & confirm',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Double-check the amounts and channel before you submit. We\'ll surface the compliance checks in the detailed receipt.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          InfoCard(
            title: 'Deposit summary',
            child: Column(
              children: [
                InfoRow(label: 'Channel', value: _selectedChannel?.name ?? '-'),
                InfoRow(label: 'Wallet credit', value: _formatCurrency(amount)),
                InfoRow(label: 'Estimated fees', value: _formatCurrency(fee)),
                InfoRow(label: 'Total debited', value: _formatCurrency(amount + fee)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_user != null)
            InfoCard(
              title: 'Wallet impact',
              child: Column(
                children: [
                  InfoRow(label: 'Current balance', value: _formatCurrency(_user!.walletBalance)),
                  InfoRow(label: 'Balance after deposit', value: _formatCurrency(newBalance)),
                  InfoRow(label: 'Reference preview', value: _reviewReference ?? _generateReference()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;
    final primaryLabel = isLastStep ? 'Confirm deposit' : 'Continue';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
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
                          await _submitDeposit();
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
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class _DepositChannel {
  const _DepositChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.timeline,
    required this.icon,
    this.feeRate = 0,
    this.minFee = 0,
    this.flatFee = 0,
  });

  final String id;
  final String name;
  final String description;
  final String timeline;
  final IconData icon;
  final double feeRate;
  final double minFee;
  final double flatFee;
}
