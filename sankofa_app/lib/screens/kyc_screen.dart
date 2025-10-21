import 'package:flutter/material.dart';
import 'package:sankofasave/screens/main_screen.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  int _currentStep = 0;
  bool _isUploaded = false;
  bool _isSubmitting = false;
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('KYC Verification', style: TextStyle(color: Color(0xFF0F172A))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index <= _currentStep;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            if (index < 2) const SizedBox(width: 8),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: _buildStepContent(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canContinue ? _handleContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentStep == 2 ? 'Finish & Go to Dashboard' : 'Continue',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() => _currentStep = (_currentStep - 1).clamp(0, 2)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    final theme = Theme.of(context);
    switch (_currentStep) {
      case 0:
        return SizedBox(
          width: double.infinity,
          child: Column(
            key: const ValueKey('kyc_step_upload'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload your Ghana Card for verification',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Upload Ghana Card',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Take a clear photo of the front of your Ghana Card to help us confirm your identity.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => setState(() => _isUploaded = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isUploaded
                          ? theme.colorScheme.secondary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _isUploaded
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 60, color: theme.colorScheme.secondary),
                            const SizedBox(height: 12),
                            const Text(
                              'Ghana Card Uploaded',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to upload',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      case 1:
        return SizedBox(
          key: const ValueKey('kyc_step_review'),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review your details',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Make sure the information on your Ghana Card matches your profile. Well use these details to activate your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              _buildChecklistItem(Icons.badge_outlined, 'Full name matches ID', 'Double-check spelling and middle names to avoid delays.'),
              _buildChecklistItem(Icons.home_outlined, 'Address confirmed', 'Ensure your residential address is up-to-date and clearly visible.'),
              _buildChecklistItem(Icons.numbers_outlined, 'Ghana Card number clear', 'Make sure all digits are captured without glare or blur.'),
            ],
          ),
        );
      default:
        return SizedBox(
          key: const ValueKey('kyc_step_confirm'),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user, color: theme.colorScheme.secondary, size: 42),
              ),
              const SizedBox(height: 24),
              Text(
                'Everything looks good!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Submit your verification to unlock your SankoFa Save dashboard. This usually takes less than a minute.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildChecklistItem(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.35),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canContinue {
    if (_isSubmitting) return false;
    if (_currentStep == 0) return _isUploaded;
    return true;
  }

  Future<void> _handleContinue() async {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      return;
    }

    setState(() => _isSubmitting = true);
    await _userService.updateKycStatus('verified');

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    Navigator.of(context).pushAndRemoveUntil(
      RouteTransitions.fade(const MainScreen()),
      (route) => false,
    );
  }
}
