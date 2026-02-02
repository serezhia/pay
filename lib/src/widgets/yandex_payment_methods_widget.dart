import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/method_channel_constants.dart';

/// Widget that displays available payment methods and allows managing
/// quick payment settings.
///
/// This widget automatically adjusts its height based on the native content.
class YandexPaymentMethodsWidget extends StatefulWidget {
  /// Creates a widget that displays payment methods.
  ///
  /// [minHeight] specifies the minimum height of the widget while loading.
  /// Defaults to 100.
  ///
  /// [width] specifies the width of the widget. If not provided, the widget
  /// will expand to fill available width.
  ///
  /// [animationDuration] specifies how long the height animation takes.
  /// Set to [Duration.zero] to disable animation.
  const YandexPaymentMethodsWidget({
    super.key,
    this.minHeight = 100,
    this.width,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Minimum height of the widget while loading or before native view reports its size.
  final double minHeight;

  /// Width of the widget.
  ///
  /// If null, the widget will expand to fill available width.
  final double? width;

  /// Duration of the height change animation.
  final Duration animationDuration;

  @override
  State<YandexPaymentMethodsWidget> createState() =>
      _YandexPaymentMethodsWidgetState();
}

class _YandexPaymentMethodsWidgetState extends State<YandexPaymentMethodsWidget> {
  double? _nativeHeight;
  MethodChannel? _methodChannel;

  void _onPlatformViewCreated(int viewId) {
    _methodChannel = MethodChannel(
      '${MethodChannelConstants.platformViewType}/$viewId',
    );
    _methodChannel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'updateHeight') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final height = (args['height'] as num).toDouble();
      if (mounted && height > 0 && height != _nativeHeight) {
        setState(() => _nativeHeight = height);
      }
    }
  }

  @override
  void dispose() {
    _methodChannel?.setMethodCallHandler(null);
    super.dispose();
  }

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

    final height = _nativeHeight ?? widget.minHeight;
    
    return SizedBox(
      height: height,
      width: widget.width,
      child: platformView,
    );
  }

  Widget _buildAndroidView() {
    return AndroidView(
      viewType: MethodChannelConstants.platformViewType,
      layoutDirection: TextDirection.ltr,
      creationParams: null,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
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
      viewType: MethodChannelConstants.platformViewType,
      layoutDirection: TextDirection.ltr,
      creationParams: null,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
        Factory<LongPressGestureRecognizer>(() => LongPressGestureRecognizer()),
        Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
      },
    );
  }

  Widget _buildUnsupportedPlatform() {
    return Container(
      height: widget.minHeight,
      width: widget.width,
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

