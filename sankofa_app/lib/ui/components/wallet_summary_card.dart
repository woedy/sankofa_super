import 'package:flutter/material.dart';

import 'responsive.dart';

class WalletSummaryStatus {
  const WalletSummaryStatus({
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
}

class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.status,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.gradientColors,
    this.trailing,
    this.padding,
  });

  final String title;
  final String value;
  final WalletSummaryStatus? status;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final List<Color>? gradientColors;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveBreakpoints.of(context);
    final theme = Theme.of(context);
    final colors = gradientColors ?? [theme.colorScheme.primary, theme.colorScheme.tertiary];
    final horizontalLayout = size != DeviceSize.small;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: horizontalLayout ? 36 : 32,
          ),
        ),
        if (status != null) ...[
          const SizedBox(height: 16),
          _StatusPill(status: status!),
        ],
      ],
    );

    final actionButton = (primaryActionLabel != null && onPrimaryAction != null)
        ? ElevatedButton(
            onPressed: onPrimaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(primaryActionLabel!),
          )
        : null;

    final hasTrailing = trailing != null;
    final hasAction = actionButton != null;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          if (hasTrailing) ...[
            const SizedBox(height: 24),
            horizontalLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: trailing!),
                    ],
                  )
                : trailing!,
          ],
          if (hasAction) ...[
            const SizedBox(height: 24),
            Align(
              alignment: horizontalLayout ? Alignment.centerRight : Alignment.centerLeft,
              child: actionButton,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final WalletSummaryStatus status;

  @override
  Widget build(BuildContext context) {
    final background = status.backgroundColor ?? Colors.white.withValues(alpha: 0.2);
    final foreground = status.foregroundColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
