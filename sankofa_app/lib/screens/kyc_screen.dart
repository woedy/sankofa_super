import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/analytics_service.dart';
import '../services/api_exception.dart';
import '../services/kyc_service.dart';
import '../services/user_service.dart';
import '../utils/route_transitions.dart';
import 'main_screen.dart';

enum _CardSide { front, back }

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final ImagePicker _picker = ImagePicker();
  final KycService _kycService = KycService();
  final UserService _userService = UserService();
  final AnalyticsService _analytics = AnalyticsService();

  int _currentStep = 0;
  bool _isSubmitting = false;
  XFile? _frontImage;
  XFile? _backImage;
  Uint8List? _frontPreview;
  Uint8List? _backPreview;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                                  color: isActive ? theme.colorScheme.secondary : Colors.grey.shade200,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
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
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : Text(
                              _currentStep == 2 ? 'Submit for Review' : 'Continue',
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
                            : () => setState(() {
                                  _currentStep = (_currentStep - 1).clamp(0, 2);
                                  _errorMessage = null;
                                }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.4),
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
    switch (_currentStep) {
      case 0:
        return _buildCaptureStep(_CardSide.front);
      case 1:
        return _buildCaptureStep(_CardSide.back);
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildCaptureStep(_CardSide side) {
    final theme = Theme.of(context);
    final isFront = side == _CardSide.front;
    final preview = isFront ? _frontPreview : _backPreview;
    final title = isFront ? 'Capture the front of your Ghana Card' : 'Capture the back of your Ghana Card';
    final subtitle = isFront
        ? 'Hold your card steady, ensure the hologram is visible, and capture the entire front without glare.'
        : 'Flip your card over and capture the back so the barcode and signature line are sharp and readable.';

    return SizedBox(
      key: ValueKey(side),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipCard(
            theme,
            title: 'Position your card inside the frame',
            description:
                'Use good lighting, place the card on a dark surface, and keep your hands steady so the details stay crisp.',
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildPreview(preview, theme),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _captureCard(side, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : () => _captureCard(side, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Upload photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Photo tips',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildGuidanceList(theme),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    return SizedBox(
      key: const ValueKey('review'),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipCard(
            theme,
            title: 'Review before you submit',
            description: 'Zoom in on each image and confirm the card number, expiry date, and barcode are readable.',
          ),
          const SizedBox(height: 24),
          Text(
            'Is everything clear?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We will send these photos securely to our verification team. You can retake either side if the text looks blurry or cropped.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildPreview(_frontPreview, theme, label: 'Front side', allowRetake: true, side: _CardSide.front)),
              const SizedBox(width: 16),
              Expanded(child: _buildPreview(_backPreview, theme, label: 'Back side', allowRetake: true, side: _CardSide.back)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'By continuing you give Sankofa permission to store these images securely. We will move to MinIO cloud storage soon; for now they are encrypted on this device and uploaded to our protected servers.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    ThemeData theme, {
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildPreview(
    Uint8List? bytes,
    ThemeData theme, {
    String? label,
    bool allowRetake = false,
    _CardSide? side,
  }) {
    final hasImage = bytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? theme.colorScheme.secondary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, size: 52, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No photo yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a button below to capture a clear shot.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
        if (hasImage && allowRetake && side != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isSubmitting ? null : () => _captureCard(side, ImageSource.camera),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake photo'),
          ),
        ],
      ],
    );
  }

  Widget _buildGuidanceList(ThemeData theme) {
    const tips = [
      'Check that your full name and Ghana Card number are readable.',
      'Avoid reflections by tilting the card slightly if necessary.',
      'Remove any plastic sleeves or covers before snapping the photo.',
    ];

    return Column(
      children: tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 16, color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  bool get _canContinue {
    if (_isSubmitting) return false;
    if (_currentStep == 0) return _frontPreview != null;
    if (_currentStep == 1) return _backPreview != null;
    return _frontPreview != null && _backPreview != null;
  }

  Future<void> _handleContinue() async {
    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
        _errorMessage = null;
      });
      return;
    }

    await _submitDocuments();
  }

  Future<void> _captureCard(_CardSide side, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 2400,
      );

      if (picked == null) {
        _analytics.logEvent('kyc_capture_cancelled', properties: {'side': side.name, 'source': source.name});
        return;
      }

      final bytes = await picked.readAsBytes();

      setState(() {
        _errorMessage = null;
        if (side == _CardSide.front) {
          _frontImage = picked;
          _frontPreview = bytes;
        } else {
          _backImage = picked;
          _backPreview = bytes;
        }
      });

      _analytics.logEvent('kyc_capture_success', properties: {'side': side.name, 'source': source.name});
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
      _analytics.logEvent('kyc_capture_failed', properties: {'side': side.name, 'source': source.name, 'reason': error.message});
    } catch (error) {
      setState(() => _errorMessage = 'We could not access the ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please try again.');
      _analytics.logEvent('kyc_capture_failed', properties: {'side': side.name, 'source': source.name, 'reason': error.toString()});
    }
  }

  Future<void> _submitDocuments() async {
    final front = _frontImage;
    final back = _backImage;

    if (front == null || back == null) {
      setState(() => _errorMessage = 'Please capture both sides of your Ghana Card before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = await _kycService.uploadGhanaCard(frontImage: front, backImage: back);
      await _userService.saveUser(user);
      _analytics.logEvent('kyc_documents_submitted');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your Ghana Card has been submitted for review.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        RouteTransitions.fade(const MainScreen()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      _analytics.logEvent('kyc_submission_failed', properties: {'reason': error.message});
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'We could not upload your documents. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not upload your documents. Please try again.')),
      );
      _analytics.logEvent('kyc_submission_failed', properties: {'reason': error.toString()});
    }
  }
}
