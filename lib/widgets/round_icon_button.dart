import 'package:flutter/material.dart';

/// Мұқаба үстіне (Stack) қойылатын ақ дөңгелек батырма.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final String? tooltip;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.grey,
    this.size = 20,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(size * 0.4),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
