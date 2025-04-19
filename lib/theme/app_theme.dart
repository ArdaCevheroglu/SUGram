import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3897F0); // Instagram blue
  static const Color secondaryColor = Color(0xFFED4956); // Instagram red/pink
  static const Color backgroundColor = Colors.white;
  static const Color scaffoldBackgroundColor = Color(0xFFF8F8F8); // Light grey background
  static const Color textColor = Color(0xFF262626); // Dark grey text
  static const Color secondaryTextColor = Color(0xFF8E8E8E); // Medium grey text
  static const Color dividerColor = Color(0xFFDBDBDB); // Light grey divider

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14.0,
    color: textColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12.0,
    color: secondaryTextColor,
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 1,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryTextColor,
    ),
    textTheme: const TextTheme(
      headlineLarge: headingStyle,
      headlineMedium: subheadingStyle,
      bodyLarge: bodyStyle,
      bodyMedium: bodyStyle,
      bodySmall: captionStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: const BorderSide(color: primaryColor),
      ),
    ),
  );
}