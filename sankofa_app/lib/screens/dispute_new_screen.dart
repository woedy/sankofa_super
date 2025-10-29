import 'package:flutter/material.dart';
import 'package:sankofasave/models/dispute_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/services/api_exception.dart';
import 'package:sankofasave/services/dispute_service.dart';
import 'package:sankofasave/services/group_service.dart';

class DisputeNewScreen extends StatefulWidget {
  const DisputeNewScreen({super.key});

  @override
  State<DisputeNewScreen> createState() => _DisputeNewScreenState();
}

class _DisputeNewScreenState extends State<DisputeNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final DisputeService _disputeService = DisputeService();
  final GroupService _groupService = GroupService();

  bool _isSubmitting = false;
  bool _loadingGroups = true;
  String? _selectedSeverity = 'Medium';
  String? _selectedPriority = 'Medium';
  String? _selectedChannel = 'Mobile App';
  String? _selectedGroupId;
  List<SusuGroupModel> _groups = const [];

  static const List<String> _severityOptions = ['Critical', 'High', 'Medium', 'Low'];
  static const List<String> _priorityOptions = ['High', 'Medium', 'Low'];
  static const List<String> _channelOptions = ['Mobile App', 'Phone', 'Email', 'WhatsApp', 'USSD'];
  static const List<String> _categorySuggestions = [
    'Wallet & Cashflow',
    'Groups & Invites',
    'Savings Goals',
    'Identity & Security',
    'KYC & Compliance',
    'App Support',
  ];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupService.getGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingGroups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGroups = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dispute = await _disputeService.createDispute(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        severity: _selectedSeverity ?? 'Medium',
        priority: _selectedPriority ?? 'Medium',
        channel: _selectedChannel ?? 'Mobile App',
        groupId: _selectedGroupId,
        initialMessage: _messageController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(dispute);
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
            content: Text('We couldn\'t submit that dispute. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a dispute'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us what happened',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Give your dispute a clear title and share a few details so our support team can help quickly.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dispute title',
                  hintText: 'e.g. Payout missing from my wallet',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a short title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What happened?',
                  hintText: 'Provide any helpful context or transaction references.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Describe what happened.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Category',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorySuggestions.map((suggestion) {
                  final isSelected = _categoryController.text.trim().toLowerCase() == suggestion.toLowerCase();
                  return ChoiceChip(
                    label: Text(suggestion),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _categoryController.text = suggestion;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Wallet & Cashflow',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pick a category so we can route your case.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildDropdown('Severity', _severityOptions, _selectedSeverity, (value) {
                    setState(() => _selectedSeverity = value);
                  })),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('Priority', _priorityOptions, _selectedPriority, (value) {
                    setState(() => _selectedPriority = value);
                  })),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown('Channel', _channelOptions, _selectedChannel, (value) {
                setState(() => _selectedChannel = value);
              }),
              const SizedBox(height: 20),
              Text(
                'Related group (optional)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_loadingGroups)
                Row(
                  children: const [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading your groups…'),
                  ],
                )
              else if (_groups.isEmpty)
                Text('We\'ll link this dispute to your account details.', style: suggestionStyle)
              else
                DropdownButtonFormField<String?>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    hintText: 'Select a group',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No specific group'),
                    ),
                    ..._groups.map(
                      (group) => DropdownMenuItem<String?>(
                        value: group.id,
                        child: Text(group.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                ),
              const SizedBox(height: 24),
              Text(
                'Initial message',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll send this to the support desk to kick off the conversation.',
                style: suggestionStyle,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  hintText: 'Include any reference numbers, names, or timeline details.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Share a quick note so we know how to help.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit dispute'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: options
          .map((option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
