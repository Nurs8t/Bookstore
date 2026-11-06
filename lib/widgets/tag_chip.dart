import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool compact;
  final Color? background;
  final Color? foreground;

  const TagChip({
    super.key,
    required this.label,
    this.compact = false,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: background ?? Colors.brown.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 11 : 12.5,
          fontWeight: FontWeight.w600,
          color: foreground ?? Colors.brown.shade700,
        ),
      ),
    );
  }
}
