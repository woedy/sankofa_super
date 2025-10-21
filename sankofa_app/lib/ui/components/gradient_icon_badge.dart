import 'package:flutter/material.dart';

import 'responsive.dart';

class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.icon,
    this.colors,
    this.diameter,
    this.iconSize,
  });

  final IconData icon;
  final List<Color>? colors;
  final double? diameter;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceSize = ResponsiveBreakpoints.of(context);

    final double resolvedDiameter;
    switch (deviceSize) {
      case DeviceSize.small:
        resolvedDiameter = diameter ?? 56;
      case DeviceSize.medium:
        resolvedDiameter = diameter ?? 64;
      case DeviceSize.large:
        resolvedDiameter = diameter ?? 72;
    }

    final iconColor = colors ?? [theme.colorScheme.secondary, theme.colorScheme.tertiary];

    return Container(
      width: resolvedDiameter,
      height: resolvedDiameter,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: iconColor),
        borderRadius: BorderRadius.circular(resolvedDiameter / 4),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: iconSize ?? (resolvedDiameter * 0.45),
      ),
    );
  }
}
