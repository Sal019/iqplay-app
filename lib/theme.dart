import 'package:flutter/material.dart';

/// Theme values taken from the iQPlay site's CSS variables (see spec).
class AppPalette {
  final bool dark;
  final Color background;
  final Color card;
  final Color sidebar;
  final Color modal;
  final Color text;
  final Color textStrong;
  final Color secondary;
  final Color border;
  final Color keyColor;

  const AppPalette({
    required this.dark,
    required this.background,
    required this.card,
    required this.sidebar,
    required this.modal,
    required this.text,
    required this.textStrong,
    required this.secondary,
    required this.border,
    required this.keyColor,
  });

  static const darkPalette = AppPalette(
    dark: true,
    background: Color(0xFF121314),
    card: Color(0xFF1A1A1A),
    sidebar: Color(0xFF101114),
    modal: Color(0xFF1B1D21),
    text: Color(0xFFF9F9F9),
    textStrong: Color(0xFFFFFFFF),
    secondary: Color(0xFFCCCCCC),
    border: Color(0x61414553), // rgba(65,69,83,0.38)
    keyColor: Color(0xFF1CC749),
  );

  static const lightPalette = AppPalette(
    dark: false,
    background: Color(0xFFFDFDFD),
    card: Color(0xFFF9F9F9),
    sidebar: Color(0xFFF1F1F1),
    modal: Color(0xFFFFFFFF),
    text: Color(0xFF111111),
    textStrong: Color(0xFF1C1C1C),
    secondary: Color(0xFF555555),
    border: Color(0xFFE2E2E2),
    keyColor: Color(0xFFD52C1F),
  );
}

/// Selectable accent styles (the site's theme/style modal). Index 0 is the
/// site default: linear-gradient(45deg, #ee0979, #ff6a00).
class AccentStyle {
  final String name;
  final List<Color> colors;
  const AccentStyle(this.name, this.colors);

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      );

  Color get primary => colors.first;
}

const List<AccentStyle> kAccentStyles = [
  AccentStyle('Sunset Pink', [Color(0xFFEE0979), Color(0xFFFF6A00)]),
  AccentStyle('Ocean Blue', [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
  AccentStyle('Purple Haze', [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
  AccentStyle('Emerald', [Color(0xFF11998E), Color(0xFF38EF7D)]),
  AccentStyle('Crimson', [Color(0xFFD52C1F), Color(0xFFFF512F)]),
  AccentStyle('Royal Gold', [Color(0xFFF7971E), Color(0xFFFFD200)]),
];

ThemeData buildTheme(AppPalette p, AccentStyle accent) {
  final scheme = ColorScheme(
    brightness: p.dark ? Brightness.dark : Brightness.light,
    primary: accent.primary,
    onPrimary: Colors.white,
    secondary: accent.colors.last,
    onSecondary: Colors.white,
    error: const Color(0xFFE53935),
    onError: Colors.white,
    surface: p.card,
    onSurface: p.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    fontFamily: 'Roboto',
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: p.text, fontSize: 14),
      bodySmall: TextStyle(color: p.secondary, fontSize: 12),
      titleMedium: TextStyle(
          color: p.textStrong, fontSize: 16, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
          color: p.textStrong, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      elevation: 0,
    ),
    dividerColor: p.border,
    iconTheme: IconThemeData(color: p.text),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.modal,
      contentTextStyle: TextStyle(color: p.text),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.modal),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.modal),
    chipTheme: ChipThemeData(
      backgroundColor: p.card,
      selectedColor: accent.primary,
      labelStyle: TextStyle(color: p.text, fontSize: 12),
      side: BorderSide(color: p.border),
    ),
  );
}
