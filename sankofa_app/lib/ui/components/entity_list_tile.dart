import 'package:flutter/material.dart';

import 'responsive.dart';

class EntityListTile extends StatelessWidget {
  const EntityListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.meta,
    this.statusChip,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget>? meta;
  final Widget? statusChip;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceSize = ResponsiveBreakpoints.of(context);
    final resolvedPadding = padding ?? const EdgeInsets.all(20);
    final resolvedRadius = borderRadius ?? BorderRadius.circular(20);
    final resolvedShadow = boxShadow ??
        [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];

    final content = _buildContent(context, deviceSize);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: resolvedRadius,
        onTap: onTap,
        child: Container(
          padding: resolvedPadding,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.cardColor,
            borderRadius: resolvedRadius,
            boxShadow: resolvedShadow,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DeviceSize deviceSize) {
    final gap = deviceSize == DeviceSize.small ? 12.0 : 16.0;

    final metaWidgets = meta ?? const [];
    final hasMeta = metaWidgets.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: gap),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  if (statusChip != null) ...[
                    SizedBox(width: gap),
                    statusChip!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: gap * 0.5),
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                  child: subtitle!,
                ),
              ],
              if (hasMeta) ...[
                SizedBox(height: gap),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: metaWidgets,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: gap),
          trailing!,
        ],
      ],
    );
  }
}
