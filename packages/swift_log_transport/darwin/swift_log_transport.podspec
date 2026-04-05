Pod::Spec.new do |s|
  s.name             = 'swift_log_transport'
  s.version = '1.0.0'
  s.summary          = 'SwiftLog (Apple swift-log) transport for revere logger.'
  s.description      = <<-DESC
    SwiftLog transport for revere logger (via platform channel).
    Uses apple/swift-log when built with Swift Package Manager.
    Falls back to NSLog when built with CocoaPods.
  DESC
  s.homepage         = 'https://github.com/kumo01GitHub/revere'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'kumo01GitHub' => 'kumo01GitHub' }
  s.source           = { :path => '.' }
  s.source_files     = 'swift_log_transport/Sources/swift_log_transport/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
