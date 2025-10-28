import 'package:flutter/material.dart';
import 'package:sankofasave/screens/kyc_screen.dart';
import 'package:sankofasave/screens/login_screen.dart';
import 'package:sankofasave/screens/main_screen.dart';
import 'package:sankofasave/screens/onboarding_screen.dart';
import 'package:sankofasave/services/analytics_service.dart';
import 'package:sankofasave/services/auth_service.dart';
import 'package:sankofasave/services/onboarding_service.dart';
import 'package:sankofasave/services/user_service.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    AnalyticsService().logEvent('splash_shown');
    _determineNextStep();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _determineNextStep() async {
    await Future.delayed(const Duration(milliseconds: 900));

    final onboardingService = OnboardingService();
    final authService = AuthService();
    final hasSession = await authService.hasActiveSession();
    final onboardingCompleted = await onboardingService.isCompleted();

    Widget destination;
    String label;

    if (hasSession) {
      final user = await UserService().getCurrentUser();
      final requiresKyc = user?.requiresKyc ?? true;
      destination = requiresKyc ? const KYCScreen() : const MainScreen();
      label = requiresKyc ? 'kyc' : 'main';
    } else if (onboardingCompleted) {
      destination = const LoginScreen();
      label = 'login';
    } else {
      destination = const OnboardingScreen();
      label = 'onboarding';
    }

    if (!mounted) return;

    AnalyticsService().logEvent('splash_completed', properties: {'next': label});
    Navigator.of(context).pushReplacement(RouteTransitions.fade(destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 70,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Text(
                    'SankoFa Save',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Where Susu wisdom meets modern finance.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built in Ghana for communities everywhere.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
