import 'package:flutter/material.dart';

/// Defines breakpoint buckets leveraged across the shared component library.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double small = 360;
  static const double medium = 600;

  static DeviceSize sizeForWidth(double width) {
    if (width < small) return DeviceSize.small;
    if (width < medium) return DeviceSize.medium;
    return DeviceSize.large;
  }

  static DeviceSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return sizeForWidth(width);
  }

  static bool isSmall(BuildContext context) => of(context) == DeviceSize.small;

  static bool isMedium(BuildContext context) => of(context) == DeviceSize.medium;

  static bool isLarge(BuildContext context) => of(context) == DeviceSize.large;
}

enum DeviceSize { small, medium, large }
