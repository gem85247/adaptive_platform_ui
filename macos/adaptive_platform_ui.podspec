Pod::Spec.new do |s|
  s.name             = 'adaptive_platform_ui'
  s.version          = '0.1.112'
  s.summary          = 'Adaptive platform-specific widgets for Flutter with macOS AppKit support.'
  s.homepage         = 'https://github.com/berkaycatak/adaptive_platform_ui'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Berkay Catak' => 'berkaycatak@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
