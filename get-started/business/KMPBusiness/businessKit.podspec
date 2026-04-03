Pod::Spec.new do |spec|
  spec.name                  = 'businessKit'
  spec.version               = '0.1.0'
  spec.summary               = 'KMP Business XCFramework — UserService, FeedService'
  spec.description           = <<-DESC
    Kotlin Multiplatform Business module.
    Provides UserService and FeedService. Depends on foundationKit.
  DESC
  spec.homepage              = 'https://github.com/example/kmp-get-started'
  spec.license               = { :type => 'Apache-2.0' }
  spec.author                = { 'KMP Team' => 'kmp@example.com' }
  spec.source                = { :path => '.' }

  spec.ios.deployment_target = '14.0'
  spec.vendored_frameworks   = 'businessKit.xcframework'

  spec.dependency 'foundationKit'

  # Bridge pod declares the ObjC protocols that businessKit's Kotlin code references.
  spec.dependency 'businessBridge'
end
