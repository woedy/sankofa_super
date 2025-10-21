import 'package:flutter/material.dart';

import 'responsive.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceSize = ResponsiveBreakpoints.of(context);
    final compact = deviceSize == DeviceSize.small;
    final resolvedPadding = padding ?? const EdgeInsets.symmetric(horizontal: 20);

    final titleWidget = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    final subtitleWidget = subtitle != null
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        : null;

    final actionWidget = (actionLabel != null && onAction != null)
        ? TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          )
        : trailing;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleWidget,
        if (subtitleWidget != null) subtitleWidget,
      ],
    );

    return Padding(
      padding: resolvedPadding,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                body,
                if (actionWidget != null) ...[
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: actionWidget),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: body),
                if (actionWidget != null) actionWidget,
              ],
            ),
    );
  }
}
