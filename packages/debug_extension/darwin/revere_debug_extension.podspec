Pod::Spec.new do |s|
  s.name             = 'revere_debug_extension'
  s.version = '0.4.0'
  s.summary          = 'A Flutter plugin for revere to collect and display app metrics and logs in real-time.'
  s.description      = <<-DESC
    A Flutter plugin for revere to collect and display app metrics and logs in real-time.
  DESC
  s.homepage         = 'https://github.com/kumo01GitHub/revere'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'kumo01GitHub' => 'kumo01GitHub' }
  s.source           = { :path => '.' }
  s.source_files     = 'revere_debug_extension/Sources/revere_debug_extension/*.swift'
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
