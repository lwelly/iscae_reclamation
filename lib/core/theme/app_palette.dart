import 'package:flutter/material.dart';

/// Couleurs sémantiques dérivées du thème actif (clair / sombre).
extension AppPalette on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appCard => Theme.of(this).cardColor;

  Color get appBorder => isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  Color get appMuted => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get appSurfaceLow => isDarkMode ? const Color(0xFF252536) : const Color(0xFFF1F5F9);

  Color get appNavBar => isDarkMode ? const Color(0xFF1E1E2E) : Colors.white;

  Color get appInputFill => isDarkMode ? const Color(0xFF252536) : const Color(0xFFF8FAFF);

  Color get appDivider => Theme.of(this).dividerColor;

  Color get appOnSurface => Theme.of(this).colorScheme.onSurface;

  // Alias compatibles dashboard
  Color get dashCardBg => appCard;
  Color get dashCardBorder => appBorder;
  Color get dashTextMuted => appMuted;
  Color get dashDivider => isDarkMode ? const Color(0xFF334155) : Colors.grey.shade100;
  Color get dashToggleBg => isDarkMode ? const Color(0xFF2D3748) : Colors.grey.shade100;
  Color get dashGridLine => appBorder;
}
