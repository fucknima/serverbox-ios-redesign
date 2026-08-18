import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:server_box/data/model/server/server.dart';

import 'package:server_box/view/platform/ios_palette.dart';

/// Small building blocks for iOS status rows and server metrics.
abstract final class IosControls {
  /// A filled status dot, like the connectivity light on an iOS status row.
  static Widget dot(Color color, {double size = 8}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// A status dot driven by a server connection state, in the system colors
  /// for the current brightness.
  static Widget connDot(BuildContext context, ServerConn conn, {double size = 8}) {
    final color = switch (conn) {
      ServerConn.finished => IosPalette.green(context),
      ServerConn.failed => IosPalette.red(context),
      ServerConn.connecting || ServerConn.loading || ServerConn.connected =>
        IosPalette.orange(context),
      ServerConn.disconnected => null,
    };
    return color == null
        ? SizedBox(width: size, height: size)
        : dot(color, size: size);
  }

  /// A compact metric: value over a hairline progress bar with a label.
  static Widget metric(
    BuildContext context, {
    required String value,
    required String label,
    required double percent,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            minHeight: 3,
            backgroundColor: IosPalette.grayByBrightness(isDark, level: 3),
            color: color ?? IosPalette.blue(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: IosPalette.secondaryLabelByBrightness(isDark),
          ),
        ),
      ],
    );
  }

  /// The disclosure chevron, standard iOS size and gray.
  static Widget chevron(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      CupertinoIcons.chevron_right,
      size: 20,
      color: color ?? IosPalette.grayByBrightness(isDark, level: 2),
    );
  }

  /// The iOS spinner, sized like the Material one it replaces.
  static Widget loading({double radius = 12}) {
    return CupertinoActivityIndicator(radius: radius);
  }

  /// The iOS spinner with a square layout box for fixed-size slots.
  static Widget loadingBox({double dimension = 24, double radius = 12}) {
    return SizedBox.square(
      dimension: dimension,
      child: CupertinoActivityIndicator(radius: radius),
    );
  }

  /// The unified iOS empty state: icon, title, message, optional action.
  static Widget empty(
    BuildContext context, {
    IconData icon = CupertinoIcons.tray,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grey = IosPalette.secondaryLabelByBrightness(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: IosPalette.grayByBrightness(isDark, level: 3)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: grey),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              CupertinoButton.filled(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  /// The unified iOS error state: title, explanation, detail, retry.
  static Widget error(
    BuildContext context, {
    required String title,
    String? explain,
    String? detail,
    VoidCallback? onRetry,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grey = IosPalette.secondaryLabelByBrightness(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 52,
              color: IosPalette.orange(context),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (explain != null) ...[
              const SizedBox(height: 6),
              Text(
                explain,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: grey),
              ),
            ],
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                detail,
                textAlign: TextAlign.center,
                maxLines: 6,
                style: TextStyle(fontSize: 11, color: grey),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              CupertinoButton.filled(onPressed: onRetry, child: Text(libL10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
