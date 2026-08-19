import 'dart:async';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:server_box/data/res/store.dart';

import 'package:server_box/view/platform/ios_palette.dart';

/// A scrollable column of [IosSection]s, inset with the iOS group margins.
class IosGroupedList extends StatelessWidget {
  const IosGroupedList({
    super.key,
    required this.children,
    this.controller,
    this.padding,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i != 0) const SizedBox(height: 28),
          children[i],
        ],
      ],
    );
  }
}

/// An iOS grouped-table section: header, a rounded cell container, footer.
class IosSection extends StatelessWidget {
  const IosSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.background,
    this.borderRadius = 10,
    this.separatorInset = 16,
  });

  final String? header;
  final String? footer;
  final List<Widget> children;
  final Color? background;
  final double borderRadius;

  /// Where the hairline between rows starts, from the left cell edge. Rows
  /// with a leading glyph pass a larger inset so the hairline lines up with
  /// their title column instead of starting under the glyph.
  final double separatorInset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark mode's grouped background is black anyway, so guessing AMOLED
    // from the scaffold color put every dark section at pure black. Ask the
    // setting instead: 3 = AMOLED, 4 = auto-AMOLED (AMOLED only in dark).
    final tMode = Stores.setting.themeMode.fetch();
    final amoled = tMode == 3 || (tMode == 4 && isDark);
    final cellColor =
        background ?? IosPalette.secondaryGroupedBackgroundByBrightness(isDark);
    final separatorColor = IosPalette.separatorByBrightness(isDark);

    final cells = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i != 0) {
        cells.add(Padding(
          padding: EdgeInsets.only(left: separatorInset),
          child: Container(height: 0.5, color: separatorColor),
        ));
      }
      cells.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              header!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: IosPalette.secondaryLabelByBrightness(isDark),
              ),
            ),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: amoled ? Colors.black : cellColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cells,
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              footer!,
              style: TextStyle(
                fontSize: 12,
                color: IosPalette.secondaryLabelByBrightness(isDark),
              ),
            ),
          ),
      ],
    );
  }
}

/// The iOS row in a grouped table.
///
/// 44pt high, 16pt inset, hairline-free (sections draw separators), with the
/// optional disclosure chevron iOS uses for navigation rows. Touch feedback
/// is the iOS momentary highlight — there is no ink ripple.
class IosRow extends StatelessWidget {
  const IosRow({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.height,
    this.titleStyle,
    this.titleColor,
    this.subtitleStyle,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 1,
    this.selected = false,
    this.selectedColor,
    this.trailingFlex = 1.0,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  /// The minimum row height (vertical 4pt padding is added either side).
  final double? height;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final TextStyle? subtitleStyle;
  final int titleMaxLines;
  final int subtitleMaxLines;
  final bool selected;
  final Color? selectedColor;

  /// The fraction of the row width the trailing may occupy at most (1.0 =
  /// unlimited). A value row uses ~0.5 so a long value cannot squeeze the
  /// title to nothing.
  final double trailingFlex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle_ =
        titleStyle ??
        TextStyle(
          fontSize: 17,
          color: titleColor ?? (enabled ? scheme.onSurface : scheme.onSurfaceVariant),
        );
    final subtitleStyle_ =
        subtitleStyle ??
        TextStyle(
          fontSize: 13,
          color: IosPalette.secondaryLabelByBrightness(isDark),
        );

    final effectiveTrailing = trailing ??
        (chevron
            ? Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: IosPalette.grayByBrightness(isDark, level: 2),
              )
            : null);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final maxTrailingW = constraints.maxWidth * trailingFlex;
        final trailingChild = effectiveTrailing == null
            ? null
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTrailingW),
                child: effectiveTrailing,
              );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      maxLines: titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle_,
                    ),
                  if (subtitle != null) ...[
                    if (title != null) const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle_,
                    ),
                  ],
                ],
              ),
            ),
            if (trailingChild != null) ...[
              const SizedBox(width: 8),
              trailingChild,
            ],
          ],
        );
      },
    );

    // Rows size to their content: a minimum height for the standard single-
    // line case, no fixed height, so large Dynamic Type grows the row instead
    // of clipping the text.
    final minHeight =
        height ?? (subtitle != null || titleMaxLines > 1 || subtitleMaxLines > 1
            ? 44.0
            : 32.0);

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: content,
      ),
    );

    if (onTap == null && onLongPress == null) {
      return ColoredBox(
        color: selected ? (selectedColor ?? _selectionColor(context)) : Colors.transparent,
        child: child,
      );
    }
    return IosPressable(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      selected: selected,
      selectedColor: selectedColor ?? _selectionColor(context),
      child: child,
    );
  }

  static Color _selectionColor(BuildContext context) {
    return IosPalette.selectedFillByBrightness(
      Theme.of(context).brightness == Brightness.dark,
    );
  }
}

/// Touch feedback the iOS way: a momentary gray highlight, no ripple.
///
/// The highlight waits a beat after the finger lands (UIKit's delay), and a
/// gesture that turns into a scroll cancels it — so a list the user is
/// dragging never flashes a row. A long press lights only once it is
/// recognized as one.
class IosPressable extends StatefulWidget {
  const IosPressable({
    super.key,
    required this.onTap,
    required this.onLongPress,
    required this.child,
    this.selected = false,
    this.selectedColor,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final bool selected;
  final Color? selectedColor;

  @override
  State<IosPressable> createState() => _IosPressableState();
}

class _IosPressableState extends State<IosPressable> {
  static const _highlightDelay = Duration(milliseconds: 50);

  bool _pressed = false;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _scheduleHighlight() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightDelay, () {
      if (mounted) setState(() => _pressed = true);
    });
  }

  void _cancelHighlight() {
    _highlightTimer?.cancel();
    _highlightTimer = null;
    if (_pressed) setState(() => _pressed = false);
  }

  void _highlightNow() {
    _highlightTimer?.cancel();
    _highlightTimer = null;
    if (!_pressed) setState(() => _pressed = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x0F000000);
    final base = widget.selected
        ? (widget.selectedColor ?? Colors.transparent)
        : Colors.transparent;
    final color = _pressed ? Color.alphaBlend(highlight, base) : base;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _scheduleHighlight(),
      onTapUp: (_) => _cancelHighlight(),
      onTapCancel: _cancelHighlight,
      onLongPressStart: (_) => _highlightNow(),
      onLongPressEnd: (_) => _cancelHighlight(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        color: color,
        child: widget.child,
      ),
    );
  }
}

/// An iOS row whose trailing is a [Switch].
class IosSwitchRow extends StatelessWidget {
  const IosSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IosRow(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: IosPalette.green(context),
      ),
      height: 33,
    );
  }
}

/// An iOS row showing a value, optionally opening a picker.
class IosValueRow extends StatelessWidget {
  const IosValueRow({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.valueColor,
    this.chevron = true,
    this.onTap,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final String value;
  final Color? valueColor;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IosRow(
      title: title,
      subtitle: subtitle,
      leading: leading,
      chevron: chevron,
      onTap: onTap,
      // Long values (model names, IPv6, paths) may not squeeze the title to
      // nothing: cap the value at half the row and ellipsize it.
      trailingFlex: 0.5,
      trailing: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 17,
          color: valueColor ?? IosPalette.secondaryLabelByBrightness(isDark),
        ),
      ),
    );
  }
}

/// The iOS settings icon: a colored rounded square with a white glyph.
class IosSettingsIcon extends StatelessWidget {
  const IosSettingsIcon(this.icon, {super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: color ?? IosPalette.blue(context),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 17, color: Colors.white),
    );
  }
}


/// Turns a settings-style section (a [Column] of CardX-wrapped tiles) into an
/// iOS grouped section: the cards' chrome unwrapped, hairline separators
/// between the rows, everything on the cell surface.
Widget iosifySection(BuildContext context, Widget group) {
  var inner = group;
  if (inner is CardX) inner = inner.child;
  final tiles = inner is Column ? inner.children : <Widget>[inner];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cells = <Widget>[];
  for (var i = 0; i < tiles.length; i++) {
    var tile = tiles[i];
    if (tile is CardX) tile = tile.child;
    cells.add(tile);
    if (i != tiles.length - 1) {
      cells.add(
        Container(
          height: 0.5,
          color: IosPalette.separatorByBrightness(isDark),
          margin: const EdgeInsets.only(left: 16),
        ),
      );
    }
  }
  return Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: IosPalette.secondaryGroupedBackgroundByBrightness(isDark),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(children: cells),
  );
}
