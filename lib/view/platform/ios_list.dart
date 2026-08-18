import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  });

  final String? header;
  final String? footer;
  final List<Widget> children;
  final Color? background;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amoled = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cellColor =
        background ?? IosPalette.secondaryGroupedBackgroundByBrightness(isDark);
    final separatorColor = IosPalette.separatorByBrightness(isDark);

    final cells = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i != 0) {
        cells.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            height: 0.5,
            color: separatorColor,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
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
/// optional disclosure chevron iOS uses for navigation rows.
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
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final double? height;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final TextStyle? subtitleStyle;

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

    final content = Row(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle_,
                ),
              if (subtitle != null) ...[
                if (title != null) const SizedBox(height: 1),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle_,
                ),
              ],
            ],
          ),
        ),
        if (effectiveTrailing != null) ...[
          const SizedBox(width: 8),
          effectiveTrailing,
        ],
      ],
    );

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: height ?? (subtitle != null ? 44 : 33),
        child: content,
      ),
    );

    if (onTap == null && onLongPress == null) {
      return ColoredBox(color: Colors.transparent, child: child);
    }
    return InkWell(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      child: child,
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
