Pod::Spec.new do |spec|
  spec.name          = 'foundationBridge'
  spec.version       = '0.1.0'
  spec.summary       = 'ObjC protocol headers for the KMP Foundation bridge'
  spec.description   = <<-DESC
    Declares the ObjC protocols (KMPPlatformInfoProvider, KMPLoggerDelegate) that
    the iOS host application must implement and register with foundationKit.
    foundationKit.xcframework declares a dependency on this pod so that Clang
    sees full protocol definitions when the app imports foundationKit.
  DESC
  spec.homepage      = 'https://github.com/example/kmp-get-started'
  spec.license       = { :type => 'Apache-2.0' }
  spec.author        = { 'KMP Team' => 'kmp@example.com' }
  spec.source        = { :path => '.' }

  spec.ios.deployment_target = '14.0'

  # Header-only pod — no compiled sources, just protocol declarations.
  spec.source_files        = 'headers/*.h'
  spec.public_header_files = 'headers/*.h'
end
