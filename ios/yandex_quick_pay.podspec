Pod::Spec.new do |s|
  s.name             = 'yandex_quick_pay'
  s.version          = '1.0.0'
  s.summary          = 'Flutter SDK for Yandex Quick Payment integration.'
  s.description      = <<-DESC
Flutter SDK for integrating Yandex Quick Payment into your Flutter application.
                       DESC
  s.homepage         = 'https://pay.yandex.ru'
  s.license          = { :type => 'Proprietary', :text => 'License Agreement is available at https://yandex.ru/legal/ypay_sdk_agreement/?lang=ru.' }
  s.author           = { 'Yandex LLC' => 'yandexpay@yandex-team.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'

  s.dependency 'Flutter'
  s.dependency 'AppMetricaCore', '5.15.0'
  s.dependency 'AppMetricaCoreExtension', '5.15.0'

  # YandexQuickPaySDK dynamic XCFramework
  s.vendored_frameworks = 'Frameworks/YandexQuickPaySDK.xcframework'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @loader_path/Frameworks',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(PODS_TARGET_SRCROOT)/Frameworks/YandexQuickPaySDK.xcframework/ios-arm64" "$(PODS_TARGET_SRCROOT)/Frameworks/YandexQuickPaySDK.xcframework/ios-arm64_x86_64-simulator"',
    'OTHER_LDFLAGS' => '$(inherited) -framework YandexQuickPaySDK',
    'SWIFT_INCLUDE_PATHS' => [
      '$(PODS_TARGET_SRCROOT)/Frameworks/YandexQuickPaySDK.xcframework/ios-arm64/YandexQuickPaySDK.framework/Modules',
      '$(PODS_TARGET_SRCROOT)/Frameworks/YandexQuickPaySDK.xcframework/ios-arm64_x86_64-simulator/YandexQuickPaySDK.framework/Modules'
    ].join(' ')
  }
end
