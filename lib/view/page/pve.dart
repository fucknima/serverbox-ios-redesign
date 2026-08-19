import 'dart:async';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/core/utils/refresh_interval.dart';
import 'package:server_box/core/utils/version.dart';
import 'package:server_box/data/model/app/error.dart';
import 'package:server_box/data/model/server/pve.dart';
import 'package:server_box/data/model/server/server_private_info.dart';
import 'package:server_box/data/provider/pve.dart';
import 'package:server_box/view/platform/ios_list.dart';
import 'package:server_box/view/platform/ios_nav.dart';
import 'package:server_box/view/platform/ios_palette.dart';
import 'package:server_box/view/widget/percent_circle.dart';

final class PvePageArgs {
  final Spi spi;

  const PvePageArgs({required this.spi});
}

final class PvePage extends ConsumerStatefulWidget {
  final PvePageArgs args;

  const PvePage({super.key, required this.args});

  @override
  ConsumerState<PvePage> createState() => _PvePageState();

  static const route = AppRouteArg<void, PvePageArgs>(
    page: PvePage.new,
    path: '/pve',
  );
}

final class _PveVmStats {
  const _PveVmStats({
    required this.cpu,
    required this.maxcpu,
    required this.mem,
    required this.maxmem,
    required this.diskread,
    required this.diskwrite,
    required this.netin,
    required this.netout,
  });

  final double cpu;
  final int maxcpu;
  final int mem;
  final int maxmem;
  final int diskread;
  final int diskwrite;
  final int netin;
  final int netout;

  static _PveVmStats of(PveResIface it) => switch (it) {
        final PveQemu q => _PveVmStats(
            cpu: q.cpu,
            maxcpu: q.maxcpu,
            mem: q.mem,
            maxmem: q.maxmem,
            diskread: q.diskread,
            diskwrite: q.diskwrite,
            netin: q.netin,
            netout: q.netout,
          ),
        final PveLxc l => _PveVmStats(
            cpu: l.cpu,
            maxcpu: l.maxcpu,
            mem: l.mem,
            maxmem: l.maxmem,
            diskread: l.diskread,
            diskwrite: l.diskwrite,
            netin: l.netin,
            netout: l.netout,
          ),
        _ => throw ArgumentError('not a vm'),
      };
}

const _kHorziPadding = 11.0;

final class _PvePageState extends ConsumerState<PvePage> {
  late MediaQueryData _media;
  Timer? _timer;
  bool _isPromptingForTfa = false;
  String? _lastHandledTfaMessage;

  late final _provider = pveProvider(widget.args.spi);
  late final _notifier = ref.read(_provider.notifier);

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _media = MediaQuery.of(context);
  }

  @override
  void initState() {
    super.initState();
    _initRefreshTimer();
    _afterInit();
  }

  @override
  Widget build(BuildContext context) {
    final pveState = ref.watch(_provider);

    // If there is an error, stop the timer
    if (pveState.error != null) {
      _timer?.cancel();
      final error = pveState.error!;
      if (error.type == PveErrType.needTfa &&
          !_isPromptingForTfa &&
          error.message != _lastHandledTfaMessage) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _promptForTfa(error),
        );
      }
    }

    final refreshBtn = pveState.error == null
        ? null
        : () {
            _lastHandledTfaMessage = null;
            _notifier.reconnect();
            _initRefreshTimer();
          };
    if (isIOS) {
      return IosNavBar(
        title: 'PVE',
        subtitle: widget.args.spi.name,
        actions: [
          if (refreshBtn != null)
            Tooltip(
              message: libL10n.refresh,
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: refreshBtn,
                child: const Icon(CupertinoIcons.refresh, size: 21),
              ),
            ),
        ],
        body: pveState.error != null
            ? _buildError(pveState.error!)
            : _buildBody(pveState.data, pveState.loadingStep),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: TwoLineText(up: 'PVE', down: widget.args.spi.name),
        actions: [
          pveState.error == null
              ? UIs.placeholder
              : Btn.icon(text: libL10n.refresh, 
                  icon: const Icon(Icons.refresh),
                  onTap: () {
                    _lastHandledTfaMessage = null;
                    _notifier.reconnect();
                    _initRefreshTimer();
                  },
                ),
        ],
      ),
      body: pveState.error != null
          ? _buildError(pveState.error!)
          : _buildBody(pveState.data, pveState.loadingStep),
    );
  }

  Widget _buildError(PveErr error) {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: Center(child: Text(error.toString())),
    );
  }

  Widget _buildBody(PveRes? data, PveLoadingStep loadingStep) {
    if (data == null) {
      return _buildLoading(loadingStep);
    }
    if (isIOS) return _buildIosBody(data);

    PveResType? lastType;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: _kHorziPadding,
        vertical: 7,
      ),
      itemCount: data.length * 2,
      itemBuilder: (context, index) {
        final item = data[index ~/ 2];
        if (index % 2 == 0) {
          final type = switch (item) {
            final PveNode _ => PveResType.node,
            final PveQemu _ => PveResType.qemu,
            final PveLxc _ => PveResType.lxc,
            final PveStorage _ => PveResType.storage,
            final PveSdn _ => PveResType.sdn,
          };
          if (type == lastType) {
            return UIs.placeholder;
          }
          lastType = type;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                type.toStr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.start,
              ),
            ),
          );
        }
        return switch (item) {
          final PveNode _ => _buildNode(item),
          final PveQemu _ => _buildQemu(item),
          final PveLxc _ => _buildLxc(item),
          final PveStorage _ => _buildStorage(item),
          final PveSdn _ => _buildSdn(item),
        };
      },
    );
  }

  Widget _buildIosBody(PveRes data) {
    final sections = <Widget>[];
    PveResType? lastType;
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final type = switch (item) {
        final PveNode _ => PveResType.node,
        final PveQemu _ => PveResType.qemu,
        final PveLxc _ => PveResType.lxc,
        final PveStorage _ => PveResType.storage,
        final PveSdn _ => PveResType.sdn,
      };
      if (type != lastType) {
        lastType = type;
        sections.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              type.toStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: IosPalette.secondaryLabel(context),
              ),
            ),
          ),
        ));
      }
      final card = switch (item) {
        final PveNode _ => _buildIosNode(item),
        final PveQemu _ => _buildIosVm(item, item, isLxc: false),
        final PveLxc _ => _buildIosVm(item, item, isLxc: true),
        final PveStorage _ => _buildIosStorage(item),
        final PveSdn _ => _buildIosSdn(item),
      };
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: card,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: sections,
    );
  }

  Widget _buildLoading(PveLoadingStep step) {
    final String message = switch (step) {
      PveLoadingStep.forwarding => l10n.pveLoadingForwarding,
      PveLoadingStep.loggingIn => l10n.pveLoadingLogin,
      PveLoadingStep.fetchingData => l10n.pveLoadingData,
      _ => l10n.pveLoadingConnect,
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isIOS)
            const CupertinoActivityIndicator(radius: 14)
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 17),
          Text(
            message,
            style: isIOS
                ? TextStyle(
                    fontSize: 13,
                    color: IosPalette.secondaryLabel(context),
                  )
                : UIs.text13Grey,
          ),
        ],
      ),
    );
  }

  Widget _buildIosNode(PveNode item) {
    return IosSection(
      separatorInset: 16,
      children: [
        IosRow(
          title: item.node,
          trailing: Text(
            item.topRight,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: IosPalette.secondaryLabel(context),
            ),
          ),
        ),
        IosRow(
          title: 'CPU',
          trailingFlex: 0.45,
          trailing: Text(
            '${(item.cpu * 100).toStringAsFixed(1)} %',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        _buildIosProgress(item.cpu / item.maxcpu),
        IosRow(
          title: 'RAM',
          subtitle: '${item.mem.bytes2Str} / ${item.maxmem.bytes2Str}',
          trailingFlex: 0.45,
          trailing: Text(
            item.maxmem.bytes2Str,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        _buildIosProgress(item.mem / item.maxmem),
      ],
    );
  }

  Widget _buildIosProgress(double value) {
    final clamped = value.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      child: SizedBox(
        height: 4,
        child: value <= 0 || value.isNaN
            ? const SizedBox.shrink()
            : ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: ColoredBox(
                  color: IosPalette.gray(context, level: isDark ? 2 : 3),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: clamped,
                    child: ColoredBox(color: IosPalette.teal(context)),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildIosVm(PveCtrlIface item, PveResIface raw, {required bool isLxc}) {
    final stats = _PveVmStats.of(raw);
    final status = _buildIosCtrlBtns(item);
    if (!item.available) {
      return IosSection(
        children: [
          IosRow(title: _wrapNodeName(item), subtitle: item.summary, trailing: status),
        ],
      );
    }
    // VM rows compress nicely into value rows: CPU %, RAM, disk r/w, net.
    final cpuPct = (stats.cpu / stats.maxcpu) * 100;
    final memPct = (stats.mem / stats.maxmem) * 100;
    return IosSection(
      children: [
        IosRow(
          title: _wrapNodeName(item),
          subtitle: item.summary,
          trailing: status,
        ),
        IosRow(
          title: 'CPU',
          trailingFlex: 0.45,
          trailing: Text(
            cpuPct.isFinite ? '${cpuPct.toStringAsFixed(0)} %' : '--',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        _buildIosProgress(stats.cpu / stats.maxcpu),
        IosRow(
          title: 'RAM',
          trailingFlex: 0.5,
          trailing: Text(
            memPct.isFinite ? '${memPct.toStringAsFixed(0)} %' : '--',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        _buildIosProgress(stats.mem / stats.maxmem),
        IosRow(
          title: l10n.read,
          trailingFlex: 0.45,
          trailing: Text(
            stats.diskread.bytes2Str,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        IosRow(
          title: l10n.write,
          trailingFlex: 0.45,
          trailing: Text(
            stats.diskwrite.bytes2Str,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        IosRow(
          title: '${libL10n.download} ↓',
          trailingFlex: 0.45,
          trailing: Text(
            stats.netin.bytes2Str,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        IosRow(
          title: '${libL10n.upload} ↑',
          trailingFlex: 0.45,
          trailing: Text(
            stats.netout.bytes2Str,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildIosStorage(PveStorage item) {
    return IosSection(
      children: [
        IosRow(
          title: _wrapNodeName(item),
          subtitle: item.summary,
          trailing: Text(
            item.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        IosValueRow(title: l10n.plugInType, value: item.plugintype),
      ],
    );
  }

  Widget _buildIosSdn(PveSdn item) {
    return IosSection(
      children: [
        IosRow(
          title: _wrapNodeName(item),
          trailing: Text(
            item.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: IosPalette.secondaryLabel(context),
            ),
          ),
        ),
      ],
    );
  }

  /// Control buttons for a QEMU/LXC: start / stop / restart / shutdown as an
  /// iOS action sheet, labelled from the trailing ellipsis. The destructive
  /// ones confirm through a Cupertino alert.
  Widget _buildIosCtrlBtns(PveCtrlIface item) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      onPressed: () => _showIosCtrlMenu(item),
      child: const Icon(CupertinoIcons.ellipsis, size: 18),
    );
  }

  void _showIosCtrlMenu(PveCtrlIface item) {
    final ctxt = context;
    showCupertinoModalPopup<void>(
      context: ctxt,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(_wrapNodeName(item)),
        message: item.summary.isEmpty ? null : Text(item.summary),
        actions: [
          if (!item.available)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _onCtrl(libL10n.start, item, () => _notifier.start(item.node, item.id));
              },
              child: Text(libL10n.start),
            )
          else ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _onCtrl(libL10n.stop, item, () => _notifier.stop(item.node, item.id));
              },
              child: Text(libL10n.stop),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _onCtrl(libL10n.reboot, item, () => _notifier.reboot(item.node, item.id));
              },
              child: Text(libL10n.reboot),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                _onCtrl(libL10n.shutdown, item, () => _notifier.shutdown(item.node, item.id));
              },
              child: Text(libL10n.shutdown),
            ),
          ],
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(libL10n.cancel),
        ),
      ),
    );
  }

  Widget _buildNode(PveNode item) {
    final valueAnim = AlwaysStoppedAnimation(UIs.primaryColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(item.node, style: UIs.text15Bold),
              const Spacer(),
              Text(item.topRight, style: UIs.text12Grey),
            ],
          ),
          UIs.height13,
          Row(
            children: [
              const Icon(Icons.memory, size: 13, color: Colors.grey),
              UIs.width7,
              const Text('CPU', style: UIs.text12Grey),
              const Spacer(),
              Text(
                '${(item.cpu * 100).toStringAsFixed(1)} %',
                style: UIs.text12Grey,
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: item.cpu / item.maxcpu,
            minHeight: 7,
            valueColor: valueAnim,
          ),
          UIs.height7,
          Row(
            children: [
              const Icon(Icons.view_agenda, size: 13, color: Colors.grey),
              UIs.width7,
              const Text('RAM', style: UIs.text12Grey),
              const Spacer(),
              Text(
                '${item.mem.bytes2Str} / ${item.maxmem.bytes2Str}',
                style: UIs.text12Grey,
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: item.mem / item.maxmem,
            minHeight: 7,
            valueColor: valueAnim,
          ),
        ],
      ),
    ).cardx;
  }

  Widget _buildQemu(PveQemu item) {
    if (!item.available) {
      return ListTile(
        title: Text(_wrapNodeName(item), style: UIs.text13Bold),
        trailing: _buildCtrlBtns(item),
      ).cardx;
    }
    final children = <Widget>[
      const SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox(width: 15),
          Text(_wrapNodeName(item), style: UIs.text13Bold),
          Text('  /  ${item.summary}', style: UIs.text12Grey),
          const Spacer(),
          _buildCtrlBtns(item),
          UIs.width13,
        ],
      ),
      UIs.height7,
      AvgSize(
        totalSize: _media.size.width,
        padding: _kHorziPadding * 2 + 26,
        children: [
          PercentCircle(percent: (item.cpu / item.maxcpu) * 100),
          PercentCircle(percent: (item.mem / item.maxmem) * 100),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${l10n.read}:\n${item.diskread.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                '${l10n.write}:\n${item.diskwrite.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '↓:\n${item.netin.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                '↑:\n${item.netout.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 21),
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: children).cardx;
  }

  Widget _buildLxc(PveLxc item) {
    if (!item.available) {
      return ListTile(
        title: Text(_wrapNodeName(item), style: UIs.text13Bold),
        trailing: _buildCtrlBtns(item),
      ).cardx;
    }
    final children = <Widget>[
      const SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox(width: 15),
          Text(_wrapNodeName(item), style: UIs.text13Bold),
          Text('  /  ${item.summary}', style: UIs.text12Grey),
          const Spacer(),
          _buildCtrlBtns(item),
          UIs.width13,
        ],
      ),
      UIs.height7,
      AvgSize(
        totalSize: _media.size.width,
        padding: _kHorziPadding * 2 + 26,
        children: [
          PercentCircle(percent: (item.cpu / item.maxcpu) * 100),
          PercentCircle(percent: (item.mem / item.maxmem) * 100),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${l10n.read}:\n${item.diskread.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                '${l10n.write}:\n${item.diskwrite.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '↓:\n${item.netin.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                '↑:\n${item.netout.bytes2Str}',
                style: UIs.text11Grey,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 21),
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: children).cardx;
  }

  Widget _buildStorage(PveStorage item) {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_wrapNodeName(item), style: UIs.text13Bold),
              const Spacer(),
              Text(item.summary, style: UIs.text11Grey),
            ],
          ),
          UIs.height7,
          KvRow(k: libL10n.content, v: item.content),
          KvRow(k: l10n.plugInType, v: item.plugintype),
        ],
      ),
    ).cardx;
  }

  Widget _buildSdn(PveSdn item) {
    return ListTile(
      title: Text(_wrapNodeName(item)),
      trailing: Text(item.summary),
    ).cardx;
  }

  Widget _buildCtrlBtns(PveCtrlIface item) {
    const pad = EdgeInsets.symmetric(horizontal: 7, vertical: 5);
    if (!item.available) {
      return Btn.icon(text: 'Start', 
        icon: const Icon(Icons.play_arrow, color: Colors.grey),
        onTap: () => _onCtrl(
          libL10n.start,
          item,
          () => _notifier.start(item.node, item.id),
        ),
      );
    }
    return Row(
      children: [
        Btn.icon(text: 'Stop', 
          icon: const Icon(Icons.stop, color: Colors.grey, size: 20),
          padding: pad,
          onTap: () => _onCtrl(
            libL10n.stop,
            item,
            () => _notifier.stop(item.node, item.id),
          ),
        ),
        Btn.icon(text: libL10n.restart, 
          icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
          padding: pad,
          onTap: () => _onCtrl(
            libL10n.reboot,
            item,
            () => _notifier.reboot(item.node, item.id),
          ),
        ),
        Btn.icon(text: 'Shutdown', 
          icon: const Icon(Icons.power_off, color: Colors.grey, size: 20),
          padding: pad,
          onTap: () => _onCtrl(
            libL10n.shutdown,
            item,
            () => _notifier.shutdown(item.node, item.id),
          ),
        ),
      ],
    );
  }
}

extension on _PvePageState {
  Future<void> _promptForTfa(PveErr error) async {
    if (!mounted || _isPromptingForTfa) return;
    _isPromptingForTfa = true;
    _lastHandledTfaMessage = error.message;
    try {
      final otpController = TextEditingController();
      final submitted = await context.showRoundDialog<bool>(
        title: l10n.pveOtpTitle,
        // Disposed by the tree. `autoFocus` is exactly the case that breaks
        // when the controller goes before the field does.
        child: DisposeWith(
          notifiers: [otpController],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.message ?? l10n.pveOtpRequired),
              const SizedBox(height: 13),
              Input(
                controller: otpController,
                label: l10n.pveOtpLabel,
                hint: '123456',
                icon: Icons.password,
                type: TextInputType.number,
                suggestion: false,
                autoFocus: true,
              ),
            ],
          ),
        ),
        actions: Btnx.cancelOk,
      );
      final otp = otpController.text.trim();

      if (!mounted || submitted != true) return;
      if (otp.isEmpty) {
        Toast.show(l10n.pveOtpRequired);
        return;
      }

      final (_, err) = await context.showLoadingDialog(
        fn: () async {
          await _notifier.submitTfaCode(otp);
          return true;
        },
      );
      if (!mounted) return;
      if (err != null) {
        _lastHandledTfaMessage = null;
        return;
      }

      _lastHandledTfaMessage = null;
      _initRefreshTimer();
    } finally {
      _isPromptingForTfa = false;
    }
  }

  void _onCtrl(
    String action,
    PveCtrlIface item,
    Future<bool> Function() func,
  ) async {
    if (!mounted) return;
    bool? sure;
    if (isIOS) {
      sure = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(libL10n.attention),
          content: Text(libL10n.askContinue('$action ${item.id}')),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(libL10n.cancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      );
    } else {
      sure = await context.showRoundDialog<bool>(
        title: libL10n.attention,
        child: Text(libL10n.askContinue('$action ${item.id}')),
        actions: Btnx.okReds,
      );
    }
    if (sure != true) return;

    final (suc, err) = await context.showLoadingDialog(fn: func);
    if (suc == true) {
      Toast.success(libL10n.success);
    } else {
      Toast.error(err?.toString() ?? libL10n.fail);
    }
  }

  /// Add PveNode if only one node exists
  String _wrapNodeName(PveCtrlIface item) {
    final pveState = ref.read(_provider);
    if (pveState.data?.onlyOneNode ?? false) {
      return item.name;
    }
    return '${item.node} / ${item.name}';
  }

  void _initRefreshTimer() {
    _timer?.cancel();
    final duration = serverStatusRefreshInterval();
    if (duration == null) return;
    _timer = Timer.periodic(duration, (_) {
      if (mounted) {
        _notifier.list();
      }
    });
  }

  void _afterInit() async {
    // Wait for the PVE state to be connected
    while (mounted) {
      final pveState = ref.read(_provider);
      if (pveState.isConnected) {
        final release = pveState.release;
        if (release != null && isVersionLessThan(release, const [8, 0])) {
          if (mounted) {
            Toast.show(l10n.pveVersionLow);
          }
        }
        break;
      }
      if (pveState.error != null) {
        break; // Skip if there is an error
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
