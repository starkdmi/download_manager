import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({ super.key, required this.icon, this.size, this.onPressed }) : super();
  final IconData icon;
  final double? size;
  final void Function()? onPressed;

  static const iconSize = 32.0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IconButton(
      onPressed: onPressed, 
      icon: Icon(icon, size: size ?? iconSize, color: primary)
    );
  }
}