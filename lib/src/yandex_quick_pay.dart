import 'dart:async';

import 'package:flutter/services.dart';

import 'models/quick_pay_config.dart';
import 'models/quick_pay_result.dart';
import 'platform/method_channel_constants.dart';
import 'quick_payment_state_listener.dart';

/// Entry point for Yandex Quick Payment SDK.
class YandexQuickPay {
  YandexQuickPay._();

  static YandexQuickPay? _instance;
  static QuickPaymentStateListener? _listener;
  static StreamSubscription<dynamic>? _eventSubscription;

  static const MethodChannel _methodChannel =
      MethodChannel(MethodChannelConstants.methodChannelName);

  static const EventChannel _eventChannel =
      EventChannel(MethodChannelConstants.eventChannelName);

  /// Initialize the SDK.
  ///
  /// Must be called before using any other methods
  ///
  /// [config] specifies the merchant ID, environment, locale, and theme.
  /// [listener] receives callbacks for state changes and payment results.
  ///
  /// The SDK will automatically initialize UI components when the Activity
  /// becomes available. If you need manual control, you can call [initUi]
  /// explicitly after initialization.
  ///
  /// Throws [PlatformException] if initialization fails.
  static Future<void> initialize({
    required QuickPayConfig config,
    required QuickPaymentStateListener listener,
  }) async {
    _listener = listener;

    await _methodChannel.invokeMethod(MethodNames.initialize, config.toMap());

    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          _handleEvent(event);
        }
      },
      onError: (dynamic error) {
        print('YandexQuickPay event stream error: $error');
      },
    );

    _instance = YandexQuickPay._();
  }

  /// Get the instance of [YandexQuickPay].
  ///
  /// Throws [StateError] if [initialize] has not been called yet.
  static YandexQuickPay get instance {
    if (_instance == null) {
      throw StateError(
        'YandexQuickPay must be initialized before use. '
        'Call YandexQuickPay.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize UI components for the SDK manually.
  ///
  /// **Note:** UI initialization happens automatically when the Activity
  /// becomes available, so you typically don't need to call this method.
  ///
  /// Only call this method if you need to reinitialize UI after special
  /// scenarios like calling handling complex navigation flows.
  ///
  /// If called before the Activity is ready, the initialization will be
  /// automatically deferred until the Activity becomes available.
  ///
  /// Throws [PlatformException] if the SDK is not initialized.
  Future<void> initUi() async {
    await _methodChannel.invokeMethod<void>(MethodNames.initUi);
  }

  /// Check if quick payment is enabled for the current user.
  ///
  /// Returns `true` if quick payment is enabled, `false` otherwise.
  ///
  /// Throws [PlatformException] if the operation fails.
  Future<bool> isQuickPaymentEnabled() async {
    final result = await _methodChannel
        .invokeMethod<Map>(MethodNames.isQuickPaymentEnabled);
    return result?[ChannelKeys.isEnabled] as bool? ?? false;
  }

  /// Enable quick payment for the user.
  ///
  /// May show biometric prompt or login screen if needed.
  ///
  /// Returns `true` if the operation was successful, `false` if it was
  /// cancelled or failed in an expected way (e.g., user cancelled).
  ///
  /// Throws [PlatformException] for unexpected errors.
  Future<bool> enableQuickPayment() async {
    final result =
        await _methodChannel.invokeMethod<Map>(MethodNames.enableQuickPayment);
    return result?[ChannelKeys.success] as bool? ?? false;
  }

  /// Disable quick payment for the user.
  ///
  /// Returns `true` if the operation was successful, `false` if it failed
  /// in an expected way.
  ///
  /// Throws [PlatformException] for unexpected errors.
  Future<bool> disableQuickPayment() async {
    final result = await _methodChannel
        .invokeMethod<Map>(MethodNames.disableQuickPayment);
    return result?[ChannelKeys.success] as bool? ?? false;
  }

  /// Get a payment session ID.
  ///
  /// Creates a new payment session. The session has a limited lifetime.
  ///
  /// May show biometric prompt.
  ///
  /// Returns the session ID as a string.
  ///
  /// Throws [PlatformException] if session creation fails.
  Future<String> getPaymentSessionId() async {
    final result = await _methodChannel
        .invokeMethod<Map>(MethodNames.getPaymentSessionId);
    final sessionId = result?[ChannelKeys.sessionId] as String?;
    if (sessionId == null || sessionId.isEmpty) {
      throw PlatformException(
        code: ErrorCodes.sessionError,
        message: 'Failed to get payment session ID',
      );
    }
    return sessionId;
  }

  /// Login the user via Yandex authorization.
  ///
  /// Shows the Yandex login screen if the user is not already authenticated.
  /// This is typically called automatically by [enableQuickPayment], but can
  /// be used separately if needed.
  ///
  /// Returns `true` if login was successful, `false` if cancelled or failed.
  ///
  /// Throws [PlatformException] if the operation fails.
  Future<bool> login() async {
    final result = await _methodChannel.invokeMethod<Map>(MethodNames.login);
    return result?[ChannelKeys.success] as bool? ?? false;
  }

  /// Logout the current user.
  ///
  /// Clears the user's authentication state and disables quick payment.
  ///
  /// Throws [PlatformException] if the operation fails.
  Future<void> logout() async {
    await _methodChannel.invokeMethod<void>(MethodNames.logout);
  }

  /// Handle a user activity (universal link) for Quick Pay.
  ///
  /// On iOS, this forwards the URL with type NSUserActivityTypeBrowsingWeb to the SDK.
  /// On Android, this always returns `false` as it's not applicable.
  ///
  /// [url] is the URL from the universal link.
  ///
  /// Returns `true` if the SDK handled the URL, `false` otherwise.
  Future<bool> handleUserActivity(String url) async {
    final result = await _methodChannel.invokeMethod<Map>(
      MethodNames.handleUserActivity,
      {ChannelKeys.url: url},
    );
    return result?[ChannelKeys.handled] as bool? ?? false;
  }

  /// Show active payment method in the payment methods widget.
  ///
  /// When called, the widget will display the currently active payment method.
  ///
  /// Throws [PlatformException] if the SDK is not initialized.
  Future<void> showActivePaymentMethod() async {
    await _methodChannel
        .invokeMethod<void>(MethodNames.showActivePaymentMethod);
  }

  /// Hide active payment method from the payment methods widget.
  ///
  /// When called, the widget will stop displaying the active payment method.
  ///
  /// Throws [PlatformException] if the SDK is not initialized.
  Future<void> hideActivePaymentMethod() async {
    await _methodChannel
        .invokeMethod<void>(MethodNames.hideActivePaymentMethod);
  }

  /// Handle an open URL (custom URL scheme) for Quick Pay.
  ///
  /// On iOS, this forwards the URL to the native SDK's `handleOpenURL`.
  /// On Android, this always returns `false` as it's not applicable.
  ///
  /// [url] is the URL to handle.
  ///
  /// Returns `true` if the SDK handled the URL, `false` otherwise.
  Future<bool> handleOpenURL(String url) async {
    final result = await _methodChannel.invokeMethod<Map>(
      MethodNames.handleOpenURL,
      {ChannelKeys.url: url},
    );
    return result?[ChannelKeys.handled] as bool? ?? false;
  }

  static void _handleEvent(Map<dynamic, dynamic> event) {
    final type = event[ChannelKeys.type] as String?;
    if (type == null) return;

    switch (type) {
      case EventTypes.paymentEnabledStateChanged:
        final isEnabled = event[ChannelKeys.isEnabled] as bool? ?? false;
        _listener?.onPaymentEnabledStateChanged?.call(isEnabled);
        break;

      case EventTypes.sessionExpired:
        _listener?.onSessionExpired?.call();
        break;

      case EventTypes.paymentResult:
        final resultStr = event[ChannelKeys.result] as String?;
        if (resultStr == null) return;

        final QuickPayResult result;
        if (resultStr == PaymentResultValues.success) {
          result = const QuickPaySuccess();
        } else {
          result = const QuickPayFailure();
        }
        _listener?.onPaymentResult?.call(result);
        break;

      default:
        break;
    }
  }

  static Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _instance = null;
    _listener = null;
  }
}
