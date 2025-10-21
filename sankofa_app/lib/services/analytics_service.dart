import 'package:flutter/foundation.dart';

class AnalyticsEvent {
  AnalyticsEvent({
    required this.name,
    required this.timestamp,
    required this.properties,
  });

  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> properties;
}

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService _instance = AnalyticsService._();

  factory AnalyticsService() => _instance;

  final List<AnalyticsEvent> _events = [];

  void logEvent(String name, {Map<String, dynamic>? properties}) {
    final event = AnalyticsEvent(
      name: name,
      timestamp: DateTime.now(),
      properties: properties ?? const {},
    );
    _events.add(event);
    if (kDebugMode) {
      debugPrint('Analytics event ➜ $name ${event.properties}');
    }
  }

  List<AnalyticsEvent> get events => List.unmodifiable(_events);
}
