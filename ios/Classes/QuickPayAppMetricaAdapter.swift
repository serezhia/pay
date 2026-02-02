import YandexQuickPaySDK
import AppMetricaCore
import AppMetricaCoreExtension

class QuickPayAppMetricaAdapter: FintechAppMetricaAdapter {

  var uuid: String {
    AppMetrica.uuid
  }
  var deviceID: String? {
    AppMetrica.deviceID
  }

  func isReporterCreated(for apiKey: String) -> Bool {
    AppMetrica.isReporterCreated(forAPIKey: apiKey)
  }
  
  func reporter(for apiKey: String) throws(FintechSDKAnalyticsInterfaces.FintechAppMetricaError) -> any FintechSDKAnalyticsInterfaces.FintechAppMetricaReportingAdapter {
    guard let reporter = AppMetrica.reporter(for: apiKey)?.fintechValue else {
      assertionFailure("AppMetrica Reporter wasn't created")
      throw .reporterCreationError(apiKey: apiKey)
    }
    return reporter
  }
  
  func extendedReporter(for apiKey: String) throws(FintechSDKAnalyticsInterfaces.FintechAppMetricaError) -> any FintechSDKAnalyticsInterfaces.FintechAppMetricaReportingAdapter {
    guard let reporter = AppMetrica.extendedReporter(for: apiKey)?.fintechValue else {
      throw .reporterCreationError(apiKey: apiKey)
    }
    return reporter
  }
  
  func activateReporter(for apiKey: String) throws(FintechSDKAnalyticsInterfaces.FintechAppMetricaError) {
    guard let config = MutableReporterConfiguration(apiKey: apiKey) else {
      throw .configCreationError(apiKey: apiKey)
    }

    AppMetrica.activateReporter(with: config)
  }
}

class QuickPayAppMetricaReporter: FintechAppMetricaReportingAdapter {
  private let reporter: AppMetricaReporting

  init(reporter: AppMetricaReporting) {
    self.reporter = reporter
  }

  func report(eventName: String, params: [String : Any], onFailure: ((any Error) -> Void)?) {
    reporter.reportEvent(name: eventName, parameters: params, onFailure: onFailure)
  }

  func setPUID(_ puid: String?) {
    reporter.userProfileID = puid
  }

  func setAppEnvironment(_ value: String, for key: String) {
    reporter.setAppEnvironment(value, forKey: key)
  }
}

extension AppMetricaReporting {
  var fintechValue: FintechAppMetricaReportingAdapter {
    QuickPayAppMetricaReporter(reporter: self)
  }
}
