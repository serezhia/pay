import Flutter
import UIKit
import YandexQuickPaySDK

// MARK: - PlatformView Factory

class ActivePaymentMethodBadgeViewFactory: NSObject, FlutterPlatformViewFactory {
  
  private weak var plugin: YandexQuickPayPlugin?
  private let messenger: FlutterBinaryMessenger
  
  init(plugin: YandexQuickPayPlugin, messenger: FlutterBinaryMessenger) {
    self.plugin = plugin
    self.messenger = messenger
    super.init()
  }
  
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return ActivePaymentMethodBadgePlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      plugin: plugin,
      messenger: messenger
    )
  }
  
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

// MARK: - PlatformView Implementation

class ActivePaymentMethodBadgePlatformView: NSObject, FlutterPlatformView {
  
  private let containerView: UIView
  private weak var plugin: YandexQuickPayPlugin?
  private let viewId: Int64
  private let methodChannel: FlutterMethodChannel
  
  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    plugin: YandexQuickPayPlugin?,
    messenger: FlutterBinaryMessenger
  ) {
    self.viewId = viewId
    self.methodChannel = FlutterMethodChannel(
      name: "yandex_quick_pay/active_payment_method_badge/\(viewId)",
      binaryMessenger: messenger
    )
    self.containerView = UIView(frame: frame)
    self.plugin = plugin
    super.init()
    
    containerView.backgroundColor = .clear
    createBadgeWidget()
  }
  
  func view() -> UIView {
    return containerView
  }
  
  private func createBadgeWidget() {
    guard let handler = plugin?.getQuickPayHandler() else {
      return
    }
    
    Task { @MainActor in
      let badgeView: UIView = handler.createActivePaymentMethodBadge()
      badgeView.translatesAutoresizingMaskIntoConstraints = false
      containerView.addSubview(badgeView)
      
      NSLayoutConstraint.activate([
        badgeView.topAnchor.constraint(equalTo: containerView.topAnchor),
        badgeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        badgeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      ])
    }
  }
}
