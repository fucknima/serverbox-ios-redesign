import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/view/platform/ios_nav.dart';

/// The session header must never let the title slide under the actions: long
/// titles, IPv6, scaled text and narrow screens all ellipsize instead.
///
/// A RenderFlex overflow throws during pump, so each case asserts no
/// exception was raised and that the title did not overlap the trailing
/// button rect.
void main() {
  const longTitle = 'very-long-server-name-production-singapore-01';
  const ipv6 = '2409:8a70:88f:d4a0:1234:5678:abcd:ffff';
  const chinese = '这是一个非常长的服务器名称用于测试溢出情况';

  Widget button(IconData icon) => CupertinoButton(
    padding: const EdgeInsets.all(8),
    onPressed: () {},
    child: Icon(icon, size: 21),
  );

  Future<void> pump(
    WidgetTester tester, {
    required String title,
    int actions = 0,
    double textScale = 1.0,
    Size? size,
  }) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
    }
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData().copyWith(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                IosSessionHeader(
                  title: title,
                  actions: [for (var i = 0; i < actions; i++) button(CupertinoIcons.search)],
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    addTearDown(tester.view.reset);
  }

  /// The title text must sit inside its Expanded and never reach the right
  /// edge where the actions live.
  void expectNoOverlap(WidgetTester tester, String title) {
    final titleRect = tester.getRect(find.text(title));
    // The leftmost action button marks the start of the actions column.
    final actionsRect = tester.getRect(find.byType(CupertinoButton).first);
    // Actions occupy the right side; the title must end before them.
    expect(titleRect.right, lessThanOrEqualTo(actionsRect.left + 0.1),
        reason: '$title overlaps the header actions');
  }

  testWidgets('long title + 1 action ellipsizes without overflow', (tester) async {
    await pump(tester, title: longTitle, actions: 1);
    expect(tester.takeException(), isNull);
    expectNoOverlap(tester, longTitle);
  });

  testWidgets('long title + 2 actions ellipsizes without overflow', (tester) async {
    await pump(tester, title: longTitle, actions: 2);
    expect(tester.takeException(), isNull);
    expectNoOverlap(tester, longTitle);
  });

  testWidgets('IPv6 title + 2 actions ellipsizes without overflow', (tester) async {
    await pump(tester, title: ipv6, actions: 2);
    expect(tester.takeException(), isNull);
    expectNoOverlap(tester, ipv6);
  });

  testWidgets('Dynamic Type 200% still fits', (tester) async {
    await pump(tester, title: longTitle, actions: 2, textScale: 2.0);
    expect(tester.takeException(), isNull);
    expectNoOverlap(tester, longTitle);
  });

  testWidgets('small iPhone width (320) still fits', (tester) async {
    await pump(
      tester,
      title: longTitle,
      actions: 2,
      size: const Size(320, 568),
    );
    expect(tester.takeException(), isNull);
    expectNoOverlap(tester, longTitle);
  });

  testWidgets('chinese long title + actions fits', (tester) async {
    await pump(tester, title: chinese, actions: 2);
    expect(tester.takeException(), isNull);
    expectNoOverlap(tester, chinese);
  });

  testWidgets('terminal header with 3 actions fits', (tester) async {
    await pump(
      tester,
      title: 'prod-shell-01',
      actions: 3,
      size: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('files header with subtitle and actions fits', (tester) async {
    final path = '/var/mobile/Containers/Data/Application/UUID/Documents/very/long/path';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              IosSessionHeader(
                title: 'data',
                subtitle: path,
                actions: [button(CupertinoIcons.search), button(CupertinoIcons.ellipsis)],
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
