import '../platform/method_channel_constants.dart';
import 'quick_pay_environment.dart';
import 'quick_pay_locale.dart';
import 'quick_pay_theme_color_scheme.dart';

class QuickPayConfig {
  /// Creates a configuration for Yandex Quick Payment SDK.
  ///
  /// [merchantId] is required and identifies your merchant account.
  /// [environment] is required and specifies whether to use sandbox or production.
  /// [locale] defaults to [QuickPayLocale.system].
  /// [theme] defaults to [QuickPayThemeColorScheme.system].
  const QuickPayConfig({
    required this.merchantId,
    required this.environment,
    this.locale = QuickPayLocale.system,
    this.theme = QuickPayThemeColorScheme.system,
  });

  final String merchantId;

  final QuickPayEnvironment environment;

  final QuickPayLocale locale;

  final QuickPayThemeColorScheme theme;

  Map<String, dynamic> toMap() {
    return {
      ChannelKeys.merchantId: merchantId,
      ChannelKeys.environment: environment.name,
      ChannelKeys.locale: locale.name,
      ChannelKeys.theme: theme.name,
    };
  }
}

