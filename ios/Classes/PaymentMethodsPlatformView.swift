import Flutter
import UIKit
import YandexQuickPaySDK

// MARK: - PlatformView Factory

class PaymentMethodsViewFactory: NSObject, FlutterPlatformViewFactory {
  
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
    return PaymentMethodsPlatformView(
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

class PaymentMethodsPlatformView: NSObject, FlutterPlatformView {
  
  private let containerView: HeightReportingView
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
      name: "yandex_quick_pay/payment_methods/\(viewId)",
      binaryMessenger: messenger
    )
    self.containerView = HeightReportingView(frame: frame)
    self.plugin = plugin
    super.init()
    
    containerView.backgroundColor = .clear
    containerView.onHeightChanged = { [weak self] height in
      self?.reportHeight(height)
    }
    createPaymentMethodsWidget()
  }
  
  func view() -> UIView {
    return containerView
  }
  
  private func createPaymentMethodsWidget() {
    guard let handler = plugin?.getQuickPayHandler() else {
      return
    }
    
    Task { @MainActor in
      let widgetView: UIView = handler.createPaymentMethodsWidget()
      widgetView.translatesAutoresizingMaskIntoConstraints = false
      containerView.addSubview(widgetView)
      
      // Don't constrain bottom - let widget use its intrinsicContentSize
      NSLayoutConstraint.activate([
        widgetView.topAnchor.constraint(equalTo: containerView.topAnchor),
        widgetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        widgetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      ])
      
      // Start observing intrinsicContentSize changes
      containerView.startObservingWidget(widgetView)
    }
  }
  
  private func reportHeight(_ height: CGFloat) {
    methodChannel.invokeMethod("updateHeight", arguments: ["height": height])
  }
}

// MARK: - HeightReportingView

private class HeightReportingView: UIView {
  
  var onHeightChanged: ((CGFloat) -> Void)?
  private var lastReportedHeight: CGFloat = 0
  private var boundsObservation: NSKeyValueObservation?
  
  func startObservingWidget(_ widget: UIView) {
    // KVO on bounds - fires when widget size changes
    boundsObservation = widget.observe(\.bounds, options: [.new, .initial]) { [weak self] view, _ in
      let height = view.bounds.height
      if height > 0 {
        self?.reportHeightIfNeeded(height)
      }
    }
  }
  
  private func reportHeightIfNeeded(_ height: CGFloat) {
    guard height > 0, abs(height - lastReportedHeight) > 0.5 else { return }
    lastReportedHeight = height
    onHeightChanged?(height)
  }
  
  deinit {
    boundsObservation?.invalidate()
  }
}

