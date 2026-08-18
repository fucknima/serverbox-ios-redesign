import 'package:flutter/material.dart';
import 'package:server_box/data/res/store.dart';

import 'package:server_box/view/platform/ios_palette.dart';

/// A page under an iOS-style collapsing large title.
///
/// The title sits large above the scrollable content and shrinks into the
/// nav bar as the user scrolls, matching the behavior of
/// `CupertinoSliverNavigationBar`/`UINavigationBar` large titles.
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
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? bottomBar;
  final Color? background;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = background ?? IosPalette.groupedBackgroundByBrightness(isDark);
    final textFactor = Stores.setting.textFactor.fetch();

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: textFactor,
      maxScaleFactor: textFactor,
      child: Scaffold(
        backgroundColor: bg,
        bottomNavigationBar: bottomBar,
        body: _wrapRefresh(
          context,
          CustomScrollView(
            physics: onRefresh != null
                ? const AlwaysScrollableScrollPhysics()
                : null,
            slivers: [
            SliverAppBar.large(
              pinned: true,
              leading: leading,
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              actions: actions,
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              forceMaterialTransparency: true,
              actionsPadding: const EdgeInsets.only(right: 8),
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            if (body != null)
              SliverToBoxAdapter(child: body!)
            else
              ...?slivers,
          ],
        ),
        ),
      ),
    );
  }

  Widget _wrapRefresh(BuildContext context, Widget scrollable) {
    final onRefresh = this.onRefresh;
    if (onRefresh == null) return scrollable;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      color: IosPalette.blue(context),
      backgroundColor: IosPalette.secondaryGroupedBackgroundByBrightness(isDark),
      onRefresh: onRefresh,
      child: scrollable,
    );
  }
}

/// The standard 44pt iOS nav bar for non-scrollable pages.
class IosNavBar extends StatelessWidget implements PreferredSizeWidget {
  const IosNavBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.background,
    this.centerTitle = true,
    this.titleStyle,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? background;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Size get preferredSize {
    return Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = background ?? IosPalette.secondaryGroupedBackgroundByBrightness(isDark);
    final paddingTop = MediaQuery.paddingOf(context).top;
    final effectiveLeading =
        leading ??
        (ModalRoute.of(context)?.canPop == true
            ? const BackButton()
            : const SizedBox(width: kToolbarHeight - 16));

    return PreferredSize(
      preferredSize: preferredSize,
      child: Material(
        color: bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: paddingTop + kToolbarHeight,
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: kToolbarHeight, child: effectiveLeading),
                    ),
                    if (title != null)
                      Align(
                        alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: centerTitle ? 0 : 60),
                          child: Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                titleStyle ??
                                TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ),
                    if (actions != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// An iOS toolbar: 49pt row on a blurred surface with a hairline top edge.
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
    return Material(
      color: bg,
      child: SafeArea(
        top: false,
        child: Container(
          height: 48.5,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: IosPalette.separatorByBrightness(isDark)),
            ),
          ),
          child: Row(children: children),
        ),
      ),
    );
  }
}
