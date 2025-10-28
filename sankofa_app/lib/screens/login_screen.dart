import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sankofasave/screens/kyc_screen.dart';
import 'package:sankofasave/screens/main_screen.dart';
import 'package:sankofasave/screens/registration_screen.dart';
import 'package:sankofasave/services/analytics_service.dart';
import 'package:sankofasave/services/api_exception.dart';
import 'package:sankofasave/services/auth_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/utils/ghana_phone_formatter.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFormatter = const GhanaPhoneNumberFormatter();
  final AuthService _authService = AuthService();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _phoneError;
  String? _otpError;
  int _secondsRemaining = 0;
  Timer? _countdownTimer;
  String? _normalizedPhone;
  bool _showSignupPrompt = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logEvent('login_screen_shown');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
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
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return digits.length == 9 && digits.startsWith(RegExp(r'[235]'));
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text;
    if (!_isValidPhone(phone)) {
      setState(() {
        _phoneError = 'Enter a valid 9-digit MoMo number';
        _otpSent = false;
      });
      AnalyticsService().logEvent('login_phone_invalid');
      return;
    }

    final normalizedPhone = _authService.normalizePhone(phone);
    setState(() {
      _isLoading = true;
      _phoneError = null;
      _otpError = null;
      _showSignupPrompt = false;
    });

    try {
      await _authService.requestOtp(normalizedPhone, purpose: 'login');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _normalizedPhone = normalizedPhone;
        _showSignupPrompt = false;
      });
      _startCountdown();
      AnalyticsService().logEvent('login_otp_sent');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('We\'ve sent a code to ${normalizedPhone.replaceFirst('+233', '+233 ')}')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      final detail = error.details?['detail'] ?? error.message;
      final detailString = detail is String ? detail : error.message;
      final isUserMissing = detailString.toLowerCase().contains('no account is registered');
      setState(() {
        _isLoading = false;
        _otpSent = false;
        _phoneError = isUserMissing ? null : error.message;
        _showSignupPrompt = isUserMissing;
      });
      AnalyticsService().logEvent(
        'login_otp_request_failed',
        properties: {
          'reason': error.message,
          'user_missing': isUserMissing,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detailString)),
      );
    } catch (error) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _isLoading = false;
        _otpSent = false;
        _phoneError = 'We could not send the code. Please try again.';
        _showSignupPrompt = false;
      });
      AnalyticsService().logEvent('login_otp_request_failed', properties: {'reason': error.toString()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not send the code. Please try again.')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _otpError = 'Enter the 6-digit code we sent');
      AnalyticsService().logEvent('login_otp_invalid_length');
      return;
    }

    final normalizedPhone = _normalizedPhone ?? _authService.normalizePhone(_phoneController.text);

    setState(() {
      _otpError = null;
      _isLoading = true;
    });

    try {
      final authenticatedUser = await _authService.verifyOtp(
        phoneNumber: normalizedPhone,
        code: otp,
      );
      final userService = UserService();
      final refreshed = await userService.refreshCurrentUser();
      final user = refreshed ?? authenticatedUser;
      final requiresKyc = user.requiresKyc;

      AnalyticsService().logEvent('login_verified', properties: {
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
      AnalyticsService().logEvent('login_otp_invalid', properties: {'reason': error.message});
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
      AnalyticsService().logEvent('login_otp_invalid', properties: {'reason': error.toString()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not verify the code. Please try again.')),
      );
    }
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
          onPressed: () => Navigator.of(context).pop(),
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
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to continue your savings journey',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_otpSent,
                  inputFormatters: [_phoneFormatter],
                  decoration: InputDecoration(
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
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    errorText: _phoneError,
                  ),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      errorText: _otpError,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
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
                      : Text(
                          _otpSent ? 'Verify OTP' : 'Send OTP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                if (_secondsRemaining > 0)
                  Text(
                    'You can resend a new code in $_secondsRemaining s',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                if (_secondsRemaining > 0) const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: (_secondsRemaining > 0 || _isLoading) ? null : () {
                      _otpController.clear();
                      _sendOtp();
                    },
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: (_secondsRemaining > 0 || _isLoading)
                            ? Colors.grey.shade400
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (_showSignupPrompt) ...[
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
                        "It looks like you're new here",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a Sankofa Save account to continue your onboarding journey.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final result = await Navigator.of(context).push(
                                    RouteTransitions.slideLeft(
                                      RegistrationScreen(prefilledPhone: _phoneController.text),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    setState(() {
                                      _otpSent = false;
                                      _phoneError = null;
                                      _otpController.clear();
                                      _showSignupPrompt = false;
                                    });
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.secondary,
                            side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Create a new Sankofa Save account'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final result = await Navigator.of(context).push(
                            RouteTransitions.slideLeft(
                              RegistrationScreen(prefilledPhone: _phoneController.text),
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {
                              _otpSent = false;
                              _phoneError = null;
                              _otpController.clear();
                              _showSignupPrompt = false;
                            });
                          }
                        },
                  child: Text(
                    'New to Sankofa Save? Create an account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
