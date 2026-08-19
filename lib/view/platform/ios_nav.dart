import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:server_box/data/res/store.dart';

import 'package:server_box/view/platform/ios_palette.dart';

/// A page under an iOS large title that shrinks into the nav bar on scroll.
///
/// The real Cupertino stack: [CupertinoPageScaffold] carrying a
/// [CupertinoSliverNavigationBar] (the UIKit large-title collapse) and a
/// [CupertinoSliverRefreshControl] for pull-to-refresh. No Material scroll
/// chrome anywhere.
class IosNavPage extends StatelessWidget {
  const IosNavPage({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.body,
    this.slivers,
    this.bottomBar,
    this.background,
    this.onRefresh,
    this.controller,
  });

  final String title;

  /// A second, smaller line under the large title (e.g. the server a
  /// directory belongs to).
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? bottomBar;
  final Color? background;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = background ?? IosPalette.groupedBackgroundByBrightness(isDark);
    final textFactor = Stores.setting.textFactor.fetch();
    final canPop = ModalRoute.of(context)?.canPop == true;

    final scrollView = CustomScrollView(
      controller: controller,
      physics: onRefresh != null
          ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
          : null,
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: _buildLargeTitle(context),
          leading:
              leading ??
              (canPop
                  ? CupertinoNavigationBarBackButton(
                      onPressed: () => Navigator.maybePop(context),
                    )
                  : null),
          trailing:
              actions == null
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions!),
          backgroundColor: bg,
        ),
        if (onRefresh != null)
          CupertinoSliverRefreshControl(onRefresh: onRefresh!),
        if (body != null)
          SliverToBoxAdapter(child: body!)
        else
          ...?slivers,
      ],
    );

    // The system Dynamic Type stays in charge; the app's textFactor only
    // steps in when the user actually set one (the default 1.0 passes the
    // system scaler through untouched). Locking the scale here would have
    // made the system 'larger text' setting a no-op.
    final child = CupertinoPageScaffold(
      backgroundColor: bg,
      child: Column(
        children: [
          Expanded(child: scrollView),
          ?bottomBar,
        ],
      ),
    );
    if (textFactor == 1.0) return child;
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: textFactor,
      maxScaleFactor: textFactor,
      child: child,
    );
  }

  Widget _buildLargeTitle(BuildContext context) {
    final subtitle = this.subtitle;
    if (subtitle == null) return Text(title);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: IosPalette.secondaryLabelByBrightness(isDark),
          ),
        ),
      ],
    );
  }
}

/// A page under a standard (non-large) iOS nav bar, for non-scrollable
/// pages. A [CupertinoPageScaffold] carrying a [CupertinoNavigationBar], so
/// bar height, safe area and the bottom hairline all come from the Cupertino
/// system rather than from Material constants.
class IosNavBar extends StatelessWidget {
  const IosNavBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.body,
    this.background,
    this.bottom,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;
  final Color? background;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The bar is one surface with the status bar above it, so it uses the
    // page background — a differently-colored bar read as a strip glued
    // under the system bar.
    final bg = background ?? IosPalette.groupedBackgroundByBrightness(isDark);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        leading:
            leading ??
            (ModalRoute.of(context)?.canPop == true
                ? CupertinoNavigationBarBackButton(
                    onPressed: () => Navigator.maybePop(context),
                  )
                : null),
        middle: title == null
            ? null
            : Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
        trailing:
            actions == null
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions!),
        backgroundColor: bg,
        border: Border(
          bottom: BorderSide(color: IosPalette.separatorByBrightness(isDark)),
        ),
      ),
      child: Column(
        children: [
          if (body != null) Expanded(child: body!),
          ?bottom,
        ],
      ),
    );
  }
}

/// An iOS toolbar: 49pt row on the cell surface with a hairline top edge.
class IosToolbar extends StatelessWidget implements PreferredSizeWidget {
  const IosToolbar({super.key, required this.children, this.background});

  final List<Widget> children;
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(49);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = background ?? IosPalette.secondaryGroupedBackgroundByBrightness(isDark);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: IosPalette.separatorByBrightness(isDark)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(height: 48.5, child: Row(children: children)),
      ),
    );
  }
}

/// The iPhone session header for the terminal and file tabs.
///
/// One bar, the session's name in the middle (tapping it switches sessions),
/// actions on the right. The title lives in an [Expanded] between the
/// leading edge and the actions, so it is squeezed and ellipsized instead of
/// sliding under the buttons — no Stack that lets title and actions overlap.
class IosSessionHeader extends StatelessWidget implements PreferredSizeWidget {
  const IosSessionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onTitleTap,
    this.background,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onTitleTap;
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // One surface with the status bar: the page background, not a bar color.
    final bg = background ?? IosPalette.groupedBackgroundByBrightness(isDark);
    final label = IosPalette.secondaryLabelByBrightness(isDark);

    final titleColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTitleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTitleTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(CupertinoIcons.chevron_down, size: 12, color: label),
                ],
              ],
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: label),
            ),
          ),
      ],
    );

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 44,
          // Row, not Stack: the title is an Expanded between the leading
          // edge and the actions, so both sides take part in the layout and
          // a long title ellipsizes instead of overlapping the buttons.
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(width: 44, child: leading),
              ],
              Expanded(
                child: Center(child: titleColumn),
              ),
              if (actions != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
