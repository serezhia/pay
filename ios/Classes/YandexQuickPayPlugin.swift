import Flutter
import UIKit
import YandexQuickPaySDK

public class YandexQuickPayPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  
  // MARK: - Constants
  
  private enum MethodName {
    static let initialize = "initialize"
    static let isQuickPaymentEnabled = "isQuickPaymentEnabled"
    static let enableQuickPayment = "enableQuickPayment"
    static let disableQuickPayment = "disableQuickPayment"
    static let getPaymentSessionId = "getPaymentSessionId"
    static let login = "login"
    static let logout = "logout"
    static let handleUserActivity = "handleUserActivity"
    static let handleOpenURL = "handleOpenURL"
  }
  
  private enum ChannelKey {
    static let merchantId = "merchantId"
    static let environment = "environment"
    static let locale = "locale"
    static let theme = "theme"
    static let isEnabled = "isEnabled"
    static let success = "success"
    static let sessionId = "sessionId"
    static let type = "type"
    static let result = "result"
    static let url = "url"
    static let handled = "handled"
  }
  
  private enum EventType {
    static let paymentEnabledStateChanged = "paymentEnabledStateChanged"
    static let sessionExpired = "sessionExpired"
    static let paymentResult = "paymentResult"
  }
  
  private enum PaymentResultValue {
    static let success = "success"
    static let failure = "failure"
  }
  
  private enum ErrorCode {
    static let notInitialized = "NOT_INITIALIZED"
    static let invalidArguments = "INVALID_ARGUMENTS"
    static let operationFailed = "OPERATION_FAILED"
    static let isQuickPaymentEnabledFailed = "IS_QUICK_PAYMENT_ENABLED_FAILED"
    static let enableQuickPaymentFailed = "ENABLE_QUICK_PAYMENT_FAILED"
    static let disableQuickPaymentFailed = "DISABLE_QUICK_PAYMENT_FAILED"
    static let loginFailed = "LOGIN_FAILED"
    static let logoutFailed = "LOGOUT_FAILED"
  }
  
  private static let platformViewType = "yandex_quick_pay/payment_methods"
  
  // MARK: - Shared Instance (for PlatformView access)
  
  private static weak var sharedInstance: YandexQuickPayPlugin?
  
  // MARK: - Properties
  
  private var quickPayHandler: FintechQuickPayHandler?
  private var eventSink: FlutterEventSink?
  private var stateListener: QuickPayStateListenerImpl?
  
  // MARK: - Plugin Registration
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "yandex_quick_pay/methods",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "yandex_quick_pay/events",
      binaryMessenger: registrar.messenger()
    )
    
    let instance = YandexQuickPayPlugin()
    sharedInstance = instance
    
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
    
    // Register as application delegate to handle universal links and URL schemes
    registrar.addApplicationDelegate(instance)
    
    // Register PlatformView factory for payment methods widget
    let viewFactory = PaymentMethodsViewFactory(plugin: instance, messenger: registrar.messenger())
    registrar.register(viewFactory, withId: platformViewType)
  }
  
  // MARK: - Internal access for PlatformView
  
  func getQuickPayHandler() -> FintechQuickPayHandler? {
    return quickPayHandler
  }
  
  // MARK: - FlutterPlugin
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case MethodName.initialize:
      handleInitialize(call: call, result: result)
    case MethodName.isQuickPaymentEnabled:
      handleIsQuickPaymentEnabled(result: result)
    case MethodName.enableQuickPayment:
      handleEnableQuickPayment(result: result)
    case MethodName.disableQuickPayment:
      handleDisableQuickPayment(result: result)
    case MethodName.getPaymentSessionId:
      handleGetPaymentSessionId(result: result)
    case MethodName.login:
      handleLogin(result: result)
    case MethodName.logout:
      handleLogout(result: result)
    case MethodName.handleUserActivity:
      handleUserActivity(call: call, result: result)
    case MethodName.handleOpenURL:
      handleOpenURL(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - FlutterStreamHandler
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
  
  // MARK: - Method Handlers
  
  private func handleInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let merchantId = args[ChannelKey.merchantId] as? String,
          let environmentString = args[ChannelKey.environment] as? String else {
      result(FlutterError(
        code: ErrorCode.invalidArguments,
        message: "Missing required arguments: merchantId, environment",
        details: nil
      ))
      return
    }
    
    let localeString = args[ChannelKey.locale] as? String ?? "system"
    let themeString = args[ChannelKey.theme] as? String ?? "system"
    
    let environment = parseEnvironment(environmentString)
    let locale = parseLocale(localeString)
    let theme = parseTheme(themeString)
    
    let config = FTQuickPayConfig(
      merchantId: merchantId,
      locale: locale,
      theme: theme,
      environment: environment,
      enableLogging: false
    )
    
    let listener = QuickPayStateListenerImpl { [weak self] event in
      self?.sendEvent(event)
    }
    self.stateListener = listener
    
    Task { @MainActor [weak self] in
      let presenterViewController = self?.getRootViewController()
      
      self?.quickPayHandler = FintechQuickPayHandler(
        config: config,
        stateListener: listener,
        presenterViewController: presenterViewController
      )

      result(nil)
    }
  }
  
  @MainActor
  private func getRootViewController() -> UIViewController? {
    if let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
       let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
      return rootVC
    }

    if let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first,
       let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
      return rootVC
    }

    return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
  }

  private func handleIsQuickPaymentEnabled(result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    Task { @MainActor in
      do {
        let isEnabled = try await handler.isQuickPaymentEnabled()
        result([ChannelKey.isEnabled: isEnabled])
      } catch {
        result(FlutterError(
          code: ErrorCode.isQuickPaymentEnabledFailed,
          message: String(describing: error),
          details: error.localizedDescription
        ))
      }
    }
  }
  
  private func handleEnableQuickPayment(result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    Task { @MainActor in
      do {
        try await handler.enableQuickPayment()
        result([ChannelKey.success: true])
      } catch {
        result(FlutterError(
          code: ErrorCode.enableQuickPaymentFailed,
          message: String(describing: error),
          details: error.localizedDescription
        ))
      }
    }
  }
  
  private func handleDisableQuickPayment(result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    Task { @MainActor in
      do {
        try await handler.disableQuickPayment()
        result([ChannelKey.success: true])
      } catch {
        result(FlutterError(
          code: ErrorCode.disableQuickPaymentFailed,
          message: String(describing: error),
          details: error.localizedDescription
        ))
      }
    }
  }
  
  private func handleGetPaymentSessionId(result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    Task {
      do {
        let sessionId = try await handler.getPaymentSessionId()
        result([ChannelKey.sessionId: sessionId])
      } catch {
        result(FlutterError(
          code: ErrorCode.operationFailed,
          message: String(describing: error),
          details: error.localizedDescription
        ))
      }
    }
  }
  
  private func handleLogin(result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    Task { @MainActor in
      do {
        try await handler.login()
        result([ChannelKey.success: true])
      } catch {
        result(FlutterError(
          code: ErrorCode.loginFailed,
          message: String(describing: error),
          details: error.localizedDescription
        ))
      }
    }
  }
  
  private func handleLogout(result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    Task { @MainActor in
      do {
        try await handler.logout()
        result(nil)
      } catch {
        result(FlutterError(
          code: ErrorCode.logoutFailed,
          message: String(describing: error),
          details: error.localizedDescription
        ))
      }
    }
  }
  
  private func handleUserActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    guard let args = call.arguments as? [String: Any],
          let urlString = args[ChannelKey.url] as? String,
          let url = URL(string: urlString) else {
      result([ChannelKey.handled: false])
      return
    }
    
    let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    userActivity.webpageURL = url
    
    let handled = handler.handleUserActivity(userActivity)
    result([ChannelKey.handled: handled])
  }
  
  private func handleOpenURL(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let handler = quickPayHandler else {
      result(FlutterError(
        code: ErrorCode.notInitialized,
        message: "SDK not initialized. Call initialize() first.",
        details: nil
      ))
      return
    }
    
    guard let args = call.arguments as? [String: Any],
          let urlString = args[ChannelKey.url] as? String,
          let url = URL(string: urlString) else {
      result([ChannelKey.handled: false])
      return
    }
    
    let handled = handler.handleOpenURL(url)
    result([ChannelKey.handled: handled])
  }
  
  // MARK: - Event Sending
  
  private func sendEvent(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(event)
    }
  }
  
  // MARK: - Helpers
  
  private func parseEnvironment(_ string: String) -> FintechQPEnvironment {
    let value = string.lowercased()
    let result = FintechQPEnvironment(rawValue: value) ?? .sandbox
    return result
  }
  
  private func parseLocale(_ string: String) -> FintechLocale {
    switch string.lowercased() {
    case "ru":
      return .ru
    case "en":
      return .en
    case "system":
      let preferredLanguage = Locale.preferredLanguages.first ?? ""
      return preferredLanguage.hasPrefix("ru") ? .ru : .en
    default:
      return .en
    }
  }
  
  private func parseTheme(_ string: String) -> FTQuickPayThemeColorScheme {
    switch string.lowercased() {
    case "light":
      return .light
    case "dark":
      return .dark
    case "system":
      return .system
    default:
      return .system
    }
  }
}

// MARK: - State Listener Implementation

private class QuickPayStateListenerImpl: FTQuickPaymentStateListener {
  
  private let onEvent: ([String: Any]) -> Void
  
  init(onEvent: @escaping ([String: Any]) -> Void) {
    self.onEvent = onEvent
  }
  
  func onPaymentEnabledStateChanged(isEnabled: Bool) {
    onEvent([
      "type": "paymentEnabledStateChanged",
      "isEnabled": isEnabled
    ])
  }
  
  func onSessionExpired() {
    onEvent([
      "type": "sessionExpired"
    ])
  }
  
  func onPaymentResult(quickpayResult: FTQuickPayResult) {
    let resultValue: String
    switch quickpayResult {
    case .success:
      resultValue = "success"
    case .failure:
      resultValue = "failure"
    }
    
    onEvent([
      "type": "paymentResult",
      "result": resultValue
    ])
  }
}

