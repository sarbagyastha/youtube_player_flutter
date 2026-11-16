Pod::Spec.new do |s|
  s.name             = 'youtube_player_darwin'
  s.version          = '0.1.0'
  s.summary          = 'iOS and macOS implementation of the youtube_player plugin.'
  s.description      = 'Hosts the YouTube IFrame Player API in a minimal WKWebView.'
  s.homepage         = 'https://github.com/sarbagyastha/youtube_player_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sarbagya Dhaubanjar' => 'https://sarbagyastha.com.np' }
  s.source           = { :path => '.' }
  s.source_files     = 'youtube_player_darwin/Sources/youtube_player_darwin/**/*.swift'
  s.resource_bundles = { 'youtube_player_darwin_privacy' => ['youtube_player_darwin/Sources/youtube_player_darwin/PrivacyInfo.xcprivacy'] }
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '6.0'
end
