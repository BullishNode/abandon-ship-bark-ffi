import 'package:flutter/material.dart';

class AppColors {
  // Second.tech actual style - Black & White minimalist

  // Blacks
  static const black = Color(0xFF000000); // Pure black
  static const dark900 = Color(0xFF0A0A0A); // Near black
  static const dark800 = Color(0xFF141414); // Very dark gray
  static const dark700 = Color(0xFF1F1F1F); // Dark gray

  // Whites
  static const white = Color(0xFFFFFFFF); // Pure white
  static const offWhite = Color(0xFFFAFAFA); // Off white

  // Grays
  static const gray100 = Color(0xFFF5F5F5);
  static const gray200 = Color(0xFFE5E5E5);
  static const gray300 = Color(0xFFD4D4D4);
  static const gray400 = Color(0xFFA3A3A3);
  static const gray500 = Color(0xFF737373);
  static const gray600 = Color(0xFF525252);
  static const gray700 = Color(0xFF404040);
  static const gray800 = Color(0xFF262626);
  static const gray900 = Color(0xFF171717);

  // Light backgrounds (for compatibility)
  static const slate50 = gray100;
  static const slate100 = gray100;
  static const slate200 = gray200;
  static const slate300 = gray300;
  static const slate400 = gray400;
  static const slate500 = gray500;
  static const slate600 = gray600;
  static const slate700 = gray700;
  static const slate800 = gray800;
  static const slate900 = gray900;
  static const slate950 = black;

  // Text colors - Simple black/white/gray
  static const textPrimary = white;
  static const textSecondary = gray400;
  static const textDark = black;

  // Accent - Keep minimal, use black as primary
  static const primary = black;
  static const primaryLight = gray900;

  // Bitcoin orange for BTC amounts
  static const bitcoin = Color(0xFFF7931A); // Bitcoin orange

  // Keep for compatibility
  static const amber100 = Color(0xFFFEF3C7);
  static const amber200 = Color(0xFFFDE68A);
  static const amber300 = Color(0xFFFCD34D);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = bitcoin;

  // Emerald (success / online)
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);

  // Indigo variants
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo400 = gray600;
  static const indigo600 = gray700;
  static const indigo950 = gray900;

  // Fuchsia (epic)
  static const fuchsia100 = Color(0xFFF5D0FE);
  static const fuchsia400 = Color(0xFFE879F9);
  static const fuchsia600 = Color(0xFFC026D3);

  // Rose (coupons)
  static const rose100 = Color(0xFFFFCDD5);
  static const rose500 = Color(0xFFF43F5E);
  static const rose950 = Color(0xFF4C0519);

  // Violet (perks CTA)
  static const violet400 = Color(0xFFA78BFA);
  static const violet500 = Color(0xFF8B5CF6);

  // Orange for bitcoin
  static const orange500 = bitcoin;

  // Utility backgrounds
  static const lightSurfaceTranslucent = Color(0xFAFFFFFF); // FA = 0.98 alpha
  static const darkSurfaceTranslucent = Color(0xFA000000); // black @98%

  // Minimal gradients - mostly solid blacks
  static const gradientBlackToGray = [
    black,
    gray900,
  ];

  static const gradientGrayToWhite = [
    gray100,
    white,
  ];

  // Keep for compatibility
  static const gradientAmberToRose = [
    gray700,
    gray800,
    black,
  ];

  static const gradientEmeraldPulse = [
    emerald400,
    emerald500,
  ];
}
