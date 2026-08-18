import 'dart:async';
import 'dart:io';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/server/private_key_info.dart';
import 'package:server_box/data/provider/private_key.dart';
import 'package:server_box/data/res/store.dart';
import 'package:server_box/view/page/private_key/edit.dart';
import 'package:server_box/view/platform/ios_controls.dart';
import 'package:server_box/view/platform/ios_list.dart';
import 'package:server_box/view/platform/ios_nav.dart';
import 'package:server_box/view/widget/page_columns.dart';

class PrivateKeysListPage extends ConsumerStatefulWidget {
  const PrivateKeysListPage({super.key});

  @override
  ConsumerState<PrivateKeysListPage> createState() => _PrivateKeyListState();

  static const route = AppRouteNoArg(
    page: PrivateKeysListPage.new,
    path: '/private_key',
  );
}

class _PrivateKeyListState extends ConsumerState<PrivateKeysListPage>
    with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return IosNavPage(
        title: l10n.privateKey,
        actions: [
          Tooltip(
            message: libL10n.add,
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: () => PrivateKeyEditPage.route.go(context),
              child: const Icon(CupertinoIcons.add, size: 22),
            ),
          ),
        ],
        body: _buildIosBody(),
      );
    }
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => PrivateKeyEditPage.route.go(context),
      ),
    );
  }

  Widget _buildIosBody() {
    final privateKeyState = ref.watch(privateKeyProvider);
    final pkis = privateKeyState.keys;
    if (pkis.isEmpty) {
      return IosControls.empty(
        context,
        icon: CupertinoIcons.lock_fill,
        title: libL10n.empty,
        actionLabel: libL10n.add,
        onAction: () => PrivateKeyEditPage.route.go(context),
      );
    }
    return IosGroupedList(
      children: [
        IosSection(
          children: [
            for (final item in pkis)
              IosRow(
                title: item.id,
                subtitle: item.type ?? libL10n.unknown,
                leading: const IosSettingsIcon(Icons.key_outlined),
                chevron: true,
                onTap: () => PrivateKeyEditPage.route.go(
                  context,
                  args: PrivateKeyEditPageArgs(pki: item),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    final privateKeyState = ref.watch(privateKeyProvider);
    final pkis = privateKeyState.keys;

    if (pkis.isEmpty) {
      return Center(child: Text(libL10n.empty));
    }

    final children = pkis.map(_buildKeyItem).toList();
    return PageColumns(children: children);
  }

  Widget _buildKeyItem(PrivateKeyInfo item) {
    return ListTile(
      title: Text(item.id),
      subtitle: Text(item.type ?? libL10n.unknown, style: UIs.textGrey),
      onTap: () => PrivateKeyEditPage.route.go(
        context,
        args: PrivateKeyEditPageArgs(pki: item),
      ),
      trailing: const Icon(Icons.edit),
    ).cardx;
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _autoAddSystemPriavteKey();
  }
}

extension on _PrivateKeyListState {
  void _autoAddSystemPriavteKey() async {
    // Only trigger on desktop platform and no private key saved
    if (isDesktop && Stores.snippet.box.keys.isEmpty) {
      final home = Pfs.homeDir;
      if (home == null) return;
      final idRsaFile = File(home.joinPath('.ssh/id_rsa'));
      if (!idRsaFile.existsSync()) return;
      final sysPk = PrivateKeyInfo(
        id: 'system',
        key: await idRsaFile.readAsString(),
      );
      context.showRoundDialog(
        title: libL10n.attention,
        child: Text(l10n.addSystemPrivateKeyTip),
        actions: Btn.ok(
          onTap: () {
            context.popDialog();
            PrivateKeyEditPage.route.go(
              context,
              args: PrivateKeyEditPageArgs(pki: sysPk),
            );
          },
        ).toList,
      );
    }
  }
}
