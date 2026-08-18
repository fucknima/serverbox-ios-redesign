import 'package:flutter/material.dart';

import 'package:server_box/view/platform/ios_palette.dart';

/// Lays the iOS look over a Material3 [ThemeData].
///
/// The app's themes are built once in `app.dart`; on iOS this post-processes
/// them so every Material widget — dialogs, sheets, dividers, inputs — picks
/// up iOS surfaces and accents without the pages choosing between platforms.
extension IosThemeX on ThemeData {
  ThemeData get iosified {
    final scheme = colorScheme;
    final isDark = brightness == Brightness.dark;
    final grouped = IosPalette.groupedBackgroundByBrightness(isDark);
    final cell = IosPalette.secondaryGroupedBackgroundByBrightness(isDark);
    final accent = isDark ? IosPalette.blueDark : IosPalette.blueLight;

    return copyWith(
      scaffoldBackgroundColor: grouped,
      canvasColor: grouped,
      cardColor: cell,
      colorScheme: scheme.copyWith(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        surface: cell,
        onSurfaceVariant: IosPalette.secondaryLabelByBrightness(isDark),
        outlineVariant: IosPalette.separatorByBrightness(isDark),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: cell,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: IosPalette.separatorByBrightness(isDark),
        thickness: 0.5,
        space: 0.5,
      ),
      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cell,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cell,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cell,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        showDragHandle: false,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cell,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF636366) : const Color(0xFF3A3A3C),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (isDark ? IosPalette.greenDark : IosPalette.greenLight)
              : IosPalette.switchTrackByBrightness(isDark),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      sliderTheme: SliderThemeData(activeTrackColor: accent),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cell,
        indicatorColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
        surfaceTintColor: Colors.transparent,
        height: 50,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? accent : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? accent : scheme.onSurfaceVariant,
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
      chipTheme: ChipThemeData(
        selectedColor: IosPalette.grayByBrightness(isDark, level: 4),
        backgroundColor: IosPalette.grayByBrightness(isDark, level: 5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EB),
        hintStyle: TextStyle(
          color: IosPalette.secondaryLabelByBrightness(isDark),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
