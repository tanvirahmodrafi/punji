import 'package:flutter/material.dart';

class AppUiStyle {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color page(BuildContext context) => Theme.of(context).colorScheme.surface;

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1F28) : Colors.white;

  static Color cardMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF161B23) : const Color(0xFFF8FAFC);

  static Color cardElevated(BuildContext context) =>
      isDark(context) ? const Color(0xFF141821) : const Color(0xFFF5F6F8);

  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outline.withValues(alpha: 0.35);

  static Color primaryButton(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D3748) : const Color(0xFF111827);

  static List<BoxShadow> cardShadow(BuildContext context) {
    final dark = isDark(context);
    return [
      BoxShadow(
        blurRadius: dark ? 10 : 6,
        offset: const Offset(0, 4),
        color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
      ),
    ];
  }
}
