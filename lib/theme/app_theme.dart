import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A class that contains all theme configurations for the Lecture Room Allocator application.
class AppTheme {
  AppTheme._();

  // Primary colors
  static const Color primary900 =
      Color(0xFF1E3A8A); // App bar, primary buttons, active states
  static const Color primary800 =
      Color(0xFF1E40AF); // Secondary actions, selected states
  static const Color primary700 =
      Color(0xFF1D4ED8); // Accent elements, highlights
  static const Color primary600 =
      Color(0xFF2563EB); // Primary interactive elements
  static const Color primary500 =
      Color(0xFF3B82F6); // Notifications, badges, indicators
  static const Color primary400 =
      Color(0xFF60A5FA); // Progress indicators, secondary highlights
  static const Color primary300 =
      Color(0xFF93C5FD); // Backgrounds for selected items, subtle highlights
  static const Color primary200 =
      Color(0xFFBFDBFE); // Background for information sections, disabled states
  static const Color primary100 =
      Color(0xFFDBEAFE); // Subtle backgrounds, hover states
  static const Color primary50 =
      Color(0xFFEFF6FF); // Very subtle backgrounds, alternate row colors

  // Neutral colors
  static const Color neutral900 =
      Color(0xFF111827); // Primary text, high emphasis content
  static const Color neutral800 = Color(0xFF1F2937); // Secondary text, headers
  static const Color neutral700 =
      Color(0xFF374151); // Tertiary text, subheaders
  static const Color neutral600 =
      Color(0xFF4B5563); // Body text, high emphasis UI elements
  static const Color neutral500 =
      Color(0xFF6B7280); // Secondary body text, medium emphasis UI elements
  static const Color neutral400 =
      Color(0xFF9CA3AF); // Placeholder text, disabled text
  static const Color neutral300 =
      Color(0xFFD1D5DB); // Borders, dividers, separators
  static const Color neutral200 =
      Color(0xFFE5E7EB); // Input backgrounds, subtle borders
  static const Color neutral100 =
      Color(0xFFF3F4F6); // Background for cards, sections
  static const Color neutral50 =
      Color(0xFFF9FAFB); // Page backgrounds, modal backgrounds

  // Semantic colors
  static const Color success600 =
      Color(0xFF16A34A); // Success states, confirmations, check-ins
  static const Color success100 =
      Color(0xFFDCFCE7); // Success backgrounds, success notifications
  static const Color warning600 =
      Color(0xFFD97706); // Warning states, alerts, pending actions
  static const Color warning100 =
      Color(0xFFFEF3C7); // Warning backgrounds, caution indicators
  static const Color error600 =
      Color(0xFFDC2626); // Error states, destructive actions, critical alerts
  static const Color error100 =
      Color(0xFFFEE2E2); // Error backgrounds, error notifications
  static const Color info600 =
      Color(0xFF0284C7); // Information states, help, guidance
  static const Color info100 =
      Color(0xFFE0F2FE); // Information backgrounds, tooltips

  // Light theme colors
  static const Color backgroundLight = neutral50;
  static const Color surfaceLight = Colors.white;
  static const Color onPrimaryLight = Colors.white;
  static const Color onSurfaceLight = neutral900;
  static const Color onBackgroundLight = neutral900;
  static const Color onErrorLight = Colors.white;

  // Dark theme colors
  static const Color backgroundDark = neutral900;
  static const Color surfaceDark = neutral800;
  static const Color onPrimaryDark = Colors.white;
  static const Color onSurfaceDark = Colors.white;
  static const Color onBackgroundDark = Colors.white;
  static const Color onErrorDark = Colors.white;

  // Card and dialog colors
  static const Color cardLight = Colors.white;
  static const Color cardDark = neutral800;
  static const Color dialogLight = Colors.white;
  static const Color dialogDark = neutral800;

  // Shadow colors
  static const Color shadowLight = Color(0x1F000000);
  static const Color shadowDark = Color(0x1FFFFFFF);

  // Divider colors
  static const Color dividerLight = neutral300;
  static const Color dividerDark = neutral700;

  /// Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary600,
      onPrimary: onPrimaryLight,
      primaryContainer: primary100,
      onPrimaryContainer: primary900,
      secondary: primary500,
      onSecondary: onPrimaryLight,
      secondaryContainer: primary50,
      onSecondaryContainer: primary800,
      tertiary: info600,
      onTertiary: Colors.white,
      tertiaryContainer: info100,
      onTertiaryContainer: info600,
      error: error600,
      onError: onErrorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      surfaceContainerHighest: neutral100,
      onSurfaceVariant: neutral700,
      outline: neutral300,
      outlineVariant: neutral200,
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: neutral800,
      onInverseSurface: Colors.white,
      inversePrimary: primary300,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: dividerLight,
    appBarTheme: const AppBarTheme(
      color: primary900,
      foregroundColor: onPrimaryLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
 cardTheme: CardThemeData(
      color: cardLight,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primary600,
      unselectedItemColor: neutral500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary600,
      foregroundColor: onPrimaryLight,
      elevation: 4,
      shape: CircleBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryLight,
        backgroundColor: primary600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: primary600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: true),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceLight,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primary600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: error600),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: error600, width: 2),
      ),
      labelStyle: const TextStyle(
        color: neutral600,
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: neutral400,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      prefixIconColor: neutral500,
      suffixIconColor: neutral500,
      floatingLabelStyle: const TextStyle(
        color: primary600,
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary600;
        }
        return neutral200;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary300;
        }
        return neutral300;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary600;
        }
        return null;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryLight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary600;
        }
        return neutral400;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary600,
      circularTrackColor: primary100,
      linearTrackColor: primary100,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary600,
      thumbColor: primary600,
      overlayColor: primary600.withAlpha(51),
      inactiveTrackColor: neutral300,
      valueIndicatorColor: primary800,
      valueIndicatorTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primary600,
      unselectedLabelColor: neutral500,
      indicatorColor: primary600,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: neutral800,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 12,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: neutral800,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      actionTextColor: primary300,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    chipTheme: ChipThemeData(
 backgroundColor: neutral100,
      disabledColor: neutral200,
      selectedColor: primary100,
      secondarySelectedColor: primary100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: neutral700,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      secondaryLabelStyle: const TextStyle(
        color: primary700,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
 dialogTheme: DialogThemeData(
      backgroundColor: dialogLight,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titleTextStyle: const TextStyle(
        color: neutral900,
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: neutral700,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: dialogLight,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: dialogLight,
      hourMinuteTextColor: neutral900,
      hourMinuteColor: neutral100,
      dayPeriodTextColor: neutral900,
      dayPeriodColor: neutral100,
      dialHandColor: primary600,
      dialBackgroundColor: neutral100,
      dialTextColor: neutral900,
      entryModeIconColor: primary600,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: dialogLight,
      headerBackgroundColor: primary900,
      headerForegroundColor: Colors.white,
      weekdayStyle: const TextStyle(
        color: neutral600,
        fontFamily: 'Inter',
        fontSize: 12,
      ),
      dayStyle: const TextStyle(
        color: neutral900,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      yearStyle: const TextStyle(
        color: neutral900,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      todayBorder: const BorderSide(color: primary600),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary600;
        }
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return null;
      }),
    ),
  );

  /// Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primary400,
      onPrimary: neutral900,
      primaryContainer: primary800,
      onPrimaryContainer: primary100,
      secondary: primary300,
      onSecondary: neutral900,
      secondaryContainer: primary700,
      onSecondaryContainer: primary100,
      tertiary: info400,
      onTertiary: neutral900,
      tertiaryContainer: info700,
      onTertiaryContainer: info100,
      error: error400,
      onError: neutral900,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      surfaceContainerHighest: neutral800,
      onSurfaceVariant: neutral300,
      outline: neutral600,
      outlineVariant: neutral700,
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: neutral200,
      onInverseSurface: neutral900,
      inversePrimary: primary700,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,
    appBarTheme: const AppBarTheme(
      color: neutral800,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
 cardTheme: CardThemeData(
      color: cardDark,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primary400,
      unselectedItemColor: neutral400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary400,
      foregroundColor: neutral900,
      elevation: 4,
      shape: CircleBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: neutral900,
        backgroundColor: primary400,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary400,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: primary400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary400,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: false),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: neutral800,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: neutral600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: neutral600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primary400, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: error400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: error400, width: 2),
      ),
      labelStyle: const TextStyle(
        color: neutral300,
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: neutral500,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      prefixIconColor: neutral400,
      suffixIconColor: neutral400,
      floatingLabelStyle: const TextStyle(
        color: primary400,
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary400;
        }
        return neutral600;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary700;
        }
        return neutral700;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary400;
        }
        return null;
      }),
      checkColor: WidgetStateProperty.all(neutral900),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary400;
        }
        return neutral500;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary400,
      circularTrackColor: primary800,
      linearTrackColor: primary800,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary400,
      thumbColor: primary400,
      overlayColor: primary400.withAlpha(51),
      inactiveTrackColor: neutral600,
      valueIndicatorColor: primary700,
      valueIndicatorTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primary400,
      unselectedLabelColor: neutral400,
      indicatorColor: primary400,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: neutral700,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 12,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: neutral700,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      actionTextColor: primary300,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: neutral700,
      disabledColor: neutral800,
      selectedColor: primary700,
      secondarySelectedColor: primary700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: neutral200,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      secondaryLabelStyle: const TextStyle(
        color: primary200,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
 dialogTheme: DialogThemeData(
      backgroundColor: dialogDark,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: neutral300,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: dialogDark,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: dialogDark,
      hourMinuteTextColor: Colors.white,
      hourMinuteColor: neutral700,
      dayPeriodTextColor: Colors.white,
      dayPeriodColor: neutral700,
      dialHandColor: primary400,
      dialBackgroundColor: neutral700,
      dialTextColor: Colors.white,
      entryModeIconColor: primary400,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: dialogDark,
      headerBackgroundColor: primary800,
      headerForegroundColor: Colors.white,
      weekdayStyle: const TextStyle(
        color: neutral400,
        fontFamily: 'Inter',
        fontSize: 12,
      ),
      dayStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      yearStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      todayBorder: const BorderSide(color: primary400),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary400;
        }
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return neutral900;
        }
        return null;
      }),
    ),
  );

  /// Helper method to build text theme based on brightness
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textHighEmphasis = isLight ? neutral900 : Colors.white;
    final Color textMediumEmphasis = isLight ? neutral700 : neutral300;
    final Color textLowEmphasis = isLight ? neutral500 : neutral400;

    // Using Google Fonts to load Inter font
    TextTheme baseTheme = GoogleFonts.interTextTheme();

    return baseTheme.copyWith(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textHighEmphasis,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: textHighEmphasis,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textHighEmphasis,
        letterSpacing: -0.25,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.5,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textHighEmphasis,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textMediumEmphasis,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textHighEmphasis,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textMediumEmphasis,
        letterSpacing: 0.25,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textLowEmphasis,
        letterSpacing: 0.4,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textMediumEmphasis,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textLowEmphasis,
        letterSpacing: 0.1,
        height: 1.4,
      ),
    );
  }

  /// Theme mode helper
  static ThemeMode getThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  /// Fetch user-specific theme preferences from Firestore
  static Future<ThemeMode> fetchUserThemeMode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Default to system theme if no user is logged in
        return ThemeMode.system;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final themePreference = data?['theme'] ?? 'system';
        return getThemeMode(themePreference);
      } else {
        // Default to system theme if no preferences are found
        return ThemeMode.system;
      }
    } catch (e) {
      debugPrint("Error fetching theme preferences: $e");
      return ThemeMode.system;
    }
  }

  /// Save user-specific theme preferences to Firestore
  static Future<void> saveUserThemeMode(ThemeMode themeMode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final themePreference = themeMode == ThemeMode.light
          ? 'light'
          : themeMode == ThemeMode.dark
              ? 'dark'
              : 'system';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'theme': themePreference});
    } catch (e) {
      debugPrint("Error saving theme preferences: $e");
    }
  }

  // Missing color definitions for dark theme
  static const Color info400 = Color(0xFF38BDF8); // Light blue for dark theme
  static const Color info700 = Color(0xFF0369A1); // Darker blue for dark theme
  static const Color error400 = Color(0xFFF87171); // Light red for dark theme
}
