Pod::Spec.new do |spec|
  spec.name                  = 'foundationKit'
  spec.version               = '0.1.0'
  spec.summary               = 'KMP Foundation XCFramework — runtime, stdlib, base capabilities'
  spec.description           = <<-DESC
    Kotlin Multiplatform Foundation module.
    Embeds Kotlin/Native runtime and stdlib. Must be loaded before any other KMP framework.
  DESC
  spec.homepage              = 'https://github.com/example/kmp-get-started'
  spec.license               = { :type => 'Apache-2.0' }
  spec.author                = { 'KMP Team' => 'kmp@example.com' }
  spec.source                = { :path => '.' }

  spec.ios.deployment_target = '14.0'
  spec.vendored_frameworks   = 'foundationKit.xcframework'

  # Bridge pod declares the ObjC protocols that foundationKit's Kotlin code references.
  # CocoaPods ensures foundationBridge.framework is linked whenever foundationKit is used,
  # so Clang can resolve protocol types without the injectBridgeHeaders hack.
  spec.dependency 'foundationBridge'
end
