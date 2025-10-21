import 'package:flutter/material.dart';

import 'responsive.dart';

class ActionChipItem {
  const ActionChipItem({
    required this.label,
    this.icon,
    this.isSelected = false,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
}

typedef ActionChipSelected = void Function(int index, ActionChipItem item);

typedef ActionChipToggled = void Function(int index, bool selected, ActionChipItem item);

class ActionChipRow extends StatelessWidget {
  const ActionChipRow({
    super.key,
    required this.items,
    this.onSelected,
    this.onToggled,
    this.multiSelect = false,
    this.spacing,
    this.runSpacing,
    this.padding,
  }) : assert(onSelected != null || onToggled != null, 'Provide onSelected or onToggled callback.');

  final List<ActionChipItem> items;
  final ActionChipSelected? onSelected;
  final ActionChipToggled? onToggled;
  final bool multiSelect;
  final double? spacing;
  final double? runSpacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final deviceSize = ResponsiveBreakpoints.of(context);
    final horizontalScroll = deviceSize != DeviceSize.small;
    final content = Wrap(
      spacing: spacing ?? 12,
      runSpacing: runSpacing ?? 12,
      children: [
        for (var i = 0; i < items.length; i++)
          _buildChip(context, index: i, item: items[i]),
      ],
    );

    if (horizontalScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding ?? EdgeInsets.zero,
        child: Row(children: [content]),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: content,
    );
  }

  Widget _buildChip(BuildContext context, {required int index, required ActionChipItem item}) {
    final theme = Theme.of(context);
    final isSelected = item.isSelected;
    final background = isSelected
        ? theme.colorScheme.secondary.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceVariant;
    final borderColor = isSelected
        ? theme.colorScheme.secondary
        : theme.colorScheme.outline.withValues(alpha: 0.4);
    final foreground = isSelected
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return FilterChip(
      label: Text(item.label),
      avatar: item.icon != null ? Icon(item.icon, size: 18, color: foreground) : null,
      selected: isSelected,
      onSelected: (selected) {
        if (multiSelect) {
          onToggled?.call(index, selected, item);
        } else {
          onSelected?.call(index, item);
        }
      },
      selectedColor: background,
      showCheckmark: false,
      side: BorderSide(color: borderColor),
      backgroundColor: theme.colorScheme.surface,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: foreground,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
