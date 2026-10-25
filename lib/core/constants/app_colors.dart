import 'package:flutter/material.dart';

/// App color definitions for Material 3 design system.
class AppColors {
  AppColors._();

  // Primary brand palette (Deep Indigo / Teal modern financial theme)
  static const Color primary = Color(0xFF1E3A8A); // Royal Navy
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimary = Colors.white;

  // Secondary & Accents
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color accent = Color(0xFF6366F1); // Indigo Accent

  // Semantic Colors
  static const Color expenseRed = Color(0xFFDC2626); // Expense
  static const Color expenseRedLight = Color(0xFFFEE2E2);
  static const Color incomeGreen = Color(0xFF16A34A); // Income
  static const Color incomeGreenLight = Color(0xFFDCFCE7);
  static const Color warningOrange = Color(0xFFEA580C);
  static const Color warningOrangeLight = Color(0xFFFFEDD5);

  // Background & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Background & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color outlineDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food & Drinks': Color(0xFFF97316), // Orange
    'Study': Color(0xFF3B82F6), // Blue
    'Travel': Color(0xFF06B6D4), // Cyan
    'Shopping': Color(0xFFEC4899), // Pink
    'Entertainment': Color(0xFF8B5CF6), // Purple
    'Bills & Utilities': Color(0xFFEAB308), // Amber
    'Healthcare': Color(0xFF10B981), // Emerald
    'Transfer': Color(0xFF64748B), // Slate
    'Other': Color(0xFF9CA3AF), // Gray
  };

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? const Color(0xFF9CA3AF);
  }
}
