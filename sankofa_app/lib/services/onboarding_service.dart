import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  OnboardingService._();

  static const String _completionKey = 'onboarding_completed';

  static final OnboardingService _instance = OnboardingService._();

  factory OnboardingService() => _instance;

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completionKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completionKey, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completionKey);
  }
}
