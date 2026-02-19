import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/method_channel_constants.dart';

/// Widget that displays the active payment method badge.
///
/// This widget shows a compact badge with the currently active payment method.
class YandexActivePaymentMethodBadge extends StatelessWidget {
  /// Creates a widget that displays the active payment method badge.
  ///
  /// [height] specifies the height of the widget. Defaults to 48.
  ///
  /// [width] specifies the width of the widget. If not provided, the widget
  /// will expand to fill available width.
  const YandexActivePaymentMethodBadge({
    super.key,
    this.height = 48,
    this.width,
  });

  /// Height of the widget.
  final double height;

  /// Width of the widget.
  ///
  /// If null, the widget will expand to fill available width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final Widget platformView;

    if (defaultTargetPlatform == TargetPlatform.android) {
      platformView = _buildAndroidView();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platformView = _buildIOSView();
    } else {
      return _buildUnsupportedPlatform();
    }

    return SizedBox(
      height: height,
      width: width,
      child: platformView,
    );
  }

  Widget _buildAndroidView() {
    return AndroidView(
      viewType: MethodChannelConstants.activePaymentMethodBadgeViewType,
      layoutDirection: TextDirection.ltr,
      creationParams: null,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
        Factory<LongPressGestureRecognizer>(() => LongPressGestureRecognizer()),
        Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
        ),
        Factory<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
        ),
      },
    );
  }

  Widget _buildIOSView() {
    return UiKitView(
      viewType: MethodChannelConstants.activePaymentMethodBadgeViewType,
      layoutDirection: TextDirection.ltr,
      creationParams: null,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
        Factory<LongPressGestureRecognizer>(() => LongPressGestureRecognizer()),
        Factory<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
        ),
      },
    );
  }

  Widget _buildUnsupportedPlatform() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: const Center(
        child: Text(
          'Yandex Quick Pay is only supported on iOS and Android',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
