import 'package:flutter/material.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';

/// Simple label chip with grey color scheme
class LabelChip extends StatelessWidget {
  final String label;
  const LabelChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        // TODO: place color in component colors
        color: const Color(0x66232B3B), // slate-800 @40%
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0x6690A4C0)), // slate-500 @40%
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.slate200,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
