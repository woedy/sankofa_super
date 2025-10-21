import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sankofasave/screens/login_screen.dart';
import 'package:sankofasave/services/analytics_service.dart';
import 'package:sankofasave/services/onboarding_service.dart';
import 'package:sankofasave/utils/route_transitions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Build Resilient Savings Circles',
      description:
          'Discover curated Susu groups led by vetted admins, transparent cycles, and contribution reminders so nobody misses a payout.',
      icon: Icons.groups_3,
      color: Color(0xFF14B8A6),
    ),
    OnboardingPage(
      title: 'Track Every Cedi with Confidence',
      description:
          'Wallet analytics, instant receipts, and intelligent alerts keep your Susu journey visible for you and your community champions.',
      icon: Icons.insights,
      color: Color(0xFF1E3A8A),
    ),
    OnboardingPage(
      title: 'Grow on Your Terms',
      description:
          'Automate top-ups, unlock savings boosts, and invite accountability partners as you scale your goals from Accra to the diaspora.',
      icon: Icons.auto_graph,
      color: Color(0xFF0891B2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService().logEvent('onboarding_shown');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    AnalyticsService().logEvent('onboarding_skipped', properties: {'page': _currentPage});
    await OnboardingService().markCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      RouteTransitions.slideUp(const LoginScreen()),
    );
  }

  Future<void> _handleAdvance() async {
    if (_currentPage == _pages.length - 1) {
      AnalyticsService().logEvent('onboarding_completed');
      await OnboardingService().markCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        RouteTransitions.slideUp(const LoginScreen()),
      );
    } else {
      final nextPage = _currentPage + 1;
      AnalyticsService().logEvent('onboarding_advance', properties: {'next_page': nextPage});
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to SankoFa Save',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Guided story • ${_currentPage + 1} of ${_pages.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _handleSkip,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  AnalyticsService().logEvent('onboarding_page_view', properties: {'page': index});
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: Theme.of(context).colorScheme.secondary,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleAdvance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildPage(OnboardingPage page) => Padding(
    padding: const EdgeInsets.all(40.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: page.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(page.icon, size: 100, color: page.color),
        ),
        const SizedBox(height: 48),
        Text(
          page.title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          page.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
