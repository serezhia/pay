import 'package:flutter/foundation.dart';

import 'models/quick_pay_result.dart';

/// Listener for quick payment state changes.
class QuickPaymentStateListener {
  /// Creates a listener for quick payment state changes.
  const QuickPaymentStateListener({
    this.onPaymentEnabledStateChanged,
    this.onSessionExpired,
    this.onPaymentResult,
  });

  /// Called when the payment enabled state changes.
  ///
  /// [isEnabled] indicates whether quick payment is currently enabled.
  final void Function(bool isEnabled)? onPaymentEnabledStateChanged;

  /// Called when the payment session expires.
  final VoidCallback? onSessionExpired;

  /// Called when a payment operation completes.
  ///
  /// [result] will be either [QuickPaySuccess] or [QuickPayFailure].
  final void Function(QuickPayResult result)? onPaymentResult;
}

