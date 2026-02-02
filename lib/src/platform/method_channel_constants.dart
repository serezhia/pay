/// Constants for platform channel communication.
class MethodChannelConstants {
  const MethodChannelConstants._();

  static const String methodChannelName = 'yandex_quick_pay/methods';
  static const String eventChannelName = 'yandex_quick_pay/events';
  static const String platformViewType = 'yandex_quick_pay/payment_methods';
}

/// Method names for the method channel.
class MethodNames {
  const MethodNames._();

  static const String initialize = 'initialize';
  static const String initUi = 'initUi';
  static const String isQuickPaymentEnabled = 'isQuickPaymentEnabled';
  static const String enableQuickPayment = 'enableQuickPayment';
  static const String disableQuickPayment = 'disableQuickPayment';
  static const String getPaymentSessionId = 'getPaymentSessionId';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String handleUserActivity = 'handleUserActivity';
  static const String handleOpenURL = 'handleOpenURL';
}

/// Event types for the event channel.
class EventTypes {
  const EventTypes._();

  static const String paymentEnabledStateChanged = 'paymentEnabledStateChanged';
  static const String sessionExpired = 'sessionExpired';
  static const String paymentResult = 'paymentResult';
}

/// Keys for method channel arguments and results.
class ChannelKeys {
  const ChannelKeys._();

  static const String merchantId = 'merchantId';
  static const String environment = 'environment';
  static const String locale = 'locale';
  static const String theme = 'theme';

  static const String isEnabled = 'isEnabled';
  static const String success = 'success';
  static const String sessionId = 'sessionId';

  static const String type = 'type';
  static const String result = 'result';

  static const String url = 'url';
  static const String handled = 'handled';
}

/// Result values for payment results.
class PaymentResultValues {
  const PaymentResultValues._();

  static const String success = 'success';
  static const String failure = 'failure';
}

/// Error codes for platform exceptions.
class ErrorCodes {
  const ErrorCodes._();

  static const String sessionError = 'SESSION_ERROR';
}

