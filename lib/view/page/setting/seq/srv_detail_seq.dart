import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/app/server_detail_card.dart';
import 'package:server_box/data/res/store.dart';
import 'package:server_box/view/page/setting/seq/reorder_proxy_decorator.dart';
import 'package:server_box/view/platform/ios_list.dart';
import 'package:server_box/view/platform/ios_palette.dart';

class ServerDetailOrderPage extends StatefulWidget {
    /// Whether it is being shown inside the settings pane rather than pushed.
  ///
  /// The pane already names what it is showing, in the one bar the page has;
  /// a second one under it would say it twice.
  final bool embedded;

  const ServerDetailOrderPage({super.key, this.embedded = false});

  @override
  State<ServerDetailOrderPage> createState() => _ServerDetailOrderPageState();

  static const route = AppRouteNoArg(
    page: ServerDetailOrderPage.new,
    path: '/settings/order/server_detail',
  );
}

class _ServerDetailOrderPageState extends State<ServerDetailOrderPage> {
  final prop = Stores.setting.detailCardOrder;
  final disabledProp = Stores.setting.detailCardDisabled;

  late List<String> _order;
  late Set<String> _enabled;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final keys = prop.fetch();
    final disabled = disabledProp.fetch();
    _order = List<String>.from(keys);
    for (final d in disabled) {
      if (!_order.contains(d)) {
        _order.add(d);
      }
    }
    _enabled = Set<String>.from(keys.where((k) => !disabled.contains(k)));
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(child: _buildBody());
    if (widget.embedded) return body;
    return Scaffold(
      appBar: CustomAppBar(title: Text(l10n.serverDetailOrder)),
      body: body,
    );
  }

  Widget _buildBody() {
    if (isIOS) {
      return ReorderableListView.builder(
        key: const PageStorageKey('srv_detail_seq'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        buildDefaultDragHandles: false,
        itemCount: _order.length,
        proxyDecorator: (child, _, _) => Material(
          color: Colors.transparent,
          elevation: 0,
          child: child,
        ),
        itemBuilder: (_, idx) => _buildIosListItem(_order[idx], idx),
        onReorderItem: _handleReorder,
      );
    }
    return ReorderableListView.builder(
      key: const PageStorageKey('srv_detail_seq'),
      padding: const EdgeInsets.all(7),
      buildDefaultDragHandles: false,
      itemCount: _order.length,
      proxyDecorator: reorderProxyDecorator,
      itemBuilder: (_, idx) => _buildListItem(_order[idx], idx),
      onReorderItem: _handleReorder,
    );
  }

  Widget _buildIosListItem(String key, int idx) {
    final isEnabled = _enabled.contains(key);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ReorderableDelayedDragStartListener(
      key: ValueKey(key),
      index: idx,
      child: Container(
        color: IosPalette.secondaryGroupedBackgroundByBrightness(isDark),
        child: Column(
          children: [
            IosRow(
              title: key,
              titleMaxLines: 1,
              titleColor: isEnabled ? null : Colors.grey,
              leading: IosSettingsIcon(
                ServerDetailCards.fromName(key)?.icon ?? CupertinoIcons.rectangle,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoSwitch(
                    value: isEnabled,
                    onChanged: (_) => _toggleEnabled(key),
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
            if (idx < _order.length - 1)
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

  Widget _buildListItem(String key, int idx) {
    final isEnabled = _enabled.contains(key);
    return ReorderableDelayedDragStartListener(
      key: ValueKey(key),
      index: idx,
      child: CardX(
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 23, right: 11),
          leading: Icon(ServerDetailCards.fromName(key)?.icon),
          title: Text(
            key,
            style: isEnabled ? null : TextStyle(color: Colors.grey),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCheckBox(key, isEnabled),
              ReorderableDragStartListener(
                index: idx,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckBox(String key, bool isEnabled) {
    return Checkbox(value: isEnabled, onChanged: (_) => _toggleEnabled(key));
  }

  void _handleReorder(int oldIndex, int newIndex) {
    final targetIndex = newIndex;
    if (targetIndex == oldIndex) {
      return;
    }

    setState(() {
      final item = _order.removeAt(oldIndex);
      _order.insert(targetIndex, item);
    });
    _saveChanges();
  }

  void _toggleEnabled(String key) {
    setState(() {
      if (_enabled.contains(key)) {
        _enabled.remove(key);
      } else {
        _enabled.add(key);
      }
    });
    _saveChanges();
  }

  void _saveChanges() {
    prop.put(_order);
    final disabledList = _order.where((k) => !_enabled.contains(k)).toList();
    disabledProp.put(disabledList);
  }
}
