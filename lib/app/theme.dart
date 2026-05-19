import 'package:flutter/material.dart';

class PetLifeDesign {
  const PetLifeDesign._();

  static const Color creamBackground = Color(0xFFF7F0E4);
  static const Color warmSurface = Color(0xFFFFFBF2);
  static const Color softSurface = Color(0xFFF2E8D8);
  static const Color primaryBrown = Color(0xFF2B2116);
  static const Color secondaryBrown = Color(0xFF7A6B5B);
  static const Color mutedText = Color(0xFF9A8B7A);
  static const Color outline = Color(0xFFE7DCCB);
  static const Color premiumGold = Color(0xFFF2B84B);
  static const Color danger = Color(0xFFC85B4A);
  static const Color success = Color(0xFF74B68A);
  static const Color infoLilac = Color(0xFFEFE5FF);

  static const double radiusSmall = 12;
  static const double radiusMedium = 18;
  static const double radiusLarge = 24;
  static const double radiusExtraLarge = 32;

  static BoxShadow softShadow = BoxShadow(
    color: primaryBrown.withValues(alpha: 0.07),
    blurRadius: 22,
    offset: const Offset(0, 10),
  );

  static BoxShadow subtleShadow = BoxShadow(
    color: primaryBrown.withValues(alpha: 0.045),
    blurRadius: 14,
    offset: const Offset(0, 6),
  );
}

ThemeData buildPetLifeTheme() {
  const colorScheme = ColorScheme.light(
    primary: PetLifeDesign.primaryBrown,
    onPrimary: Colors.white,
    secondary: PetLifeDesign.premiumGold,
    onSecondary: PetLifeDesign.primaryBrown,
    surface: PetLifeDesign.warmSurface,
    onSurface: PetLifeDesign.primaryBrown,
    error: PetLifeDesign.danger,
    outline: PetLifeDesign.outline,
    outlineVariant: PetLifeDesign.outline,
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: PetLifeDesign.creamBackground,
  );

  final textTheme = baseTheme.textTheme.apply(
    bodyColor: PetLifeDesign.primaryBrown,
    displayColor: PetLifeDesign.primaryBrown,
  );

  return baseTheme.copyWith(
    textTheme: textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        color: PetLifeDesign.secondaryBrown,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: PetLifeDesign.secondaryBrown,
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: PetLifeDesign.creamBackground,
      foregroundColor: PetLifeDesign.primaryBrown,
      titleTextStyle: TextStyle(
        color: PetLifeDesign.primaryBrown,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: PetLifeDesign.warmSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: PetLifeDesign.primaryBrown.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        side: const BorderSide(
          color: PetLifeDesign.outline,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: PetLifeDesign.primaryBrown,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            PetLifeDesign.primaryBrown.withValues(alpha: 0.28),
        disabledForegroundColor: Colors.white70,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: PetLifeDesign.primaryBrown,
        side: const BorderSide(color: PetLifeDesign.outline),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PetLifeDesign.secondaryBrown,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PetLifeDesign.warmSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        borderSide: const BorderSide(color: PetLifeDesign.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        borderSide: const BorderSide(color: PetLifeDesign.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        borderSide: const BorderSide(
          color: PetLifeDesign.primaryBrown,
          width: 1.4,
        ),
      ),
      labelStyle: const TextStyle(
        color: PetLifeDesign.secondaryBrown,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: PetLifeDesign.mutedText,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PetLifeDesign.softSurface,
      selectedColor: PetLifeDesign.primaryBrown,
      disabledColor: PetLifeDesign.softSurface.withValues(alpha: 0.5),
      labelStyle: const TextStyle(
        color: PetLifeDesign.secondaryBrown,
        fontWeight: FontWeight.w800,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: PetLifeDesign.outline,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PetLifeDesign.primaryBrown,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: PetLifeDesign.warmSurface,
      indicatorColor: PetLifeDesign.softSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: PetLifeDesign.primaryBrown.withValues(alpha: 0.08),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);

        return TextStyle(
          color: isSelected
              ? PetLifeDesign.primaryBrown
              : PetLifeDesign.mutedText,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);

        return IconThemeData(
          color: isSelected
              ? PetLifeDesign.primaryBrown
              : PetLifeDesign.mutedText,
          size: isSelected ? 24 : 22,
        );
      }),
    ),
  );
}