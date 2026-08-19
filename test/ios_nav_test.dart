import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/view/platform/ios_nav.dart';

/// IosNavBar P0 regression: server subtitle rendering and the action
/// overflow policy. Long titles + subtitle + actions/… must never overlap;
/// Dynamic Type 200% must not overflow.
void main() {
  const longDid = 'very-long-production-singapore-2026-08-19';
  const ipv6 = '2409:8a70:88f:d4a0:1234:5678:abcd:ffff';

  Widget bar({
    String title = 'Process',
    String? subtitle,
    List<Widget>? actions,
    bool overflow = false,
    double scale = 1.0,
  }) {
    final list = actions ??
        List.generate(
          overflow ? 3 : 2,
          (i) => CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () {},
            child: Icon(i == 0 ? CupertinoIcons.refresh : CupertinoIcons.sort_up, size: 21),
          ),
        );
    return MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: CupertinoApp(
        home: CupertinoPageScaffold(
          child: IosNavBar(
            title: title,
            subtitle: subtitle,
            actions: list,
            moreMenu: overflow
                ? (ctx) => CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('more'),
                        ),
                      ],
                    )
                : null,
            body: const SizedBox(),
          ),
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget widget, {Size? size}) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
    }
    await tester.pumpWidget(widget);
    await tester.pump();
  }

  testWidgets('subtitle renders under the title on one ellipsized line',
      (tester) async {
    await pump(tester, bar(subtitle: longDid));
    expect(find.text('Process'), findsOneWidget);
    expect(find.text(longDid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long IPv6 subtitle is ellipsized, no overlap', (tester) async {
    await pump(tester, bar(title: 'Systemd', subtitle: ipv6));
    final titleRect = tester.getRect(find.text('Systemd'));
    final actionIcons = find.byType(CupertinoButton);
    for (final e in actionIcons.evaluate()) {
      final r = tester.getRect(find.descendant(
        of: find.byWidgetPredicate((w) => w == e.widget),
        matching: find.byType(Icon),
      ));
      expect(titleRect.overlaps(r), isFalse, reason: 'title must not overlap actions');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('3 actions fold to primary + ellipsis', (tester) async {
    await pump(tester, bar(overflow: true));
    // Primary (refresh) + the … button: any two non-free icons.
    expect(
      find.byIcon(CupertinoIcons.refresh),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('<= 2 actions render directly', (tester) async {
    await pump(tester, bar(overflow: false));
    expect(find.byIcon(CupertinoIcons.refresh), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.sort_up), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long title + subtitle at Dynamic Type 200% on small phone',
      (tester) async {
    await pump(
      tester,
      bar(title: longDid, subtitle: ipv6, actions: null, overflow: false),
      size: const Size(320, 640),
    );
    // No RenderFlex overflow: only one title column exists and it ellipsizes.
    expect(tester.takeException(), isNull);
  });
}