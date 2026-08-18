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
          largeTitle: Text(title),
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

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: textFactor,
      maxScaleFactor: textFactor,
      child: CupertinoPageScaffold(
        backgroundColor: bg,
        child: Column(
          children: [
            Expanded(child: scrollView),
            ?bottomBar,
          ],
        ),
      ),
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
    final bg = background ?? IosPalette.secondaryGroupedBackgroundByBrightness(isDark);

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
