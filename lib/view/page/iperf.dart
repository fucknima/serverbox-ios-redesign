import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:server_box/core/route.dart';
import 'package:server_box/data/ssh/terminal_source.dart';
import 'package:server_box/view/page/ssh/page/page.dart';
import 'package:server_box/view/platform/ios_list.dart';
import 'package:server_box/view/platform/ios_nav.dart';
import 'package:server_box/view/platform/ios_palette.dart';

class IPerfPage extends StatefulWidget {
  final SpiRequiredArgs args;

  const IPerfPage({super.key, required this.args});

  @override
  State<IPerfPage> createState() => _IPerfPageState();

  static const route = AppRouteArg<void, SpiRequiredArgs>(
    page: IPerfPage.new,
    path: '/iperf',
  );
}

class _IPerfPageState extends State<IPerfPage> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return IosNavBar(
        title: 'iperf',
        actions: [
          Tooltip(
            message: libL10n.start,
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: () {
                if (_hostCtrl.text.isEmpty || _portCtrl.text.isEmpty) {
                  Toast.show(libL10n.empty);
                  return;
                }
                final args = SshPageArgs(
                  source: ServerSource(widget.args.spi),
                  initCmd: 'iperf -c ${_hostCtrl.text} -p ${_portCtrl.text}',
                );
                SSHPage.route.go(context, args);
              },
              child: const Icon(CupertinoIcons.play_fill, size: 22),
            ),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          children: [
            IosSection(
              children: [
                _iosField(
                  controller: _hostCtrl,
                  label: libL10n.host,
                ),
                _iosField(
                  controller: _portCtrl,
                  label: libL10n.port,
                  type: TextInputType.number,
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(title: const Text('iperf')),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  /// One form field on the cell surface, no box of its own.
  Widget _iosField({
    required TextEditingController controller,
    required String label,
    TextInputType? type,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      child: CupertinoTextField(
        controller: controller,
        keyboardType: type,
        autocorrect: false,
        placeholder: label,
        placeholderStyle: TextStyle(
          color: IosPalette.secondaryLabelByBrightness(isDark),
        ),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: null,
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: 'iperf',
      child: const Icon(Icons.send),
      onPressed: () {
        if (_hostCtrl.text.isEmpty || _portCtrl.text.isEmpty) {
          Toast.show(libL10n.empty);
          return;
        }
        final args = SshPageArgs(
          source: ServerSource(widget.args.spi),
          initCmd: 'iperf -c ${_hostCtrl.text} -p ${_portCtrl.text}',
        );
        SSHPage.route.go(context, args);
      },
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      children: [
        Input(
          controller: _hostCtrl,
          label: libL10n.host,
          icon: Icons.computer,
          suggestion: false,
        ),
        Input(
          controller: _portCtrl,
          label: libL10n.port,
          type: TextInputType.number,
          icon: Icons.numbers,
          suggestion: false,
        ),
      ],
    );
  }
}
