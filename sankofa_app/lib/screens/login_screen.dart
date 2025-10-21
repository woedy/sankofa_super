import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sankofasave/screens/kyc_screen.dart';
import 'package:sankofasave/screens/main_screen.dart';
import 'package:sankofasave/services/analytics_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class GhanaPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digitsOnly.length > 9 ? digitsOnly.substring(0, 9) : digitsOnly;

    final buffer = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      buffer.write(truncated[i]);
      if (i == 1 || i == 4) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFormatter = GhanaPhoneNumberFormatter();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _phoneError;
  String? _otpError;
  int _secondsRemaining = 0;
  Timer? _countdownTimer;

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

    setState(() {
      _isLoading = true;
      _phoneError = null;
      _otpError = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
    _startCountdown();
    AnalyticsService().logEvent('login_otp_sent');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!')),
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
    if (otp != '123456') {
      setState(() => _otpError = 'That code didn\'t match. Try again.');
      AnalyticsService().logEvent('login_otp_invalid');
      return;
    }

    setState(() {
      _otpError = null;
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));

    final user = await UserService().getCurrentUser();
    final requiresKyc = (user?.kycStatus ?? 'pending') != 'verified';
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
              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
