import 'package:flutter/material.dart';

/// ThemeExtension so you can access component-specific tokens from Theme.of(context).
@immutable
class ComponentColors extends ThemeExtension<ComponentColors> {
  final Color cardBg;

  final Color borderStrong;
  final Color borderSoft;

  final List<Color> headerChipGradient;
  final List<Color> progressGradient;

  const ComponentColors({
    required this.cardBg,
    required this.borderStrong,
    required this.borderSoft,
    required this.headerChipGradient,
    required this.progressGradient,
  });

  @override
  ComponentColors copyWith({
    Color? cardBg,
    Color? borderStrong,
    Color? borderSoft,
    List<Color>? headerChipGradient,
    List<Color>? progressGradient,
  }) {
    return ComponentColors(
      cardBg: cardBg ?? this.cardBg,
      borderStrong: borderStrong ?? this.borderStrong,
      borderSoft: borderSoft ?? this.borderSoft,
      headerChipGradient: headerChipGradient ?? this.headerChipGradient,
      progressGradient: progressGradient ?? this.progressGradient,
    );
  }

  @override
  ComponentColors lerp(ThemeExtension<ComponentColors>? other, double t) {
    if (other is! ComponentColors) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> lerpList(List<Color> a, List<Color> b) =>
        List.generate(a.length, (i) => lerpColor(a[i], b[i]));

    return ComponentColors(
      cardBg: lerpColor(cardBg, other.cardBg),
      borderStrong: lerpColor(borderStrong, other.borderStrong),
      borderSoft: lerpColor(borderSoft, other.borderSoft),
      headerChipGradient: lerpList(
        headerChipGradient,
        other.headerChipGradient,
      ),
      progressGradient: lerpList(progressGradient, other.progressGradient),
    );
  }
}
