Pod::Spec.new do |spec|
  spec.name          = 'businessBridgeImpl'
  spec.version       = '0.1.0'
  spec.summary       = 'Concrete ObjC implementations of the KMP Business bridge protocols'
  spec.description   = <<-DESC
    Provides AppAuthDelegate and AppNetworkDelegate — ready-to-use ObjC classes that
    implement the businessBridge protocols. Link this pod in your iOS app and pass
    instances to BusinessBridgeSetupKt.configureBusinessBridge at startup.
  DESC
  spec.homepage      = 'https://github.com/example/kmp-get-started'
  spec.license       = { :type => 'Apache-2.0' }
  spec.author        = { 'KMP Team' => 'kmp@example.com' }
  spec.source        = { :path => '.' }

  spec.ios.deployment_target = '14.0'

  spec.source_files        = 'headers/*.h', 'sources/*.m'
  spec.public_header_files = 'headers/*.h'

  spec.dependency 'businessBridge'
end
