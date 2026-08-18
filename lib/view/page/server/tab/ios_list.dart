// ignore_for_file: invalid_use_of_protected_member

part of 'tab.dart';

/// The iOS server list: a grouped table under a collapsing large title.
///
/// One row per server, dot-lit by connection state, with the CPU / MEM / NET /
/// DISK metrics drawn as hairline bars beside the row. Power actions moved
/// from the flip card into a long-press action sheet — iOS has no flip cards.
extension _IosList on _ServerPageState {
  Widget _buildIosList() {
    final serverOrder = ref.watch(serversProvider.select((s) => s.serverOrder));
    ref.watch(serversProvider.select((s) => s.tags));

    return _tag.listenVal((val) {
      final filtered = _filterServers(serverOrder);
      return _ServerOpenRequest(
        split: false,
        onOpen: _openRequestedServer,
        child: IosNavPage(
          title: libL10n.server,
          actions: [
            _IosIconBtn(
              icon: CupertinoIcons.gear,
              tooltip: libL10n.setting,
              onTap: () => SettingsPage.route.go(context),
            ),
            _IosIconBtn(
              icon: CupertinoIcons.add,
              tooltip: libL10n.add,
              onTap: _onTapAddServer,
            ),
          ],
          onRefresh: () => ref.read(serversProvider.notifier).refresh(),
          slivers: [
            if (_tags.value.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _IosTagHeader(
                  tags: _tags,
                  onTagChanged: (p0) => _tag.value = p0,
                  initTag: _tag.value,
                ),
              ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: IosControls.empty(
                  context,
                  icon: CupertinoIcons.square_stack_3d_up,
                  title: l10n.emptyServersTitle,
                  message: l10n.emptyServersTip,
                  actionLabel: libL10n.add,
                  onAction: _onTapAddServer,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildIosServerRow(ref.watch(serverProvider(filtered[index]))),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildIosServerRow(ServerState srv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cellColor = IosPalette.secondaryGroupedBackgroundByBrightness(isDark);
    final separatorColor = IosPalette.separatorByBrightness(isDark);
    final connected = srv.conn == ServerConn.finished;

    return ColoredBox(
      color: cellColor,
      child: Column(
        children: [
          IosPressable(
            onTap: () => _onTapCard(context, srv),
            onLongPress: () => _onLongPressIos(srv),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IosControls.connDot(srv.conn),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          srv.spi.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          srv.spi.displayAddr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: IosPalette.secondaryLabelByBrightness(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildIosTopRight(srv),
                  const SizedBox(width: 4),
                  _buildIosConnIcon(srv),
                ],
              ),
            ),
          ),
          if (connected) ...[
            Divider(height: 0.5, thickness: 0.5, color: separatorColor, indent: 16),
            _buildIosMetrics(srv),
          ],
        ],
      ),
    );
  }

  Widget _buildIosTopRight(ServerState srv) {
    final str = srv._getTopRightStr(srv.spi);
    if (str == null) return UIs.placeholder;
    return GestureDetector(
      onTap: () {
        if (srv.status.err == null) return;
        _showFailReason(srv.status);
      },
      child: Text(str, style: UIs.text12Grey),
    );
  }

  Widget _buildIosConnIcon(ServerState srv) {
    final (icon, color, onTap) = switch (srv.conn) {
      ServerConn.connecting || ServerConn.loading || ServerConn.connected => (
        null,
        null,
        null,
      ),
      ServerConn.failed => (
        srv.needsInteractiveAuth
            ? CupertinoIcons.lock_fill
            : CupertinoIcons.refresh,
        IosPalette.redLight,
        () {
          TryLimiter.reset(srv.spi.id);
          ref.read(serversProvider.notifier).refresh(spi: srv.spi);
        },
      ),
      ServerConn.disconnected => (
        CupertinoIcons.link,
        IosPalette.grayLight(2),
        () => ref.read(serversProvider.notifier).refresh(spi: srv.spi),
      ),
      ServerConn.finished => (
        CupertinoIcons.xmark_circle,
        IosPalette.grayLight(2),
        () => ref.read(serversProvider.notifier).closeServer(id: srv.spi.id),
      ),
    };

    if (srv.conn == ServerConn.connecting ||
        srv.conn == ServerConn.loading ||
        srv.conn == ServerConn.connected) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: IosControls.loadingBox(dimension: 24),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  Widget _buildIosMetrics(ServerState srv) {
    final ss = srv.status;
    final id = srv.spi.id;
    final cardNoti = _getCardNoti(id);
    // Narrow phones get two rows: CPU/MEM/DSK on the first, the network
    // reading on its own line where a long speed has room to breathe.
    final narrow = MediaQuery.sizeOf(context).width < 390;

    final cpu = _buildIosMetric(
      value: '${(ss.cpu.usedPercent() ?? 0).toStringAsFixed(0)}%',
      label: 'CPU',
      percent: (ss.cpu.usedPercent() ?? 0) / 100,
      color: IosPalette.blue(context),
    );
    final mem = _buildIosMetric(
      value: '${(ss.mem.usedPercent * 100).toStringAsFixed(0)}%',
      label: 'MEM',
      percent: ss.mem.usedPercent,
      color: IosPalette.green(context),
    );
    final dsk = _buildIosMetric(
      value: ss.diskUsage == null
          ? '--'
          : '${ss.diskUsage!.usedPercent.toStringAsFixed(0)}%',
      label: 'DSK',
      percent: (ss.diskUsage?.usedPercent ?? 0) / 100,
      color: IosPalette.orange(context),
    );
    final net = cardNoti.listenVal((v) {
      final type = v.net ?? Stores.setting.netViewType.fetch();
      final device = ref.read(serversProvider).servers[id]?.custom?.netDev;
      final (a, b) = type.build(ss, dev: device);
      return _buildIosNetMetric(
        a,
        b,
        onTap: () => cardNoti.value = cardNoti.value.copyWith(net: type.next),
      );
    });

    if (!narrow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Expanded(child: cpu),
            const SizedBox(width: 14),
            Expanded(child: mem),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: net),
            const SizedBox(width: 14),
            Expanded(child: dsk),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: cpu),
              const SizedBox(width: 14),
              Expanded(child: mem),
              const SizedBox(width: 14),
              Expanded(child: dsk),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'NET',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 8),
              Expanded(child: net),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIosMetric({
    required String value,
    required String label,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 3,
            color: color,
            backgroundColor: IosPalette.grayLight(4),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildIosNetMetric(String up, String down, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grey = IosPalette.secondaryLabelByBrightness(isDark);
    // Scale down rather than overflow: an IPv6-length or multi-GB reading
    // must not push the row past its column.
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(up, style: TextStyle(fontSize: 12, color: grey)),
          const SizedBox(width: 6),
          Text(down, style: TextStyle(fontSize: 12, color: grey)),
        ],
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: child,
      ),
    );
  }

  Future<void> _onLongPressIos(ServerState srv) async {
    final powerFuncs = srv.conn == ServerConn.finished
        ? ServerPower.funcs
        : const <ShellFunc>[];
    // iOS action sheet: destructive shutdown last among the actions, cancel
    // below, presented with the Cupertino pop transition.
    final action = await showCupertinoModalPopup<Object>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(
            srv.spi.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            for (final func in powerFuncs)
              CupertinoActionSheetAction(
                isDefaultAction: func == ShellFunc.suspend,
                isDestructiveAction: func == ShellFunc.shutdown,
                onPressed: () => Navigator.pop(context, func),
                child: Text(ServerPower.label(func)),
              ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, ServerEditPage.route),
              child: Text(libL10n.edit),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(libL10n.cancel),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action is ShellFunc) {
      ServerPower.confirmAndRun(context, ref, srv.spi, action);
    } else if (action == ServerEditPage.route) {
      ServerEditPage.route.go(context, args: SpiRequiredArgs(srv.spi));
    }
  }
}

/// The tag chips pinned under the large title.
class _IosTagHeader extends SliverPersistentHeaderDelegate {
  const _IosTagHeader({
    required this.tags,
    required this.onTagChanged,
    required this.initTag,
  });

  final ValueNotifier<Set<String>> tags;
  final void Function(String) onTagChanged;
  final String initTag;

  @override
  double get minExtent => TagSwitcher.kTagBtnHeight;

  @override
  double get maxExtent => TagSwitcher.kTagBtnHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: IosPalette.groupedBackgroundByBrightness(isDark),
      child: TagSwitcher(
        tags: tags,
        onTagChanged: onTagChanged,
        initTag: initTag,
        singleLine: true,
        reversed: true,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _IosTagHeader oldDelegate) {
    return oldDelegate.initTag != initTag ||
        oldDelegate.onTagChanged != onTagChanged;
  }
}

class _IosIconBtn extends StatelessWidget {
  const _IosIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onTap,
        child: Icon(
          icon,
          size: 22,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
