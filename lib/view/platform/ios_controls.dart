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

  /// A status dot driven by a server connection state.
  static Widget connDot(ServerConn conn, {double size = 8}) {
    final color = switch (conn) {
      ServerConn.finished => IosPalette.greenLight,
      ServerConn.failed => IosPalette.redLight,
      ServerConn.connecting || ServerConn.loading || ServerConn.connected =>
        IosPalette.orangeLight,
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
      Icons.chevron_right,
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
}
