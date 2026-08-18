import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';

/// The iOS system palette.
///
/// Colors resolve against [BuildContext] brightness, mirroring the semantic
/// roles Apple ships on iOS. Material's `ColorScheme` already covers most
/// roles; these are the ones iOS defines beyond it (system accents and the
/// grouped-list surfaces).
abstract final class IosPalette {
  static const _lightGroupedBackground = Color(0xFFF2F2F7);
  static const _darkGroupedBackground = Color(0xFF000000);

  static const _lightSecondaryGroupedBackground = Color(0xFFFFFFFF);
  static const _darkSecondaryGroupedBackground = Color(0xFF1C1C1E);

  static const _lightSeparator = Color(0x1C000000);
  static const _darkSeparator = Color(0x2CFFFFFF);

  static const _lightSecondaryLabel = Color(0x99000000);
  static const _darkSecondaryLabel = Color(0x99FFFFFF);

  static const _lightSwitchTrack = Color(0xFFE9E9EA);
  static const _darkSwitchTrack = Color(0xFF39393D);

  static const blueLight = Color(0xFF007AFF);
  static const blueDark = Color(0xFF0A84FF);
  static const greenLight = Color(0xFF34C759);
  static const greenDark = Color(0xFF30D158);
  static const redLight = Color(0xFFFF3B30);
  static const redDark = Color(0xFFFF453A);
  static const orangeLight = Color(0xFFFF9500);
  static const orangeDark = Color(0xFFFF9F0A);
  static const yellowLight = Color(0xFFFFCC00);
  static const yellowDark = Color(0xFFFFD60A);
  static const tealLight = Color(0xFF30B0C7);
  static const tealDark = Color(0xFF64D2FF);
  static const purpleLight = Color(0xFFAF52DE);
  static const purpleDark = Color(0xFFBF5AF2);
  static const pinkLight = Color(0xFFFF2D55);
  static const pinkDark = Color(0xFFFF375F);
  static const indigoLight = Color(0xFF5856D6);
  static const indigoDark = Color(0xFF5E5CE6);

  static Color blue(BuildContext c) => c.isDark ? blueDark : blueLight;
  static Color green(BuildContext c) => c.isDark ? greenDark : greenLight;
  static Color red(BuildContext c) => c.isDark ? redDark : redLight;
  static Color orange(BuildContext c) => c.isDark ? orangeDark : orangeLight;
  static Color yellow(BuildContext c) => c.isDark ? yellowDark : yellowLight;
  static Color teal(BuildContext c) => c.isDark ? tealDark : tealLight;
  static Color purple(BuildContext c) => c.isDark ? purpleDark : purpleLight;
  static Color pink(BuildContext c) => c.isDark ? pinkDark : pinkLight;
  static Color indigo(BuildContext c) => c.isDark ? indigoDark : indigoLight;

  static Color grayLight(int level) => _grayLight[level.clamp(0, 5)];
  static Color grayDark(int level) => _grayDark[level.clamp(0, 5)];
  static Color gray(BuildContext c, {int level = 5}) =>
      c.isDark ? grayDark(level) : grayLight(level);

  static const List<Color> _grayLight = [
    Color(0xFF8E8E93),
    Color(0xFFAEAEB2),
    Color(0xFFC7C7CC),
    Color(0xFFD1D1D6),
    Color(0xFFE5E5EA),
    Color(0xFFF2F2F7),
  ];
  static const List<Color> _grayDark = [
    Color(0xFF8E8E93),
    Color(0xFF636366),
    Color(0xFF48484A),
    Color(0xFF3A3A3C),
    Color(0xFF2C2C2E),
    Color(0xFF1C1C1E),
  ];

  static Color groupedBackgroundByBrightness(bool isDark) =>
      isDark ? _darkGroupedBackground : _lightGroupedBackground;

  static Color groupedBackground(BuildContext c) =>
      groupedBackgroundByBrightness(c.isDark);

  static Color secondaryGroupedBackgroundByBrightness(bool isDark) =>
      isDark ? _darkSecondaryGroupedBackground : _lightSecondaryGroupedBackground;

  static Color secondaryGroupedBackground(BuildContext c) =>
      secondaryGroupedBackgroundByBrightness(c.isDark);

  static Color separatorByBrightness(bool isDark) =>
      isDark ? _darkSeparator : _lightSeparator;

  static Color separator(BuildContext c) => separatorByBrightness(c.isDark);

  static Color secondaryLabelByBrightness(bool isDark) =>
      isDark ? _darkSecondaryLabel : _lightSecondaryLabel;

  static Color secondaryLabel(BuildContext c) =>
      secondaryLabelByBrightness(c.isDark);

  static Color switchTrackByBrightness(bool isDark) =>
      isDark ? _darkSwitchTrack : _lightSwitchTrack;

  static Color switchTrack(BuildContext c) => switchTrackByBrightness(c.isDark);

  static Color grayByBrightness(bool isDark, {int level = 5}) =>
      isDark ? grayDark(level) : grayLight(level);
}
