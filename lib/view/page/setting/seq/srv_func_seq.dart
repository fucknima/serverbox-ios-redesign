import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:server_box/data/model/app/menu/server_func.dart';
import 'package:server_box/data/res/store.dart';
import 'package:server_box/view/platform/ios_list.dart';
import 'package:server_box/view/platform/ios_palette.dart';

class ServerFuncBtnsOrderPage extends StatefulWidget {
    /// Whether it is being shown inside the settings pane rather than pushed.
  ///
  /// The pane already names what it is showing, in the one bar the page has;
  /// a second one under it would say it twice.
  final bool embedded;

  const ServerFuncBtnsOrderPage({super.key, this.embedded = false});

  @override
  State<ServerFuncBtnsOrderPage> createState() => _ServerDetailOrderPageState();

  static const route = AppRouteNoArg(
    page: ServerFuncBtnsOrderPage.new,
    path: '/setting/seq/srv_func',
  );
}

class _ServerDetailOrderPageState extends State<ServerFuncBtnsOrderPage> {
  final prop = Stores.setting.serverFuncBtns;

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();
    return Scaffold(
      appBar: CustomAppBar(title: Text(libL10n.sequence)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ValBuilder(
      listenable: prop.listenable(),
      builder: (keys) {
        final disabled = ServerFuncBtn.values
            .map((e) => e.index)
            .where((e) => !keys.contains(e))
            .toList();
        final allKeys = [...keys, ...disabled];
        if (isIOS) {
          return ReorderableListView.builder(
            key: const PageStorageKey('srv_func_seq'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, _, _) => Material(
              color: Colors.transparent,
              elevation: 0,
              child: child,
            ),
            itemCount: allKeys.length,
            itemBuilder: (_, idx) =>
                _buildIosListItem(allKeys[idx], idx, keys, allKeys.length),
            onReorderItem: (o, n) {
              if (o >= keys.length || n >= keys.length) {
                Toast.show(libL10n.disabled);
                return;
              }
              if (o == n) {
                return;
              }
              final moved = keys.removeAt(o);
              keys.insert(n, moved);
              prop.set(keys);
            },
          );
        }
        return ReorderableListView.builder(
          key: const PageStorageKey('srv_func_seq'),
          padding: const EdgeInsets.all(7),
          itemCount: allKeys.length,
          itemBuilder: (_, idx) => _buildListItem(allKeys[idx], idx, keys),
          onReorderItem: (o, n) {
            if (o >= keys.length || n >= keys.length) {
              Toast.show(libL10n.disabled);
              return;
            }
            if (o == n) {
              return;
            }
            final moved = keys.removeAt(o);
            keys.insert(n, moved);
            prop.set(keys);
          },
        );
      },
    );
  }

  Widget _buildIosListItem(int key, int idx, List<int> keys, int count) {
    final funcBtn = ServerFuncBtn.values[key];
    final enabled = idx < keys.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ReorderableDelayedDragStartListener(
      key: ValueKey(key),
      index: idx,
      child: Container(
        color: IosPalette.secondaryGroupedBackgroundByBrightness(isDark),
        child: Column(
          children: [
            IosRow(
              title: funcBtn.toStr,
              titleMaxLines: 1,
              titleColor: enabled ? null : Colors.grey,
              leading: IosSettingsIcon(funcBtn.icon),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoSwitch(
                    value: enabled,
                    onChanged: (val) => _toggleFuncEnabled(keys, key, idx, val),
                  ),
                  const SizedBox(width: 4),
                  ReorderableDragStartListener(
                    index: idx,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.line_horizontal_3,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (idx < count - 1)
              Container(
                height: 0.5,
                color: IosPalette.separatorByBrightness(isDark),
                margin: const EdgeInsets.only(left: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleFuncEnabled(List<int> keys, int key, int idx, bool val) {
    if (val) {
      if (idx >= keys.length) {
        keys.add(key);
      } else {
        keys.insert(idx.clamp(0, keys.length), key);
      }
    } else {
      keys.remove(key);
    }
    prop.put(keys);
  }

  Widget _buildListItem(int key, int idx, List<int> keys) {
    final funcBtn = ServerFuncBtn.values[key];
    return CardX(
      key: ValueKey(key),
      child: ListTile(
        title: RichText(
          text: TextSpan(
            children: [
              WidgetSpan(child: Icon(funcBtn.icon)),
              const WidgetSpan(child: UIs.width13),
              TextSpan(text: funcBtn.toStr, style: UIs.textGrey),
            ],
          ),
        ),
        leading: _buildCheckBox(keys, key, idx, idx < keys.length),
      ),
    );
  }

  Widget _buildCheckBox(List<int> keys, int key, int idx, bool value) {
    return Checkbox(
      value: value,
      onChanged: (val) {
        if (val == null) return;
        if (val) {
          if (idx >= keys.length) {
            keys.add(key);
          } else {
            keys.insert(idx - 1, key);
          }
        } else {
          keys.remove(key);
        }
        prop.put(keys);
      },
    );
  }
}
