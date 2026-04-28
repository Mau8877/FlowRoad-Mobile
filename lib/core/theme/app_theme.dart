import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.frBlack,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.frGold,
        primary: AppColors.frBrown,
        secondary: AppColors.frGold,
        surface: AppColors.frCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.frBlack,
        foregroundColor: AppColors.frGold,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.frGold,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.frCream,
        labelStyle: const TextStyle(
          color: AppColors.frBrown,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: AppColors.frGray.withValues(alpha: 0.75)),
        prefixIconColor: AppColors.frBrown,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.frGold.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.frGold, width: 1.8),
        ),
      ),
    );
  }
}
