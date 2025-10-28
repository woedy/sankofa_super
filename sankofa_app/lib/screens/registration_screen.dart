import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sankofasave/screens/kyc_screen.dart';
import 'package:sankofasave/screens/main_screen.dart';
import 'package:sankofasave/services/analytics_service.dart';
import 'package:sankofasave/services/api_exception.dart';
import 'package:sankofasave/services/auth_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/utils/ghana_phone_formatter.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.prefilledPhone});

  final String? prefilledPhone;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFormatter = const GhanaPhoneNumberFormatter();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _otpSent = false;
  int _secondsRemaining = 0;
  Timer? _countdownTimer;
  String? _normalizedPhone;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logEvent('registration_screen_shown');
    final prefilled = widget.prefilledPhone;
    if (prefilled != null && prefilled.trim().isNotEmpty) {
      _phoneController.text = GhanaPhoneNumberFormatter.formatForDisplay(prefilled);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  bool _isValidPhone(String input) {
    final digits = GhanaPhoneNumberFormatter.digitsOnly(input);
    return digits.length == 9 && digits.startsWith(RegExp(r'[235]'));
  }

  bool _isValidEmail(String input) {
    if (input.isEmpty) {
      return true;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(input);
  }

  String? _fieldError(Map<String, dynamic>? details, String key) {
    if (details == null) {
      return null;
    }
    final value = details[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is List && value.isNotEmpty && value.first is String) {
      return value.first as String;
    }
    return null;
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phoneInput = _phoneController.text;
    final email = _emailController.text.trim();
    var hasError = false;

    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _otpError = null;
    });

    if (name.length < 2) {
      setState(() => _nameError = 'Enter your full name');
      hasError = true;
    }

    if (!_isValidPhone(phoneInput)) {
      setState(() => _phoneError = 'Enter a valid 9-digit MoMo number');
      hasError = true;
    }

    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      hasError = true;
    }

    if (hasError) {
      AnalyticsService().logEvent('registration_form_invalid');
      return;
    }

    final normalizedPhone = _authService.normalizePhone(phoneInput);

    setState(() {
      _isLoading = true;
      _otpSent = false;
    });

    try {
      AnalyticsService().logEvent('registration_submitted');
      final result = await _authService.registerUser(
        phoneNumber: normalizedPhone,
        fullName: name,
        email: email.isEmpty ? null : email,
      );
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _normalizedPhone = result.phoneNumber;
        _otpController.clear();
      });
      _startCountdown();
      AnalyticsService().logEvent('registration_otp_sent');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'We have sent a verification code to ${result.phoneNumber}')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      final details = error.details;
      setState(() {
        _isLoading = false;
        _otpSent = false;
        _nameError = _fieldError(details, 'full_name');
        _phoneError = _fieldError(details, 'phone_number') ?? (error.message.isNotEmpty ? error.message : null);
        _emailError = _fieldError(details, 'email');
      });
      AnalyticsService().logEvent('registration_failed', properties: {'reason': error.message});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _isLoading = false;
        _otpSent = false;
      });
      AnalyticsService().logEvent('registration_failed', properties: {'reason': error.toString()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not complete registration. Please try again.')),
      );
    }
  }

  Future<void> _resendOtp() async {
    final phone = _normalizedPhone;
    if (phone == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      await _authService.requestOtp(phone, purpose: 'signup');
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() => _isLoading = false);
      _startCountdown();
      AnalyticsService().logEvent('registration_otp_resent');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A new code has been sent to ${phone.replaceFirst('+233', '+233 ')}')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _isLoading = false;
        _otpError = error.message;
      });
      AnalyticsService().logEvent('registration_otp_resend_failed', properties: {'reason': error.message});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _isLoading = false;
        _otpError = 'We could not resend the code. Please try again.';
      });
      AnalyticsService().logEvent('registration_otp_resend_failed', properties: {'reason': error.toString()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not resend the code. Please try again.')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _otpError = 'Enter the 6-digit code we sent');
      return;
    }

    final phone = _normalizedPhone ?? _authService.normalizePhone(_phoneController.text);

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final authenticatedUser = await _authService.verifyOtp(
        phoneNumber: phone,
        code: code,
        purpose: 'signup',
      );
      final userService = UserService();
      final refreshed = await userService.refreshCurrentUser();
      final user = refreshed ?? authenticatedUser;
      final requiresKyc = user.requiresKyc;

      AnalyticsService().logEvent('registration_verified', properties: {
        'next_screen': requiresKyc ? 'kyc' : 'main',
      });

      if (!mounted) return;

      _countdownTimer?.cancel();
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        requiresKyc
            ? RouteTransitions.slideLeft(const KYCScreen())
            : RouteTransitions.slideLeft(const MainScreen()),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _isLoading = false;
        _otpError = error.message;
      });
      AnalyticsService().logEvent('registration_verification_failed', properties: {'reason': error.message});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _isLoading = false;
        _otpError = 'Something went wrong. Please try again.';
      });
      AnalyticsService().logEvent('registration_verification_failed', properties: {'reason': error.toString()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not verify the code. Please try again.')),
      );
    }
  }

  void _resetOtpFlow() {
    _countdownTimer?.cancel();
    setState(() {
      _otpSent = false;
      _secondsRemaining = 0;
      _otpController.clear();
      _otpError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                _otpSent ? 'Verify your phone number' : 'Create your Sankofa Save account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code we sent to complete your registration.'
                    : 'Tell us a bit about you so we can set up your savings experience.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 32),
              if (!_otpSent) ...[
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full name',
                    hintText: 'Ama Mensah',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneFormatter],
                  decoration: InputDecoration(
                    labelText: 'Mobile money number',
                    hintText: '24 123 4567',
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '🇬🇭 +233',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    errorText: _phoneError,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'ama@example.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    errorText: _emailError,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We sent a code to ${(_normalizedPhone ?? '').replaceFirst('+233', '+233 ')}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Enter the code below to continue.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Verification code',
                    hintText: '123456',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    errorText: _otpError,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify and continue',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_secondsRemaining > 0)
                  Text(
                    'You can request a new code in $_secondsRemaining s',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                if (_secondsRemaining > 0) const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: (_secondsRemaining > 0 || _isLoading) ? null : _resendOtp,
                      child: Text(
                        'Resend code',
                        style: TextStyle(
                          color: (_secondsRemaining > 0 || _isLoading)
                              ? Colors.grey.shade400
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              AnalyticsService().logEvent('registration_restart');
                              _resetOtpFlow();
                            },
                      child: Text(
                        'Use a different number',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Already have an account? Sign in',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop(false);
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Go to sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
