import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.frGray,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.frGold,
        primary: AppColors.frBlack,
        secondary: AppColors.frGold,
        surface: AppColors.frWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.frBlack,
        foregroundColor: AppColors.frWhite,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.frWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.frGold, width: 1.5),
        ),
      ),
    );
  }
}
