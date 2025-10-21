import 'package:flutter/material.dart';

class ModalScaffold extends StatelessWidget {
  const ModalScaffold({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final constrainedWidth = width > maxWidth ? maxWidth : width;
        final theme = Theme.of(context);
        final borderRadius = BorderRadius.circular(28);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constrainedWidth),
            child: Padding(
              padding: resolvedPadding,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
