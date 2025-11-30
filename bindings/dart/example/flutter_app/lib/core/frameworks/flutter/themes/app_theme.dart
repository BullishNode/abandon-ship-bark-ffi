import 'package:flutter/material.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/component_colors.dart';
import 'color_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.black,
      onPrimary: AppColors.white,
      secondary: AppColors.gray700,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.black,
      error: Colors.red.shade700,
      onError: AppColors.white,
      primaryContainer: AppColors.black,
      onPrimaryContainer: AppColors.white,
      secondaryContainer: AppColors.gray100,
      onSecondaryContainer: AppColors.black,
      surfaceContainerHighest: AppColors.white,
      surfaceContainerHigh: AppColors.white,
      surfaceContainer: AppColors.white,
      surfaceContainerLow: AppColors.offWhite,
      surfaceContainerLowest: AppColors.offWhite,
    );

    final componentColors = ComponentColors(
      cardBg: AppColors.white,
      borderStrong: AppColors.gray300,
      borderSoft: AppColors.gray200,
      headerChipGradient: AppColors.gradientBlackToGray,
      progressGradient: const [
        AppColors.gray700,
        AppColors.gray800,
        AppColors.black,
      ],
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.slate900),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        foregroundColor: AppColors.slate900,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceTranslucent,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.slate200),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: AppColors.slate200),
        backgroundColor: AppColors.slate100,
        labelStyle: const TextStyle(color: AppColors.slate900),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.slate200.withValues(alpha: 0.8)),
        ),
      ),
      dividerColor: AppColors.slate200,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.slate950,
        unselectedItemColor: AppColors.slate400,
        elevation: 8,
      ),
      buttonTheme: const ButtonThemeData(
        colorScheme: ColorScheme.light(primary: AppColors.black),
      ),
      extensions: [componentColors],
    );
  }

  /// DARK THEME - Black & white minimalist
  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.gray400,
      onSecondary: AppColors.black,
      surface: AppColors.black,
      onSurface: AppColors.white,
      error: Colors.red.shade400,
      onError: AppColors.black,
      primaryContainer: AppColors.white,
      onPrimaryContainer: AppColors.black,
      secondaryContainer: AppColors.gray800,
      onSecondaryContainer: AppColors.white,
      surfaceContainerHighest: AppColors.dark700,
      surfaceContainerHigh: AppColors.dark800,
      surfaceContainer: AppColors.dark900,
      surfaceContainerLow: AppColors.black,
      surfaceContainerLowest: AppColors.black,
    );

    final componentColors = const ComponentColors(
      cardBg: AppColors.darkSurfaceTranslucent,
      borderStrong: AppColors.gray800,
      borderSoft: AppColors.gray900,
      headerChipGradient: AppColors.gradientBlackToGray,
      progressGradient: [AppColors.gray700, AppColors.gray800, AppColors.black],
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.black,
      textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.white)),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: AppColors.white,
        shape: const Border(
          bottom: BorderSide(color: AppColors.gray900, width: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.gray800),
        ),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: AppColors.gray800),
        backgroundColor: AppColors.gray900,
        labelStyle: TextStyle(color: AppColors.white),
        shape: StadiumBorder(side: BorderSide(color: AppColors.gray800)),
      ),
      dividerColor: AppColors.gray800,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray800),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.white, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.black,
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.gray600,
        elevation: 0,
      ),
      buttonTheme: const ButtonThemeData(
        colorScheme: ColorScheme.dark(primary: AppColors.white),
      ),
      extensions: [componentColors],
    );
  }
}
