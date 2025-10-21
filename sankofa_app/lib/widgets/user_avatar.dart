import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.imagePath,
    this.size = 48,
    this.borderColor,
  });

  final String initials;
  final String? imagePath;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!.withValues(alpha: 0.6), width: size * 0.06)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: hasImage
            ? Image.asset(
                imagePath!,
                fit: BoxFit.cover,
              )
            : Container(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
      ),
    );
  }
}