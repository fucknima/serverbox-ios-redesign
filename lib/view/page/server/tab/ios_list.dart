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
              icon: Icons.settings_outlined,
              tooltip: libL10n.setting,
              onTap: () => SettingsPage.route.go(context),
            ),
            _IosIconBtn(
              icon: Icons.add,
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
                child: Center(
                  child: Text(libL10n.empty, style: UIs.text13Grey),
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
          InkWell(
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
        srv.needsInteractiveAuth ? Icons.lock_outline : Icons.refresh,
        IosPalette.redLight,
        () {
          TryLimiter.reset(srv.spi.id);
          ref.read(serversProvider.notifier).refresh(spi: srv.spi);
        },
      ),
      ServerConn.disconnected => (
        MingCute.link_3_line,
        IosPalette.grayLight(2),
        () => ref.read(serversProvider.notifier).refresh(spi: srv.spi),
      ),
      ServerConn.finished => (
        MingCute.unlink_2_line,
        IosPalette.grayLight(2),
        () => ref.read(serversProvider.notifier).closeServer(id: srv.spi.id),
      ),
    };

    if (srv.conn == ServerConn.connecting ||
        srv.conn == ServerConn.loading ||
        srv.conn == ServerConn.connected) {
      return const Padding(
        padding: EdgeInsets.all(6),
        child: SizedLoading(24, padding: 2),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(6),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _buildIosMetric(
              value: '${(ss.cpu.usedPercent() ?? 0).toStringAsFixed(0)}%',
              label: 'CPU',
              percent: (ss.cpu.usedPercent() ?? 0) / 100,
              color: IosPalette.blue(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildIosMetric(
              value: '${(ss.mem.usedPercent * 100).toStringAsFixed(0)}%',
              label: 'MEM',
              percent: ss.mem.usedPercent,
              color: IosPalette.green(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: cardNoti.listenVal((v) {
              final type = v.net ?? Stores.setting.netViewType.fetch();
              final device =
                  ref.read(serversProvider).servers[id]?.custom?.netDev;
              final (a, b) = type.build(ss, dev: device);
              return _buildIosNetMetric(
                a,
                b,
                onTap: () => cardNoti.value = cardNoti.value.copyWith(net: type.next),
              );
            }),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildIosMetric(
              value: ss.diskUsage == null
                  ? '--'
                  : '${ss.diskUsage!.usedPercent.toStringAsFixed(0)}%',
              label: 'DSK',
              percent: (ss.diskUsage?.usedPercent ?? 0) / 100,
              color: IosPalette.orange(context),
            ),
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
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(up, style: TextStyle(fontSize: 12, color: grey)),
        const SizedBox(width: 6),
        Text(down, style: TextStyle(fontSize: 12, color: grey)),
      ],
    );
    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
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
    final action = await showModalBottomSheet<Object>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                srv.spi.name,
                style: UIs.text13Grey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              for (final func in powerFuncs)
                ListTile(
                  leading: Icon(ServerPower.icon(func)),
                  title: Text(ServerPower.label(func)),
                  onTap: () {
                    Navigator.pop(context, func);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(libL10n.edit),
                onTap: () {
                  Navigator.pop(context, ServerEditPage.route);
                },
              ),
              const SizedBox(height: 8),
            ],
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
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onTap,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
