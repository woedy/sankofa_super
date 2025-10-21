import 'package:flutter/material.dart';

import 'responsive.dart';

class ProgressSummaryBar extends StatelessWidget {
  const ProgressSummaryBar({
    super.key,
    required this.progress,
    this.label,
    this.secondaryLabel,
    this.color,
  });

  final double progress;
  final String? label;
  final String? secondaryLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceSize = ResponsiveBreakpoints.of(context);
    final primaryColor = color ?? theme.colorScheme.secondary;
    final clampedProgress = progress.clamp(0.0, 1.0);

    final hasPrimary = label != null && label!.isNotEmpty;
    final hasSecondary = secondaryLabel != null && secondaryLabel!.isNotEmpty;

    final labelsWidget = deviceSize == DeviceSize.small
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPrimary)
                Text(
                  label!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              if (hasSecondary) ...[
                if (hasPrimary) const SizedBox(height: 4),
                Text(
                  secondaryLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (hasPrimary || hasSecondary) const SizedBox(height: 8),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPrimary)
                Expanded(
                  child: Text(
                    label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    softWrap: true,
                  ),
                ),
              if (hasPrimary && hasSecondary) const SizedBox(width: 12),
              if (hasSecondary)
                Expanded(
                  child: Text(
                    secondaryLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.end,
                    softWrap: true,
                  ),
                ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelsWidget,
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 12,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clampedProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
