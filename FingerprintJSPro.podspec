Pod::Spec.new do |s|
  s.name = "FingerprintJSPro"
  s.version = "0.1.1"
  s.summary = "FingerprintJS Pro visitor identification in a mobile app"

  s.description = "Helps to retrieve a FingerprintJS Pro visitor identifier in a native mobile app within a webview"

  s.homepage = "https://github.com/fingerprintjs/fingerprintjs-pro-ios-integrations"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Konstantin Darutkin" => "konstantin.darutkin@fingerprintjs.com" }
  s.source = { :git => "https://github.com/fingerprintjs/fingerprintjs-pro-ios-integrations.git", :tag => s.version.to_s }

  s.ios.deployment_target = "9.0"

  s.swift_version = "5.0"

  s.source_files = "Sources/FingerprintJSPro/**/*.swift"
  s.resources = "Sources/FingerprintJSPro/Resources/**/*.js"

  s.frameworks = "UIKit"
end
